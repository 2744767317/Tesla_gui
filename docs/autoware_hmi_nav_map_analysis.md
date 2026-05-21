# Autoware HMI 导航与地图页集成分析

## 1. 结论先行

当前工程非常适合沿着“保留 Tesla 视觉层，新增 ROS2 Bridge + AD API 适配层”的路线演进。

最小风险方案不是重写 QML，而是把现有 Tesla UI 继续作为 HMI 前端，新增两层：

1. `Qt HMI Client` 层：继续保留现有 `NavigationMapScreen.qml`、`main.qml`、`NavigationController`、状态面板和 Tesla 风格。
2. `ROS2 Bridge + AD API Adapter` 层：专门负责 Autoware ROS2 topic/service 的订阅、调用、版本兼容和数据整形。

建议采用“分进程桥接”而不是“GUI 进程直接嵌 ROS2”：

- 当前工程是独立 Qt/qmake 工程，直接把 ROS2/ament 深度嵌入 GUI 进程，构建和部署风险都更高。
- 分进程后，Qt 前端基本不动视觉层，只把现在的演示型 `AutowareBridge` 改造成桥接客户端即可。
- ROS2 Bridge 崩溃或 DDS 波动时，不会直接拖死 QML 界面。

## 2. 现有工程现状

### 2.1 导航/地图页现状

`NavigationMapScreen.qml` 现在已经同时承担了以下职责：

- 在线地名搜索
- 在线路径规划
- 地图渲染
- 起终点交互
- 路线候选排序
- 驾驶回放动画
- 导航卡片文案更新

这说明它已经是一个完整的“导航页面壳”，视觉上完全值得保留。

但它目前的数据来源仍是演示/互联网服务：

- 路线规划来自 `router.project-osrm.org`
- 搜索与逆地理编码来自 `photon.komoot.io`
- 车辆沿路线前进依赖 `Timer` + `vehicleCtrl.speed`
- 导航提示由 OSRM step 结果和本地模拟逻辑生成

这意味着当前页面适合做 Autoware HMI 的壳，但还不是 Autoware 的真实导航页。

### 2.2 当前导航控制器现状

`NavigationController` 的定位比较好，它本质上已经是一个“导航卡片 ViewModel”：

- 接收路线步骤
- 计算剩余距离和 ETA
- 生成导航提示
- 向 QML 暴露轻量属性

这一层建议保留，但输入源需要改成“Autoware 适配后的路线/规划状态”，而不是 OSRM 的原始结果。

### 2.3 当前 Autoware 相关代码现状

工程里已经有一个早期的 `AutowareBridge` 和 `ADController`，这对后续演进有帮助，但目前仍然是“演示桥”：

- `AutowareBridge` 用 `QTimer` 模拟连接、车辆运动、任务进度和路径点
- `sendGoal()` 当前直接覆盖 `m_lat/m_lng`，语义上把“目标点”和“车辆当前位置”混在了一起
- `ADController` 现在是本地状态机，并没有对接 Autoware AD API

因此当前最合理的做法不是继续在这两个类里堆演示逻辑，而是把它们改造成“真实桥接数据的前端适配器”。

## 3. 为什么这条路线风险最低

### 3.1 可以保留的部分

以下内容基本都可以保留：

- Tesla 风格 QML 布局
- 地图容器和覆盖层样式
- 左侧状态卡片和底部系统面板
- `NavigationController` 这类轻量 UI ViewModel
- 地图点击选点、缩放、跟随视角等交互体验

### 3.2 必须替换的部分

以下内容应逐步替换成 Autoware 真数据：

- OSRM 路线请求
- Photon 搜索结果到路线的直接绑定
- 基于 `Timer` 的“车辆沿路线移动”
- `missionProgress` 的本地自增
- `ADController` 的本地 enable/disable 逻辑
- `AutowareBridge` 里的连接与状态模拟

### 3.3 为什么不建议直接把 QML 绑到 ROS2

不建议让 `NavigationMapScreen.qml` 直接理解 Autoware ROS2 细节，原因有三个：

1. QML 页面现在已经很重，再叠加 ROS2 状态机会让维护成本迅速上升。
2. Autoware AD API 存在版本差异，应该由适配层吸收，而不是泄漏到 UI。
3. UI 需要的是稳定、简单、可展示的数据结构，而不是原始 ROS message。

## 4. 推荐目标架构

建议形成下面的分层：

### 4.1 UI 层

- `main.qml`
- `NavigationMapScreen.qml`
- `Components/AutowareStatusPanel.qml`

职责：

- 保留 Tesla 风格
- 呈现地图、车辆、目标点、路线覆盖层、状态卡片
- 触发“选点导航”“切换模式”“清除路线”“启动/停止”等用户动作

### 4.2 HMI ViewModel 层

- `NavigationController`
- 未来可增加 `RouteViewModel`、`VehicleStateViewModel`

职责：

- 把桥接层提供的原始状态整理成适合 UI 的轻量属性
- 统一导航文案、进度条、状态灯、按钮 enable/disable 规则

### 4.3 Qt 侧桥接客户端

- 现有 `AutowareBridge` 建议转型为“桥接客户端”

职责：

- 不再自己模拟 ROS 数据
- 只维护 GUI 与 ROS2 Bridge 之间的 IPC
- 对 QML 暴露稳定属性和命令接口

建议暴露的前端语义不要直接等同于 ROS message 字段名，而是面向页面：

- `bridgeConnected`
- `localizationState`
- `routeState`
- `operationMode`
- `motionState`
- `mrmState`
- `vehiclePose`
- `vehicleSpeedKph`
- `steeringAngleDeg`
- `plannedPathPoints`
- `nextBehavior`
- `nextBehaviorDistance`
- `missionProgress`

### 4.4 ROS2 Bridge + AD API Adapter

建议新增独立 ROS2 进程，例如：

- `autoware_hmi_bridge`

职责：

- 订阅 Autoware AD API topic
- 调用 Autoware AD API service
- 适配不同 AD API 版本
- 将 Lanelet/Trajectory/State 转成 HMI 可直接消费的数据结构
- 管理与 GUI 的 IPC 协议

## 5. 推荐的 AD API 对接面

下面是最适合当前项目第一阶段接入的主干接口。

### 5.1 路径规划与目标点控制

首选接入：

- `/api/routing/set_route_points`
- `/api/routing/state`
- `/api/routing/route`
- `/api/routing/clear_route`

必要时按版本支持：

- `/api/routing/change_route_points`

适配建议：

- 页面点击地图或搜索地点后，不再直接请求 OSRM。
- 由桥接层把终点和中间点转成 `SetRoutePoints` 请求。
- 桥接层负责判断当前 route state。

推荐桥接规则：

- `UNSET` 时调用 `set_route_points`
- `SET` 且目标版本支持 `change_route_points` 时调用 `change_route_points`
- `SET` 但目标版本不支持 route change 时，走“清路由 -> 重新设路由”的兼容路径

这里需要注意一个关键事实：

- AD API Routing 天生是“单条有效路由”模型，不提供类似 OSRM 的多备选路线列表。
- 因此当前页面里的“推荐路线 / 备选路线 1 / 备选路线 2”不能直接映射到 AD API。

推论：

- 如果你想继续保留“多路线候选”交互，需要额外的上游路径候选服务。
- 如果第一阶段追求最低风险，建议先把路线候选列表降级为“单条 Autoware 生效路线 + 若干任务点预设”。

### 5.2 定位初始化

建议接入：

- `/api/localization/initialization_state`
- `/api/localization/initialize`

这正好可以承接当前地图页面的“右键设置起点 / 点击地图选点”能力。

建议流程：

- 用户在地图上选定起点
- UI 生成带协方差的初始位姿请求
- 桥接层调用 `initialize`
- 页面显示 `UNINITIALIZED / INITIALIZING / INITIALIZED`

这会比现在单纯修改 `currentLoc` 更接近真实 Autoware 工作流。

### 5.3 自动驾驶模式控制

建议接入：

- `/api/operation_mode/state`
- `/api/operation_mode/enable_autoware_control`
- `/api/operation_mode/disable_autoware_control`
- `/api/operation_mode/change_to_autonomous`
- `/api/operation_mode/change_to_stop`
- 如需要再接 `change_to_local`、`change_to_remote`

这意味着当前 `ADController` 不应继续自己维护 `adEnabled` 真值，而应该改成：

- 读取 `operation_mode/state`
- 根据可切换标志决定按钮是否可点击
- 调用 AD API service 发起模式切换

### 5.4 启动车辆前的 HMI Hook

建议按版本可选支持：

- `/api/motion/state`
- `/api/motion/accept_start`

这一组接口很适合未来“页面化路径规划 + 定点控制”的出发确认流程：

- 路线设置成功
- 车辆进入 `STARTING`
- HMI 给出“确认起步”提示
- 用户点击确认后调用 `accept_start`

如果当前部署版本没有发布这组 API，就先不要把页面逻辑绑死在它上面。

### 5.5 车辆状态可视化

建议接入：

- `/api/vehicle/kinematics`
- `/api/vehicle/status`
- `/api/vehicle/metrics`

推荐映射：

- `lat/lng` <- `vehicle/kinematics.geographic_pose`
- `odomX/odomY/heading` <- `vehicle/kinematics.pose`
- `vehicleSpeed` <- `vehicle/kinematics.twist`
- `steeringAngle` <- `vehicle/status.steering_tire_angle`
- `gear` <- `vehicle/status.gear`
- 能耗/电量 <- `vehicle/metrics`

这会直接替换当前 `AutowareBridge` 里基于 `QTimer` 的模拟数据。

### 5.6 风险与安全状态

建议接入：

- `/api/fail_safe/mrm_state`
- `/api/planning/velocity_factors`
- `/api/planning/steering_factors`

这部分非常适合增强 Tesla 风格 HMI，而不必破坏原界面风格：

- `MRM` 状态用于红色风险提示、接管提示、紧急停车态
- `velocity_factors` 用于显示“前方信号灯 / 障碍物 / 停车原因”
- `steering_factors` 用于显示“即将左转 / 右转 / 变道 / 避障”

相比继续依赖 OSRM 的 turn-by-turn 文案，这组数据更贴近 Autoware 的真实决策原因。

## 6. 地图页如何演进而不破坏 Tesla 风格

### 6.1 可以完全保留的视觉元素

- 地图底图
- 高亮路线叠层
- 当前车位置 marker
- 终点 marker
- 左上导航卡片
- 右上操作提示
- 左下/右下状态浮层

### 6.2 需要替换的数据来源

当前 `routePath`、`routeSteps`、`routeOptions` 都主要服务于 OSRM 模型。

建议逐步改成：

- `routePath` <- Autoware 规划轨迹的可视化折线
- `routeSteps` <- 桥接层根据 planning factors 生成的 HMI 步骤摘要
- `routeOptions` <- 第一阶段可退化为 1 条；后续如有需要再接外部候选服务

### 6.3 关于轨迹显示

需要注意：

- `/api/routing/route` 返回的是 lanelet 格式 route data，不是当前 QML 直接可画的经纬度折线。
- 当前 QML 地图需要的是 `QVariantList<lat,lng>` 一类的轻量路径点集合。

因此桥接层必须承担“路线/轨迹转绘图路径”的责任。

第一阶段的现实做法：

- 由桥接层消费 Autoware 的规划输出轨迹
- 优先适配内部规划接口中的 `/planning/scenario_planning/trajectory`
- 将轨迹重采样为稀疏经纬度点
- 再下发给 Qt 地图页渲染

换句话说，真正应该喂给 `NavigationMapScreen.qml` 的不是 AD API 原始消息，而是“已经可画出来的 polyline”。

### 6.4 关于导航文案

当前页面的导航文案来自 OSRM step，这在 Autoware 模式下不一定继续成立。

最低风险替代方案：

- 目的地：来自 route goal
- 当前状态：来自 route state / motion state / operation mode
- 下一行为：来自 steering factor 或 velocity factor
- 距离信息：来自 factor distance 或轨迹剩余距离估算

这样能保留 Tesla 风格的“导航卡片”，但数据语义更贴合 Autoware。

## 7. 对现有类的改造建议

### 7.1 `NavigationMapScreen.qml`

建议保留为主页面，但要做职责收缩：

- 保留展示和交互
- 移出 OSRM/Photon 直连逻辑
- 移出 `simulateDrive` 主导的车辆运动
- 改成消费桥接层下发的真实状态

### 7.2 `NavigationController`

建议保留，并增强为“导航状态汇总器”：

- 输入从 OSRM steps 扩展为“路线状态 + planning factors + 轨迹进度”
- 继续负责 ETA、剩余距离、下一行为文案
- 不直接依赖 ROS2

### 7.3 `AutowareBridge`

建议彻底改定位：

- 从“本地模拟器”改成“Qt 侧桥接客户端/Facade”
- 不再自己生成路径
- 不再自己累计 mission progress
- 不再用 `sendGoal()` 改写当前位置

### 7.4 `ADController`

建议不要再作为真实自动驾驶状态源，而是二选一：

1. 删除，状态全部并入新的桥接 ViewModel
2. 保留，但仅作为 UI 领域层包装器，底层完全依赖桥接状态

如果目标是降低维护成本，更推荐第 1 种。

## 8. 当前工程里最值得立刻做的重构

第一批建议只做“结构重构”，先不要急着改视觉：

### Phase A: 去演示化

- 保留现有 UI
- 把 `AutowareBridge` 的模拟数据逻辑与 QML 解耦
- 把 `NavigationMapScreen.qml` 中网络请求逻辑抽离

### Phase B: 打通真实桥接

- 新增独立 ROS2 Bridge 进程
- 定义 Qt 与 Bridge 之间的 IPC 协议
- 先打通 vehicle status、operation mode、route state

### Phase C: 地图真实化

- 让地图位置跟随真实 `vehicle/kinematics`
- 让路线高亮来自 Autoware 轨迹
- 让状态卡片显示真实 route/motion/mrm 状态

### Phase D: 页面化任务流

- 地图选点 -> localization initialize
- 设置目标点 -> set_route_points
- 进入 autonomous/stop 模式切换
- 未来再加 accept_start、任务预设、多站点拆分任务

## 9. 版本兼容注意事项

Autoware 文档里存在一个对我们很重要的信号：

- Routing feature 页面里，`CHANGING` 仍被描述为“未实现”
- 但 AD API 列表页已经出现 `/api/routing/change_route` 与 `/api/routing/change_route_points`，版本标记为 `v1.5.0`

这说明“中途改路由”能力与部署版本强相关。

所以桥接层必须做两件事：

1. 启动时读取 `/api/interface/version`
2. 按版本决定是否开放“在线改路由”能力

不要让 QML 页面直接假设某个 Autoware 版本一定支持中途改路。

## 10. 对你这个项目最合适的落地顺序

如果目标是“尽快把现有 Tesla UI 变成可工作的 Autoware HMI”，建议实现顺序如下：

1. 保留现有 Tesla 页面风格和布局，不动主要视觉资产。
2. 新增 ROS2 Bridge 独立进程，先接 `vehicle status + kinematics + operation mode + route state`。
3. 把当前 `AutowareStatusPanel` 改成真实状态面板。
4. 把地图页当前位置、朝向、速度改成真实 Autoware 数据。
5. 把“设终点”接到 `set_route_points`。
6. 把路线高亮改成桥接层下发的真实轨迹。
7. 最后再考虑多路线候选、任务编排、多站点和更复杂的人机交互。

这条顺序最符合“风险最低、效果最快、视觉不散”的目标。

## 11. 官方参考

- AD API 总览: https://autowarefoundation.github.io/autoware-documentation/release-v1.0_beta/design/autoware-interfaces/ad-api/
- AD API 列表: https://autowarefoundation.github.io/autoware-documentation/main/design/autoware-interfaces/ad-api/list/
- Routing 功能: https://autowarefoundation.github.io/autoware-documentation/pr-480/design/autoware-interfaces/ad-api/features/routing/
- `set_route_points`: https://autowarefoundation.github.io/autoware-documentation/main/design/autoware-interfaces/ad-api/list/api/routing/set_route_points/
- `change_route_points`: https://autowarefoundation.github.io/autoware-documentation/main/design/autoware-interfaces/ad-api/list/api/routing/change_route_points/
- Localization: https://autowarefoundation.github.io/autoware-documentation/pr-279/design/autoware-interfaces/ad-api/features/localization/
- `localization/initialize`: https://autowarefoundation.github.io/autoware-documentation/main/design/autoware-interfaces/ad-api/list/api/localization/initialize/
- Operation mode: https://autowarefoundation.github.io/autoware-documentation/pr-544/design/autoware-interfaces/ad-api/features/operation_mode/
- `operation_mode/state`: https://autowarefoundation.github.io/autoware-documentation/fix-toggle/design/autoware-interfaces/ad-api/list/api/operation_mode/state/
- Motion: https://autowarefoundation.github.io/autoware-documentation/pr-279/design/autoware-interfaces/ad-api/features/motion/
- `motion/accept_start`: https://autowarefoundation.github.io/autoware-documentation/main/design/autoware-interfaces/ad-api/list/api/motion/accept_start/
- Vehicle status: https://autowarefoundation.github.io/autoware-documentation/main/design/autoware-interfaces/ad-api/features/vehicle-status/
- `vehicle/kinematics`: https://autowarefoundation.github.io/autoware-documentation/latest/design/autoware-interfaces/ad-api/list/api/vehicle/kinematics/
- `vehicle/status`: https://autowarefoundation.github.io/autoware-documentation/main/design/autoware-interfaces/ad-api/list/api/vehicle/status/
- Planning factors: https://autowarefoundation.github.io/autoware-documentation/main/design/autoware-interfaces/ad-api/features/planning-factors/
- `planning/velocity_factors`: https://autowarefoundation.github.io/autoware-documentation/pr-366/design/autoware-interfaces/ad-api/list/api/planning/velocity_factors/
- `planning/steering_factors`: https://autowarefoundation.github.io/autoware-documentation/pr-279/design/autoware-interfaces/ad-api/list/api/planning/steering_factors/
- Fail-safe / MRM: https://autowarefoundation.github.io/autoware-documentation/pr-366/design/autoware-interfaces/ad-api/list/api/fail_safe/
- Planning component design: https://autowarefoundation.github.io/autoware-documentation/pr-473/design/autoware-architecture/planning/
- Interface mapping: https://autowarefoundation.github.io/autoware-documentation/pr-279/design/autoware-interfaces/components/interfaces/
