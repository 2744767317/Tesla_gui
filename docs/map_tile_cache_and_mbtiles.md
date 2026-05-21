# 地图瓦片缓存与 MBTiles 使用说明

当前地图仍使用 Qt Location 的 `osm` 插件，但已经把瓦片层改成“本地缓存优先”：

- 在线瓦片会写入本地磁盘缓存，后续缩放/拖拽优先从本机读取。
- 可通过环境变量调整缓存位置和容量。
- `.mbtiles` 不直接由 Qt OSM 插件读取，项目会通过本地 tile server 转成 `http://127.0.0.1` 瓦片服务。

## 默认缓存

程序启动时会自动创建：

- `TESLA_MAP_CACHE_DIR`：在线瓦片磁盘缓存目录。
- `TESLA_MAP_OFFLINE_DIR`：Qt OSM 插件离线瓦片目录。

默认在线瓦片使用免费的 Carto Voyager 栅格瓦片，数据仍来自 OSM，但视觉比 OSM 标准瓦片更接近现代车机导航。

```bash
export TESLA_MAP_STYLE=carto-voyager   # 默认
export TESLA_MAP_STYLE=osm-standard    # 原始 OSM 标准瓦片
export TESLA_MAP_STYLE=carto-light
export TESLA_MAP_STYLE=carto-dark
```

默认缓存目录按风格隔离，例如 `~/.cache/Tesla_Dashboard_UI/maptiles/carto-voyager-v1`。这可以避免同一 z/x/y 命中旧样式缓存后出现“地图老旧或路线错位”的假象。

可选容量配置：

```bash
export TESLA_MAP_DISK_CACHE_MB=1536
export TESLA_MAP_MEMORY_CACHE_MB=256
export TESLA_MAP_TEXTURE_CACHE_MB=512
```

注意：Qt Location OSM 插件的缓存容量接口是 32 位 `int`，磁盘缓存不要超过 2000MB。项目会自动 clamp 到安全范围，避免启动阶段在 `QGeoFileTileCache::setMaxDiskUsage` 崩溃。

## 使用 MBTiles

推荐只设置一个环境变量，让 HMI 自动启动本地瓦片服务：

```bash
export TESLA_MAP_MBTILES="/path/to/china.mbtiles"
./Tesla_Dashboard_UI
```

可选端口：

```bash
export TESLA_MAP_TILE_PORT=8765
```

也可以手动启动本地 MBTiles 服务：

```bash
python3 tools/mbtiles_tile_server.py /path/to/china.mbtiles --port 8765 --cache-tiles 4096
```

再启动 HMI：

```bash
export TESLA_MAP_TILE_HOST="http://127.0.0.1:8765"
./Tesla_Dashboard_UI
```

Qt Location 的 `osm.mapping.custom.host` 需要基础 URL。项目会兼容旧写法并自动裁掉 `/%z/%x/%y.png`，最终传给 Qt 的是：

```bash
export TESLA_MAP_TILE_HOST="http://127.0.0.1:8765"
```

说明：

- 大多数 MBTiles 使用 TMS 行号，脚本会默认翻转 Y 轴。
- 如果你的 MBTiles 已经是 XYZ scheme，启动脚本时加 `--xyz`。
- 本地 tile server 会返回长缓存头，Qt 仍会继续写入自己的磁盘/纹理缓存。
- 本地 tile server 会复用 SQLite 只读连接，并缓存最近访问瓦片；缩放时同一区域重复请求会直接命中内存。

## 推荐路线

开发期推荐先用在线 OSM + 约 1.5GB 磁盘缓存跑热常用区域。

演示或车机离线场景推荐准备区域级 MBTiles，通过 `TESLA_MAP_TILE_HOST` 指到本地服务，避免缩放时等待公网瓦片下载。

如果已经准备好 MBTiles，更推荐 `TESLA_MAP_MBTILES=/path/to/map.mbtiles ./Tesla_Dashboard_UI`。这样 C++ 配置层会自动拉起本地服务，QML 地图层只看到一个本机瓦片地址，后面切 Autoware HMI 时风险更低。

## 搜索与反查服务

默认地理编码仍使用公共 Nominatim：

```bash
export TESLA_GEOCODE_PROVIDER=nominatim
export TESLA_GEOCODE_HOST=https://nominatim.openstreetmap.org
```

公共 Nominatim 在弱网、限流或国内网络环境下会超时，而且中国 POI 覆盖不等于高德/百度这类商业地图。项目内置了全国主要城市和部分热点的本地索引，只用于兜底，不替代完整 POI 数据。

推荐演示或车机环境接本地服务：

```bash
export TESLA_GEOCODE_PROVIDER=nominatim
export TESLA_GEOCODE_HOST=http://127.0.0.1:8080
```

也可以接 Photon：

```bash
export TESLA_GEOCODE_PROVIDER=photon
export TESLA_GEOCODE_HOST=http://127.0.0.1:2322
```

路线服务继续通过 OSRM 配置：

```bash
export TESLA_OSRM_HOST=http://127.0.0.1:5000
```

要获得一致的路线和底图精度，建议瓦片、地理编码、OSRM 使用同一批 OSM 数据构建。否则会出现“搜索点、路线吸附点、视觉道路不完全重合”的现象。

## 免费 POI 覆盖的现实边界

高德/百度级中国 POI 覆盖来自商业数据和持续运营，不存在稳定、合法、无限量、无需 key 的等价公网接口。当前项目的免费路线是：

- 路线：OSRM + OSM，道路覆盖依赖 OSM 数据质量。
- 底图：Carto/OSM 免费栅格瓦片，适合演示和开发，但不能承诺国内道路实时更新。
- 搜索：本地内置城市/热点兜底 + 可接本地 Nominatim/Photon。

如果不花接口钱，想显著接近车机体验，推荐下载中国或目标省份 OSM 数据，自建：

- `osrm-backend` 用于路径规划。
- `nominatim` 或 `photon` 用于地理编码搜索。
- `tilemaker + OpenMapTiles schema` 或现成 MBTiles 用于本地矢量/栅格底图。

这样没有接口 key 成本，但有本机磁盘、导入时间和维护成本。
