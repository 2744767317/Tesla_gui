# OSM / OSRM 阶段规划能力分析

## 1. 当前我们已经具备的真实能力

当前工程并不是“纯演示地图”了，已经有一条真实在线规划链路：

1. `NavigationMapScreen.qml`
   - 负责地图点击选点
   - 负责目的地搜索输入
   - 负责路线候选展示、偏好切换、回放和导航面板
2. `MapDataService`
   - `requestRoute()` 调 OSRM
   - `searchPlaces()` 调 Nominatim
   - `reverseGeocode()` 调 Nominatim reverse
3. `NavigationController`
   - 把路径步骤转成 UI 可消费的导航文案、ETA、剩余距离、进度

换句话说，现在这套系统已经能做：

- 地图选点
- 输入目的地搜索
- 在线路径规划
- 多候选路线展示
- 最快 / 最短 / 均衡 三种本地排序
- 线路高亮和车辆沿线路回放

这已经是一个可以继续做实的“OSM / OSRM 阶段 HMI”。

## 2. 现在真正还缺什么

如果目标是“真正实现规划功能”，现在还缺的是 4 个关键能力：

### 2.1 搜索体验还不够稳

现在已有：

- 在线 Nominatim 搜索
- 本地地标兜底

还应继续增强：

- 中文 / 拼音 / 英文混合匹配
- 热门地点建议
- 搜索历史
- 收藏地点 / Home / Work
- 搜索结果去重

### 2.2 路线模型还是单起终点优先

现在已有：

- 起点
- 终点
- OSRM alternatives

后面应预留：

- 途经点 waypoints
- 路线 profile 选择
  - driving
  - cycling
  - walking
- 避让策略
  - avoid toll
  - avoid ferry
  - avoid highway

### 2.3 回放是“沿路线驱动”，不是真车定位驱动

当前 `simulateDrive` 是一条很好的桌面预览能力，但它本质上是：

- 用 `vehicleCtrl.speed`
- 按路径点推进 marker

这适合当前阶段，因为它让路线 UI、导航 UI、相机跟随都能先完成。

但它不是最终真实定位闭环。

### 2.4 地图侧状态机还不够清晰

建议后面明确 5 个页面状态：

- `idle`
- `searching`
- `route_ready`
- `navigating`
- `route_error`

这样以后不管是接 ROS2，还是继续只做 OSRM，都不会乱。

## 3. 现在最值得保留的接口边界

为了以后低风险切到 Autoware，当前阶段就应该稳定这几个边界：

### 3.1 页面只认页面语义

`NavigationMapScreen.qml` 不应该关心“底层是 OSRM 还是 Autoware”。

它只该认这些语义：

- 搜索目的地
- 设置起点
- 设置终点
- 请求路线
- 返回候选路线
- 返回路线步骤
- 返回逆地理名称

### 3.2 `MapDataService` 继续做外部地图服务适配层

建议后续把它稳定成下面这组职责：

- 搜索 POI
- 请求路线
- 请求逆地理编码
- 预留多途经点请求
- 预留 profile / avoid 选项

### 3.3 `NavigationController` 继续做导航 UI ViewModel

它现在的位置是对的，不要让它直接掺地图 HTTP 逻辑。

它适合长期保留来输出：

- `destination`
- `nextManeuver`
- `etaMinutes`
- `distanceToNext`
- `routeProgress`

## 4. 下一阶段建议实现顺序

### 第一组：把搜索做顺

- 中文输入稳定
- 拼音 / 中文 / 英文混搜
- 搜索空状态、加载态、错误态
- 搜索结果去重和高亮

### 第二组：把路线请求做实

- 统一起终点更新时机
- 重算逻辑稳定
- 候选路线切换稳定
- 离线 fallback 与在线结果切换更清晰

当前这一步已经建议落实成 `MapDataService` 的标准能力，而不是散落在 QML：

- `OSRM_HOST` / `TESLA_OSRM_HOST`
  - 默认走 `https://router.project-osrm.org`
  - 后续切本地 OSRM 时只需要改环境变量，例如 `http://127.0.0.1:5000`
- 路线超时
  - 建议统一由 service 层控制，避免页面一直卡在“规划中”
  - 当前可用 `TESLA_ROUTE_TIMEOUT_MS` 调整，默认 9000 ms
- 路线缓存
  - 对同一组起终点和同一 OSRM host 做结果缓存
  - 当前可用 `TESLA_ROUTE_CACHE_ENABLED=0` 关闭缓存排查问题
- 请求状态与错误码
  - 页面可以继续只用旧的 `routeReady / routeFailed`
  - 但底层应额外暴露 `loading / cached / ready / error / cancelled`
  - 错误码建议至少区分 `timeout`、`network-error`、`http-error`、`parse-error`、`empty-route`

这样以后从公共 OSRM 切到本地 OSRM，不需要改页面语义，也不会把地图规划状态重新揉回 QML。

### 第三组：把路线模型预留出来

- waypoints 数据结构
- route options 数据结构固定
- profile / avoid 参数预留
- 收藏地点与历史地点入口

## 5. 结论

当前最对的方向不是急着接 ROS2，而是先把这套 OSM / OSRM 导航壳做成一套稳定、顺手、可扩展的“前台规划系统”。

当下面这些点稳定后，再接 Autoware 风险会很低：

- 搜索输入稳定
- 路线请求稳定
- 候选路线切换稳定
- 导航面板状态稳定
- 页面语义与底层服务解耦

## 6. 当前可用配置

本项目当前建议优先用环境变量控制 OSRM 行为：

```bash
export TESLA_OSRM_HOST="http://127.0.0.1:5000"
export TESLA_ROUTE_TIMEOUT_MS=8000
export TESLA_ROUTE_CACHE_ENABLED=1
```

说明：

- `TESLA_OSRM_HOST`
  - 路径规划服务地址
  - 未设置时默认使用公共 OSRM
- `TESLA_ROUTE_TIMEOUT_MS`
  - 路线请求超时，内部会限制在 1500 到 30000 ms
- `TESLA_ROUTE_CACHE_ENABLED`
  - `1/true/on` 启用缓存
  - `0/false/off/no` 关闭缓存
