import QtQuick 2.9
import QtPositioning

QtObject {
    id: searchStateRoot

    property var searchResults: []
    property var historyPlaces: []
    property var favoritePlaces: []
    property var quickPlaces: []
    property var homePlace: null
    property var workPlace: null
    property int maxHistoryItems: 8
    property int maxFavoriteItems: 8
    property int maxQuickItems: 10
    property var localPlaces: [
        { name: "北京，中国", keywords: "beijing 北京", latitude: 39.9042, longitude: 116.4074, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "上海，中国", keywords: "shanghai 上海", latitude: 31.2304, longitude: 121.4737, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "深圳，中国", keywords: "shenzhen 深圳", latitude: 22.5431, longitude: 114.0579, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "广州，中国", keywords: "guangzhou 广州", latitude: 23.1291, longitude: 113.2644, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "杭州，中国", keywords: "hangzhou 杭州", latitude: 30.2741, longitude: 120.1551, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "成都，中国", keywords: "chengdu 成都", latitude: 30.5728, longitude: 104.0668, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "西安，中国", keywords: "xian xi'an 西安", latitude: 34.3416, longitude: 108.9398, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "武汉，中国", keywords: "wuhan 武汉", latitude: 30.5928, longitude: 114.3055, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "山东省，中国", keywords: "shandong 山东 鲁", latitude: 36.6683, longitude: 117.0208, sourceType: "region", sourceLabel: "省级" },
        { name: "济南，山东，中国", keywords: "jinan 济南 山东", latitude: 36.6512, longitude: 117.1201, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "济南西站，济南，山东，中国", keywords: "jinan west railway station 济南西站 高铁 山东", latitude: 36.6687, longitude: 116.8925, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "济南遥墙国际机场，济南，山东，中国", keywords: "jinan yao qiang airport 遥墙机场 济南机场 山东", latitude: 36.8572, longitude: 117.2158, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "青岛，山东，中国", keywords: "qingdao 青岛 山东", latitude: 36.0671, longitude: 120.3826, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "青岛北站，青岛，山东，中国", keywords: "qingdao north railway station 青岛北站 高铁 山东", latitude: 36.1699, longitude: 120.3748, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "青岛胶东国际机场，青岛，山东，中国", keywords: "qingdao jiaodong airport 胶东机场 青岛机场 山东", latitude: 36.3617, longitude: 120.0886, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "泰山，泰安，山东，中国", keywords: "taishan mount tai 泰山 泰安 山东", latitude: 36.2550, longitude: 117.1000, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "泰安，山东，中国", keywords: "taian tai'an 泰安 山东", latitude: 36.2000, longitude: 117.0876, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "烟台，山东，中国", keywords: "yantai 烟台 山东", latitude: 37.4638, longitude: 121.4479, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "潍坊，山东，中国", keywords: "weifang 潍坊 山东", latitude: 36.7068, longitude: 119.1618, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "淄博，山东，中国", keywords: "zibo 淄博 山东", latitude: 36.8135, longitude: 118.0548, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "枣庄，山东，中国", keywords: "zaozhuang 枣庄 山东", latitude: 34.8105, longitude: 117.3237, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "东营，山东，中国", keywords: "dongying 东营 山东", latitude: 37.4348, longitude: 118.6746, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "济宁，山东，中国", keywords: "jining 济宁 山东", latitude: 35.4149, longitude: 116.5872, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "威海，山东，中国", keywords: "weihai 威海 山东", latitude: 37.5133, longitude: 122.1204, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "日照，山东，中国", keywords: "rizhao 日照 山东", latitude: 35.4164, longitude: 119.5270, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "临沂，山东，中国", keywords: "linyi 临沂 山东", latitude: 35.1047, longitude: 118.3564, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "德州，山东，中国", keywords: "dezhou 德州 山东", latitude: 37.4355, longitude: 116.3593, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "聊城，山东，中国", keywords: "liaocheng 聊城 山东", latitude: 36.4567, longitude: 115.9854, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "滨州，山东，中国", keywords: "binzhou 滨州 山东", latitude: 37.3835, longitude: 117.9707, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "菏泽，山东，中国", keywords: "heze 菏泽 山东", latitude: 35.2338, longitude: 115.4807, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "曲阜三孔，济宁，山东，中国", keywords: "qufu sankong confucius 曲阜 三孔 孔庙 山东", latitude: 35.5967, longitude: 116.9865, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "蓬莱阁，烟台，山东，中国", keywords: "penglai pavilion 蓬莱阁 烟台 山东", latitude: 37.8256, longitude: 120.7507, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "崂山，青岛，山东，中国", keywords: "laoshan mount lao 崂山 青岛 山东", latitude: 36.1896, longitude: 120.5986, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "大明湖，济南，山东，中国", keywords: "daming lake 大明湖 济南 山东", latitude: 36.6757, longitude: 117.0255, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "趵突泉，济南，山东，中国", keywords: "baotu spring 趵突泉 济南 山东", latitude: 36.6612, longitude: 117.0142, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "山东大学中心校区，济南，山东，中国", keywords: "shandong university 山东大学 山大 中心校区 济南", latitude: 36.6730, longitude: 117.0601, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "山东省体育中心，济南，山东，中国", keywords: "shandong sports center 山东省体育中心 体育场 济南 山东", latitude: 36.6416, longitude: 117.0069, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "山东省立医院，济南，山东，中国", keywords: "shandong provincial hospital 山东省立医院 省立医院 济南 山东", latitude: 36.6640, longitude: 116.9952, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "陕西省，中国", keywords: "shaanxi shanxi 陕西 秦", latitude: 34.2658, longitude: 108.9541, sourceType: "region", sourceLabel: "省级" },
        { name: "咸阳，陕西，中国", keywords: "xianyang 咸阳 陕西", latitude: 34.3296, longitude: 108.7088, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "宝鸡，陕西，中国", keywords: "baoji 宝鸡 陕西", latitude: 34.3619, longitude: 107.2377, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "渭南，陕西，中国", keywords: "weinan 渭南 陕西", latitude: 34.4996, longitude: 109.5102, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "延安，陕西，中国", keywords: "yanan yan'an 延安 陕西", latitude: 36.5853, longitude: 109.4898, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "榆林，陕西，中国", keywords: "yulin 榆林 陕西", latitude: 38.2852, longitude: 109.7346, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "汉中，陕西，中国", keywords: "hanzhong 汉中 陕西", latitude: 33.0676, longitude: 107.0231, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "安康，陕西，中国", keywords: "ankang 安康 陕西", latitude: 32.6847, longitude: 109.0290, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "商洛，陕西，中国", keywords: "shangluo 商洛 陕西", latitude: 33.8704, longitude: 109.9404, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "天安门广场，北京，中国", keywords: "tiananmen 天安门 北京", latitude: 39.9087, longitude: 116.3975, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "八达岭长城，北京，中国", keywords: "great wall changcheng 长城 北京", latitude: 40.4319, longitude: 116.5704, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "北京南站，北京，中国", keywords: "beijing south railway station 北京南站", latitude: 39.8652, longitude: 116.3785, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "首都国际机场，北京，中国", keywords: "beijing capital airport 首都机场", latitude: 40.0799, longitude: 116.6031, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "西安城墙，西安，中国", keywords: "xian city wall 西安城墙 城墙", latitude: 34.2583, longitude: 108.9426, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "大雁塔，西安，中国", keywords: "dayanta big wild goose pagoda 大雁塔 西安", latitude: 34.2190, longitude: 108.9646, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "陕西省体育场，西安，中国", keywords: "shaanxi stadium 陕西省体育场 体育场 西安", latitude: 34.2308, longitude: 108.9466, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "西安北站，西安，中国", keywords: "xian north railway station 西安北站 高铁", latitude: 34.3763, longitude: 108.9398, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "西安咸阳国际机场，西安，中国", keywords: "xian xianyang airport 咸阳机场 西安机场", latitude: 34.4471, longitude: 108.7516, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "西湖，杭州，中国", keywords: "west lake xihu 西湖 杭州", latitude: 30.2590, longitude: 120.1490, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "杭州东站，杭州，中国", keywords: "hangzhou east railway station 杭州东站", latitude: 30.2919, longitude: 120.2120, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "上海虹桥站，上海，中国", keywords: "shanghai hongqiao railway station 上海虹桥站", latitude: 31.1947, longitude: 121.3189, sourceType: "hotspot", sourceLabel: "热点" },
        { name: "德里国家首都辖区，印度", keywords: "delhi ncr 印度 德里", latitude: 28.4595, longitude: 77.0266, sourceType: "hotspot", sourceLabel: "热点" }
    ]
    property var gazetteerPlaces: [
        { name: "天津，中国", keywords: "tianjin 天津 津", latitude: 39.3434, longitude: 117.3616, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "重庆，中国", keywords: "chongqing 重庆 渝", latitude: 29.5630, longitude: 106.5516, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "石家庄，河北，中国", keywords: "shijiazhuang 石家庄 河北 冀", latitude: 38.0428, longitude: 114.5149, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "唐山，河北，中国", keywords: "tangshan 唐山 河北", latitude: 39.6309, longitude: 118.1802, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "秦皇岛，河北，中国", keywords: "qinhuangdao 秦皇岛 河北", latitude: 39.9354, longitude: 119.5996, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "保定，河北，中国", keywords: "baoding 保定 河北", latitude: 38.8739, longitude: 115.4646, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "雄安新区，河北，中国", keywords: "xiongan 雄安新区 雄安 河北", latitude: 39.0437, longitude: 115.8720, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "太原，山西，中国", keywords: "taiyuan 太原 山西 晋", latitude: 37.8706, longitude: 112.5489, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "大同，山西，中国", keywords: "datong 大同 山西", latitude: 40.0768, longitude: 113.3001, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "呼和浩特，内蒙古，中国", keywords: "hohhot huhehaote 呼和浩特 内蒙古 蒙", latitude: 40.8426, longitude: 111.7492, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "包头，内蒙古，中国", keywords: "baotou 包头 内蒙古", latitude: 40.6574, longitude: 109.8404, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "鄂尔多斯，内蒙古，中国", keywords: "ordos eerduosi 鄂尔多斯 内蒙古", latitude: 39.6087, longitude: 109.7815, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "沈阳，辽宁，中国", keywords: "shenyang 沈阳 辽宁 辽", latitude: 41.8057, longitude: 123.4315, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "大连，辽宁，中国", keywords: "dalian 大连 辽宁", latitude: 38.9140, longitude: 121.6147, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "长春，吉林，中国", keywords: "changchun 长春 吉林 吉", latitude: 43.8171, longitude: 125.3235, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "吉林市，吉林，中国", keywords: "jilin city 吉林市 吉林", latitude: 43.8378, longitude: 126.5494, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "哈尔滨，黑龙江，中国", keywords: "harbin haerbin 哈尔滨 黑龙江 黑", latitude: 45.8038, longitude: 126.5349, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "南京，江苏，中国", keywords: "nanjing 南京 江苏 苏", latitude: 32.0603, longitude: 118.7969, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "南京南站，南京，江苏，中国", keywords: "nanjing south railway station 南京南站 高铁 江苏", latitude: 31.9707, longitude: 118.7965, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "苏州，江苏，中国", keywords: "suzhou 苏州 江苏", latitude: 31.2989, longitude: 120.5853, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "无锡，江苏，中国", keywords: "wuxi 无锡 江苏", latitude: 31.4912, longitude: 120.3119, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "徐州，江苏，中国", keywords: "xuzhou 徐州 江苏", latitude: 34.2058, longitude: 117.2841, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "宁波，浙江，中国", keywords: "ningbo 宁波 浙江 浙", latitude: 29.8683, longitude: 121.5440, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "温州，浙江，中国", keywords: "wenzhou 温州 浙江", latitude: 27.9938, longitude: 120.6994, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "义乌，浙江，中国", keywords: "yiwu 义乌 浙江", latitude: 29.3069, longitude: 120.0751, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "合肥，安徽，中国", keywords: "hefei 合肥 安徽 皖", latitude: 31.8206, longitude: 117.2272, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "芜湖，安徽，中国", keywords: "wuhu 芜湖 安徽", latitude: 31.3525, longitude: 118.4331, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "黄山，安徽，中国", keywords: "huangshan 黄山 安徽", latitude: 29.7147, longitude: 118.3376, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "福州，福建，中国", keywords: "fuzhou 福州 福建 闽", latitude: 26.0745, longitude: 119.2965, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "厦门，福建，中国", keywords: "xiamen 厦门 福建", latitude: 24.4798, longitude: 118.0894, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "泉州，福建，中国", keywords: "quanzhou 泉州 福建", latitude: 24.8741, longitude: 118.6757, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "南昌，江西，中国", keywords: "nanchang 南昌 江西 赣", latitude: 28.6820, longitude: 115.8582, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "九江，江西，中国", keywords: "jiujiang 九江 江西", latitude: 29.7051, longitude: 116.0019, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "赣州，江西，中国", keywords: "ganzhou 赣州 江西", latitude: 25.8311, longitude: 114.9348, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "郑州，河南，中国", keywords: "zhengzhou 郑州 河南 豫", latitude: 34.7466, longitude: 113.6254, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "郑州东站，郑州，河南，中国", keywords: "zhengzhou east railway station 郑州东站 高铁 河南", latitude: 34.7591, longitude: 113.7782, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "洛阳，河南，中国", keywords: "luoyang 洛阳 河南", latitude: 34.6197, longitude: 112.4540, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "开封，河南，中国", keywords: "kaifeng 开封 河南", latitude: 34.7973, longitude: 114.3076, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "宜昌，湖北，中国", keywords: "yichang 宜昌 湖北", latitude: 30.6919, longitude: 111.2865, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "襄阳，湖北，中国", keywords: "xiangyang 襄阳 湖北", latitude: 32.0089, longitude: 112.1224, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "长沙，湖南，中国", keywords: "changsha 长沙 湖南 湘", latitude: 28.2282, longitude: 112.9388, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "岳阳，湖南，中国", keywords: "yueyang 岳阳 湖南", latitude: 29.3571, longitude: 113.1287, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "张家界，湖南，中国", keywords: "zhangjiajie 张家界 湖南", latitude: 29.1171, longitude: 110.4792, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "佛山，广东，中国", keywords: "foshan 佛山 广东 粤", latitude: 23.0218, longitude: 113.1219, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "东莞，广东，中国", keywords: "dongguan 东莞 广东", latitude: 23.0207, longitude: 113.7518, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "珠海，广东，中国", keywords: "zhuhai 珠海 广东", latitude: 22.2711, longitude: 113.5767, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "南宁，广西，中国", keywords: "nanning 南宁 广西 桂", latitude: 22.8170, longitude: 108.3665, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "桂林，广西，中国", keywords: "guilin 桂林 广西", latitude: 25.2736, longitude: 110.2900, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "柳州，广西，中国", keywords: "liuzhou 柳州 广西", latitude: 24.3255, longitude: 109.4155, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "海口，海南，中国", keywords: "haikou 海口 海南 琼", latitude: 20.0442, longitude: 110.1999, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "三亚，海南，中国", keywords: "sanya 三亚 海南", latitude: 18.2528, longitude: 109.5119, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "绵阳，四川，中国", keywords: "mianyang 绵阳 四川 川 蜀", latitude: 31.4675, longitude: 104.6796, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "乐山，四川，中国", keywords: "leshan 乐山 四川", latitude: 29.5521, longitude: 103.7654, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "九寨沟，四川，中国", keywords: "jiuzhaigou 九寨沟 四川", latitude: 33.2600, longitude: 103.9180, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "贵阳，贵州，中国", keywords: "guiyang 贵阳 贵州 黔", latitude: 26.6470, longitude: 106.6302, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "遵义，贵州，中国", keywords: "zunyi 遵义 贵州", latitude: 27.7257, longitude: 106.9272, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "昆明，云南，中国", keywords: "kunming 昆明 云南 滇", latitude: 25.0389, longitude: 102.7183, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "大理，云南，中国", keywords: "dali 大理 云南", latitude: 25.6065, longitude: 100.2676, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "丽江，云南，中国", keywords: "lijiang 丽江 云南", latitude: 26.8550, longitude: 100.2278, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "西双版纳，云南，中国", keywords: "xishuangbanna 西双版纳 云南 景洪", latitude: 22.0094, longitude: 100.7974, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "拉萨，西藏，中国", keywords: "lhasa 拉萨 西藏 藏", latitude: 29.6500, longitude: 91.1000, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "日喀则，西藏，中国", keywords: "shigatse rikaze 日喀则 西藏", latitude: 29.2670, longitude: 88.8810, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "兰州，甘肃，中国", keywords: "lanzhou 兰州 甘肃 甘 陇", latitude: 36.0611, longitude: 103.8343, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "敦煌，甘肃，中国", keywords: "dunhuang 敦煌 甘肃", latitude: 40.1421, longitude: 94.6619, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "天水，甘肃，中国", keywords: "tianshui 天水 甘肃", latitude: 34.5809, longitude: 105.7249, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "西宁，青海，中国", keywords: "xining 西宁 青海 青", latitude: 36.6171, longitude: 101.7782, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "格尔木，青海，中国", keywords: "golmud geermu 格尔木 青海", latitude: 36.4064, longitude: 94.9033, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "银川，宁夏，中国", keywords: "yinchuan 银川 宁夏 宁", latitude: 38.4872, longitude: 106.2309, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "乌鲁木齐，新疆，中国", keywords: "urumqi wulumuqi 乌鲁木齐 新疆 新", latitude: 43.8256, longitude: 87.6168, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "喀什，新疆，中国", keywords: "kashgar kashi 喀什 新疆", latitude: 39.4704, longitude: 75.9898, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "吐鲁番，新疆，中国", keywords: "turpan tulufan 吐鲁番 新疆", latitude: 42.9513, longitude: 89.1895, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "香港，中国", keywords: "hong kong hongkong 香港 港", latitude: 22.3193, longitude: 114.1694, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "澳门，中国", keywords: "macau macao 澳门 澳", latitude: 22.1987, longitude: 113.5439, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "台北，台湾，中国", keywords: "taipei 台北 台湾 台", latitude: 25.0330, longitude: 121.5654, sourceType: "gazetteer", sourceLabel: "城市" },
        { name: "高雄，台湾，中国", keywords: "kaohsiung gaoxiong 高雄 台湾", latitude: 22.6273, longitude: 120.3014, sourceType: "gazetteer", sourceLabel: "城市" }
    ]
    property string searchHint: ""
    property bool showSearchResults: false

    property var persistentSettings: searchStorage

    Component.onCompleted: loadPersistedPlaces()

    function safeParseArray(rawText) {
        if (!rawText || !rawText.length)
            return []

        try {
            var parsed = JSON.parse(rawText)
            return parsed instanceof Array ? parsed : []
        } catch (error) {
            return []
        }
    }

    function safeParsePlace(rawText) {
        if (!rawText || !rawText.length)
            return null

        try {
            var parsed = JSON.parse(rawText)
            return isValidPlace(parsed) ? parsed : null
        } catch (error) {
            return null
        }
    }

    function isValidPlace(place) {
        return place
            && place.name !== undefined
            && place.latitude !== undefined
            && place.longitude !== undefined
            && !isNaN(Number(place.latitude))
            && !isNaN(Number(place.longitude))
            && Math.abs(Number(place.latitude)) <= 90
            && Math.abs(Number(place.longitude)) <= 180
    }

    function normalizePlace(place, sourceType, sourceLabel) {
        if (!isValidPlace(place))
            return null

        return {
            name: localizePlaceName(String(place.name || "目的地")),
            keywords: String(place.keywords || place.name || ""),
            latitude: Number(place.latitude),
            longitude: Number(place.longitude),
            sourceType: sourceType || place.sourceType || "local",
            sourceLabel: sourceLabel || place.sourceLabel || "本地"
        }
    }

    function placeKey(place) {
        if (!isValidPlace(place))
            return ""

        return Number(place.latitude).toFixed(5) + "," + Number(place.longitude).toFixed(5)
    }

    function dedupePlaces(places, limit) {
        var output = []
        var seen = {}
        for (var index = 0; index < places.length; index++) {
            var place = normalizePlace(places[index], places[index].sourceType, places[index].sourceLabel)
            if (!place)
                continue

            var key = placeKey(place)
            if (seen[key])
                continue

            seen[key] = true
            output.push(place)
            if (limit && output.length >= limit)
                break
        }
        return output
    }

    function loadPersistedPlaces() {
        historyPlaces = dedupePlaces(safeParseArray(persistentSettings.historyJson), maxHistoryItems)
        favoritePlaces = dedupePlaces(safeParseArray(persistentSettings.favoritesJson), maxFavoriteItems)
        homePlace = normalizePlace(safeParsePlace(persistentSettings.homeJson), "home", "Home")
        workPlace = normalizePlace(safeParsePlace(persistentSettings.workJson), "work", "Work")
        refreshQuickPlaces()
    }

    function persistHistory() {
        persistentSettings.historyJson = JSON.stringify(historyPlaces)
        refreshQuickPlaces()
    }

    function persistFavorites() {
        persistentSettings.favoritesJson = JSON.stringify(favoritePlaces)
        refreshQuickPlaces()
    }

    function setHomePlace(place) {
        homePlace = normalizePlace(place, "home", "Home")
        persistentSettings.homeJson = homePlace ? JSON.stringify(homePlace) : ""
        refreshQuickPlaces()
    }

    function setWorkPlace(place) {
        workPlace = normalizePlace(place, "work", "Work")
        persistentSettings.workJson = workPlace ? JSON.stringify(workPlace) : ""
        refreshQuickPlaces()
    }

    function recordHistory(place) {
        var normalized = normalizePlace(place, "history", "历史")
        if (!normalized)
            return

        var filtered = []
        var key = placeKey(normalized)
        for (var index = 0; index < historyPlaces.length; index++) {
            if (placeKey(historyPlaces[index]) !== key)
                filtered.push(historyPlaces[index])
        }

        filtered.unshift(normalized)
        historyPlaces = dedupePlaces(filtered, maxHistoryItems)
        persistHistory()
    }

    function toggleFavorite(place) {
        var normalized = normalizePlace(place, "favorite", "收藏")
        if (!normalized)
            return false

        var key = placeKey(normalized)
        var filtered = []
        var removed = false
        for (var index = 0; index < favoritePlaces.length; index++) {
            if (placeKey(favoritePlaces[index]) === key) {
                removed = true
                continue
            }
            filtered.push(favoritePlaces[index])
        }

        if (!removed)
            filtered.unshift(normalized)

        favoritePlaces = dedupePlaces(filtered, maxFavoriteItems)
        persistFavorites()
        return !removed
    }

    function isFavorite(place) {
        var key = placeKey(place)
        if (!key.length)
            return false

        for (var index = 0; index < favoritePlaces.length; index++) {
            if (placeKey(favoritePlaces[index]) === key)
                return true
        }
        return false
    }

    function allLocalSearchPlaces() {
        var places = []
        if (homePlace)
            places.push(homePlace)
        if (workPlace)
            places.push(workPlace)
        places = places.concat(favoritePlaces, historyPlaces, localPlaces, gazetteerPlaces)
        return dedupePlaces(places, 0)
    }

    function sourcePriority(place) {
        if (place.sourceType === "home" || place.sourceType === "work")
            return -700
        if (place.sourceType === "favorite")
            return -520
        if (place.sourceType === "history")
            return -360
        if (place.sourceType === "hotspot")
            return -120
        if (place.sourceType === "gazetteer")
            return -80
        if (place.sourceType === "region")
            return 30
        return 0
    }

    function localMatchScore(query, place, orderIndex) {
        var needle = String(query || "").trim().toLowerCase()
        var name = String(place.name || "").toLowerCase()
        var keywords = String(place.keywords || "").toLowerCase()
        var haystack = name + " " + keywords
        var relaxedNeedle = needle.replace(/省|市|自治区|特别行政区|地区|新区|景区|机场|火车站|高铁站/g, "")
        if (!needle.length)
            return sourcePriority(place) + orderIndex * 0.01
        if (name === needle || keywords === needle)
            return -1200 + sourcePriority(place)
        if (name.indexOf(needle) === 0)
            return -900 + sourcePriority(place)
        if (haystack.indexOf(needle) >= 0)
            return -600 + sourcePriority(place)
        if (relaxedNeedle.length >= 2 && haystack.indexOf(relaxedNeedle) >= 0)
            return -520 + sourcePriority(place)
        var shortName = name.split("，")[0]
        if (shortName.length >= 2 && needle.indexOf(shortName) >= 0)
            return -430 + sourcePriority(place)
        return 999999
    }

    function refreshQuickPlaces() {
        var seeded = []
        if (homePlace)
            seeded.push(homePlace)
        if (workPlace)
            seeded.push(workPlace)

        seeded = seeded.concat(favoritePlaces, historyPlaces, localPlaces.slice(0, 8))
        quickPlaces = dedupePlaces(seeded, maxQuickItems)
    }

    function showQuickSuggestions(message) {
        refreshQuickPlaces()
        searchResults = quickPlaces
        showSearchResults = quickPlaces.length > 0
        searchHint = quickPlaces.length ? (message || "常用地点") : "暂无常用地点"
    }

    function mergeSearchResults(onlineResults, query, limit) {
        return dedupePlaces(onlineResults.concat(localSearchResults(query)), limit || 8)
    }

    function translateTerm(text) {
        var translations = {
            "China": "中国",
            "Beijing": "北京",
            "Shanghai": "上海",
            "Shenzhen": "深圳",
            "Guangzhou": "广州",
            "Hangzhou": "杭州",
            "Chengdu": "成都",
            "Xi'an": "西安",
            "Xi’an": "西安",
            "Wuhan": "武汉",
            "Shandong": "山东",
            "Jinan": "济南",
            "Qingdao": "青岛",
            "Yantai": "烟台",
            "Weifang": "潍坊",
            "Zibo": "淄博",
            "Zaozhuang": "枣庄",
            "Dongying": "东营",
            "Jining": "济宁",
            "Weihai": "威海",
            "Rizhao": "日照",
            "Linyi": "临沂",
            "Dezhou": "德州",
            "Liaocheng": "聊城",
            "Binzhou": "滨州",
            "Heze": "菏泽",
            "Tai'an": "泰安",
            "Taian": "泰安",
            "Shaanxi": "陕西",
            "Shaanxi Province": "陕西省",
            "Xianyang": "咸阳",
            "Baoji": "宝鸡",
            "Weinan": "渭南",
            "Yan'an": "延安",
            "Yanan": "延安",
            "Yulin": "榆林",
            "Hanzhong": "汉中",
            "Ankang": "安康",
            "Shangluo": "商洛",
            "Province": "省",
            "Stadium": "体育场",
            "Sports Center": "体育中心",
            "Railway Station": "火车站",
            "Airport": "机场",
            "Great Wall of China": "长城",
            "Tiananmen Square": "天安门广场",
            "Beijing South Railway Station": "北京南站",
            "Beijing Capital International Airport": "首都国际机场",
            "Shaanxi Province Stadium": "陕西省体育场",
            "Xi'an City Wall": "西安城墙",
            "Daming Lake": "大明湖",
            "Baotu Spring": "趵突泉",
            "Mount Tai": "泰山",
            "Laoshan": "崂山",
            "Shandong University": "山东大学",
            "Delhi NCR": "德里国家首都辖区",
            "India": "印度",
            "Unnamed road": "未命名道路",
            "Pinned": "选点"
        }

        if (translations[text])
            return translations[text]

        var result = text
        var replacements = [
            ["Shaanxi Province", "陕西省"],
            ["Shandong Province", "山东省"],
            ["Xi'an", "西安"],
            ["Xi’an", "西安"],
            ["Jinan", "济南"],
            ["Qingdao", "青岛"],
            ["Yantai", "烟台"],
            ["Weifang", "潍坊"],
            ["Zibo", "淄博"],
            ["Zaozhuang", "枣庄"],
            ["Dongying", "东营"],
            ["Jining", "济宁"],
            ["Weihai", "威海"],
            ["Rizhao", "日照"],
            ["Linyi", "临沂"],
            ["Dezhou", "德州"],
            ["Liaocheng", "聊城"],
            ["Binzhou", "滨州"],
            ["Heze", "菏泽"],
            ["Shandong", "山东"],
            ["Shaanxi Province", "陕西省"],
            ["Shaanxi", "陕西"],
            ["Xianyang", "咸阳"],
            ["Baoji", "宝鸡"],
            ["Weinan", "渭南"],
            ["Yan'an", "延安"],
            ["Yanan", "延安"],
            ["Yulin", "榆林"],
            ["Hanzhong", "汉中"],
            ["Ankang", "安康"],
            ["Shangluo", "商洛"],
            ["Beijing", "北京"],
            ["Shanghai", "上海"],
            ["China", "中国"],
            ["Sports Center", "体育中心"],
            ["Railway Station", "火车站"],
            ["Airport", "机场"],
            ["Stadium", "体育场"],
            ["Province", "省"]
        ]

        for (var index = 0; index < replacements.length; index++)
            result = result.replace(replacements[index][0], replacements[index][1])
        return result
    }

    function localizePlaceName(name) {
        if (!name || !name.length)
            return name

        var parts = name.split(",")
        for (var index = 0; index < parts.length; index++)
            parts[index] = translateTerm(parts[index].trim())
        return parts.join("，")
    }

    function parseCoordinateQuery(query) {
        var normalized = query === undefined || query === null ? "" : String(query).trim()
        normalized = normalized.replace(/，/g, ",").replace(/\s+/g, "")
        var match = normalized.match(/^(-?\d+(?:\.\d+)?)\,(-?\d+(?:\.\d+)?)$/)
        if (!match)
            return null

        var first = Number(match[1])
        var second = Number(match[2])
        if (isNaN(first) || isNaN(second))
            return null

        var latitude = first
        var longitude = second
        if (Math.abs(first) > 90 && Math.abs(second) <= 90) {
            latitude = second
            longitude = first
        }

        if (Math.abs(latitude) > 90 || Math.abs(longitude) > 180)
            return null

        return QtPositioning.coordinate(latitude, longitude)
    }

    function localSearchResults(query) {
        var needle = String(query || "").toLowerCase()
        var ranked = []
        var places = allLocalSearchPlaces()
        for (var index = 0; index < places.length; index++) {
            var score = localMatchScore(needle, places[index], index)
            if (score < 999999) {
                var place = normalizePlace(places[index], places[index].sourceType, places[index].sourceLabel)
                place.score = score
                ranked.push(place)
            }
        }

        ranked.sort(function(left, right) {
            return left.score - right.score
        })

        var matches = []
        for (var matchIndex = 0; matchIndex < ranked.length && matches.length < 8; matchIndex++) {
            var cleaned = ranked[matchIndex]
            delete cleaned.score
            matches.push(cleaned)
        }
        return matches
    }

    function applyLocalSearchResults(query, message) {
        var results = localSearchResults(query)
        searchResults = results
        showSearchResults = results.length > 0
        searchHint = results.length
            ? message
            : ((message && message.length) ? message : "无本地匹配")
    }
}
