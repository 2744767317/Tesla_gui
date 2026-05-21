import QtQuick 2.9
import QtLocation 6.10
import QtQml 2.3
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtPositioning
import Style 1.0
import "Components"
import "qrc:/LayoutManager.js" as Responsive

Page {
    id: pageMap

    property var currentLoc: QtPositioning.coordinate(39.9042, 116.4074)
    property var demoStartLoc: QtPositioning.coordinate(39.9042, 116.4074)
    property var demoDestinationLoc: QtPositioning.coordinate(40.4319, 116.5704)
    property var destinationLoc: QtPositioning.coordinate(40.4319, 116.5704)
    property alias routePath: routeState.routePath
    property alias drivePath: routeState.drivePath
    property alias routeDistanceCache: routeState.routeDistanceCache
    property alias routeRenderPath: routeState.routeRenderPath
    property alias routeInteractionPath: routeState.routeInteractionPath
    property alias routeSteps: routeState.routeSteps
    property alias routeOptions: routeState.routeOptions
    property alias searchResults: searchState.searchResults
    property alias localPlaces: searchState.localPlaces
    property alias quickPlaces: searchState.quickPlaces
    property alias favoritePlaces: searchState.favoritePlaces
    property alias historyPlaces: searchState.historyPlaces
    property alias activeRouteIndex: routeState.activeRouteIndex
    property alias routePlaybackStep: playbackState.routePlaybackStep
    property alias routeCursorIndex: routeState.routeCursorIndex
    property alias routeSegmentIndex: routeState.routeSegmentIndex
    property alias routeProgressDistanceMeters: playbackState.routeProgressDistanceMeters
    property alias routeTotalDistanceMeters: routeState.routeTotalDistanceMeters
    property alias smoothedMapBearing: cameraController.smoothedMapBearing
    property alias cameraRigLat: cameraController.cameraRigLat
    property alias cameraRigLng: cameraController.cameraRigLng
    property alias cameraLeadDistanceMeters: cameraController.cameraLeadDistanceMeters
    property alias cameraFollowEase: cameraController.cameraFollowEase
    property alias cameraBearingEase: cameraController.cameraBearingEase
    property alias cameraTargetCoordinate: cameraController.cameraTargetCoordinate
    property alias routeStatus: routeState.routeStatus
    property alias routeHint: routeState.routeHint
    property alias searchHint: searchState.searchHint
    property string destinationName: "八达岭长城，北京，中国"
    property alias routePreference: routeState.routePreference
    property alias cameraMode: cameraController.mode
    property string liveLocationStatus: "手动定位 北京"
    property alias followZoomLevel: cameraController.followZoomLevel
    property alias followTiltLevel: cameraController.followTiltLevel
    property alias inspectTiltLevel: cameraController.inspectTiltLevel
    property alias freeMinZoomLevel: cameraController.freeMinZoomLevel
    property alias freeMaxZoomLevel: cameraController.freeMaxZoomLevel
    property alias pendingZoomLevel: cameraController.pendingZoomLevel
    property alias wheelZoomAnchorPoint: cameraController.wheelZoomAnchorPoint
    property alias wheelZoomAnchorCoordinate: cameraController.wheelZoomAnchorCoordinate
    property bool isRoutingStart: false
    property bool runMapAnimation: false
    property bool enableGradient: true
    property bool showDebugControls: false
    property alias showSearchResults: searchState.showSearchResults
    property alias routeRequestInFlight: routeState.routeRequestInFlight
    readonly property var searchStateObject: searchState
    readonly property var tileSettingsObject: mapTileSettings
    readonly property var mapDataServiceObject: mapDataService
    property var navigationController: navCtrl
    readonly property bool navigationActive: navCtrl && navCtrl.isNavigating
    property bool useDevicePosition: false
    property bool mapDragActive: false
    property alias mapViewportInteracting: cameraController.viewportInteracting
    property alias visualPlaybackTick: playbackState.visualPlaybackTick
    property point mapDragLastPoint: Qt.point(0, 0)
    property bool navPanelVisible: true
    property real navPanelScale: 1.0
    property bool navPanelCompactMode: true
    readonly property var adaptive: new Responsive.AdaptiveLayoutManager(width, height, width, height)
    readonly property var mapObject: mapCanvas
    readonly property var currentLocationMarker: mapCanvas.currentLocationMarkerItem
    readonly property var destinationMarker: mapCanvas.destinationMarkerItem
    readonly property var startMarker: mapCanvas.startMarkerItem
    padding: 0

    MapRouteState {
        id: routeState
    }

    MapSearchState {
        id: searchState
    }

    RoutePlaybackState {
        id: playbackState
        cameraRigLat: pageMap.currentLoc.latitude
        cameraRigLng: pageMap.currentLoc.longitude
        cameraTargetCoordinate: pageMap.currentLoc
        wheelZoomAnchorCoordinate: pageMap.currentLoc
    }

    MapTileSourceState {
        id: tileSourceState
        tileSettings: mapTileSettings
        darkTheme: Style.isDark
    }

    MapCameraController {
        id: cameraController
        pageMap: pageMap
        mapObject: pageMap.mapObject
        vehicleMarker: pageMap.currentLocationMarker
        routePath: pageMap.routePath
        currentLoc: pageMap.currentLoc
        routeActive: pageMap.routePath.length > 0
        navigationActive: pageMap.navigationActive
    }

    function resetRouteState(keepMarkers) {
        // 每次重新规划前先清理动画和旧路线，避免旧状态影响新路线显示。
        playbackController.stopAll()
        cameraController.stopRig()
        isRoutingStart = false
        currentLocationMarker.coordinate = currentLoc
        routeCursorIndex = 0
        routePath = []
        drivePath = []
        routeDistanceCache = []
        routeRenderPath = []
        routeInteractionPath = []
        routeSteps = []
        routeOptions = []
        activeRouteIndex = 0
        routeSegmentIndex = 0
        routeProgressDistanceMeters = 0
        routeTotalDistanceMeters = 0
        cameraTargetCoordinate = currentLoc
        visualPlaybackTick = 0
        routeStatus = "idle"

        if (!keepMarkers) {
            startMarker.visible = false
            destinationMarker.visible = false
            currentLocationMarker.visible = false
        }
    }

    function adjustNavPanelScale(delta) {
        navPanelScale = Math.max(0.92, Math.min(1.08, navPanelScale + delta))
    }

    function syncCompactMode() {
        navPanelCompactMode = true
    }

    function selectCustomMapType() {
        if (!mapObject || !mapObject.supportedMapTypes.length)
            return

        mapObject.activeMapType = mapObject.supportedMapTypes[mapObject.supportedMapTypes.length - 1]
    }

    function startAnimation() {
        syncCompactMode()
        requestRoute()
    }

    function reroute() {
        requestRoute()
    }

    function resetToDemoRoute() {
        currentLoc = demoStartLoc
        destinationLoc = demoDestinationLoc
        destinationName = "八达岭长城，北京，中国"
        liveLocationStatus = "手动定位 北京"
        navPanel.searchText = ""
        searchHint = ""
        requestRoute()
    }

    onWidthChanged: {
        syncCompactMode()
        adaptive.updateWindowWidth(width)
    }

    onHeightChanged: {
        syncCompactMode()
        adaptive.updateWindowHeight(height)
    }

    function setDestinationFromCoordinate(coordinate, label) {
        destinationLoc = coordinate
        destinationName = label && label.length ? localizePlaceName(label) : "选点 " + coordinateLabel(coordinate)
        searchState.recordHistory({
            name: destinationName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        })
        routeHint = "目的地已更新"
        searchHint = ""
        showSearchResults = false
        requestReverseDestinationName(coordinate)
        requestRoute()
    }

    function setStartFromCoordinate(coordinate) {
        currentLoc = coordinate
        currentLocationMarker.coordinate = coordinate
        currentLocationMarker.visible = true
        liveLocationStatus = "手动定位 " + coordinateLabel(coordinate)
        routeHint = "起点已更新"
        searchHint = ""
        requestRoute()
    }

    function updateLiveCoordinate(coordinate, sourceName) {
        if (!coordinate || !coordinate.isValid)
            return

        currentLoc = coordinate
        currentLocationMarker.coordinate = coordinate
        currentLocationMarker.visible = true
        liveLocationStatus = sourceName + " " + coordinateLabel(coordinate)
    }

    function setCameraMode(mode) {
        cameraController.setMode(mode)
    }

    function beginViewportInteraction() {
        cameraController.beginViewportInteraction()
    }

    function endViewportInteraction() {
        cameraController.endViewportInteraction()
    }

    function queueWheelZoom(screenPoint, zoomDelta) {
        cameraController.queueWheelZoom(screenPoint, zoomDelta)
    }

    function routeDistanceMiles() {
        return routeState.routeDistanceMiles(routePath)
    }

    function buildDemoRoute() {
        return routeState.buildDemoRoute(currentLoc, destinationLoc, 180)
    }

    function coordinateLabel(coordinate) {
        return coordinate.latitude.toFixed(4) + ", " + coordinate.longitude.toFixed(4)
    }

    function translateTerm(text) {
        return searchState.translateTerm(text)
    }

    function localizePlaceName(name) {
        return searchState.localizePlaceName(name)
    }

    function destinationLabel() {
        return destinationName && destinationName.length ? localizePlaceName(destinationName) : "选点 " + coordinateLabel(destinationLoc)
    }

    function formatMiles(value) {
        var km = value * 1.609344
        return km >= 10 ? km.toFixed(0) + " 公里" : km.toFixed(1) + " 公里"
    }

    function formatMinutes(value) {
        if (value < 1)
            return "<1 分钟"
        if (value < 60)
            return Math.round(value) + " 分钟"

        var hours = Math.floor(value / 60)
        var minutes = Math.round(value % 60)
        return hours + " 小时 " + minutes + " 分钟"
    }

    function bearingBetween(fromCoord, toCoord) {
        return routeState.bearingBetween(fromCoord, toCoord)
    }

    function angleDeltaDegrees(firstAngle, secondAngle) {
        return routeState.angleDeltaDegrees(firstAngle, secondAngle)
    }

    function currentBearing() {
        if (drivePath.length < 2)
            return mapObject.bearing

        var nextIndex = Math.min(drivePath.length - 1, routeSegmentIndex + 1)
        return bearingBetween(drivePath[routeSegmentIndex], drivePath[nextIndex])
    }

    function shortestAngleDelta(fromAngle, toAngle) {
        return routeState.shortestAngleDelta(fromAngle, toAngle)
    }

    function smoothBearing(fromAngle, toAngle, factor) {
        return routeState.smoothBearing(fromAngle, toAngle, factor)
    }

    function rebuildRouteDistanceCache() {
        routeState.rebuildRouteDistanceCache(drivePath)
    }

    function coordinateAtRouteDistance(distanceMeters, updatePlaybackCursor) {
        if (!drivePath.length)
            return currentLoc
        return routeState.coordinateAtRouteDistance(distanceMeters, updatePlaybackCursor)
    }

    function interpolateCoordinate(fromCoord, toCoord, ratio) {
        return routeState.interpolateCoordinate(fromCoord, toCoord, ratio)
    }

    function densifySegment(segmentStart, segmentEnd, stepMeters, output) {
        routeState.densifySegment(segmentStart, segmentEnd, stepMeters, output)
    }

    function resampleDrivePath(path) {
        return routeState.resampleDrivePath(path)
    }

    function simplifyRenderPath(path, minPointDistanceMeters, keepTurnDegrees) {
        return routeState.simplifyRenderPath(path, minPointDistanceMeters, keepTurnDegrees)
    }

    function coordinateAheadOfCurrent(distanceMetersAhead) {
        if (!drivePath.length)
            return currentLoc
        return routeState.coordinateAheadOfCurrent(distanceMetersAhead, routeProgressDistanceMeters)
    }

    function updateCameraTargetCoordinate() {
        cameraController.updateTargetCoordinate()
    }

    function tickCameraRig() {
        cameraController.tickRig()
    }

    function playbackMetersPerTick() {
        return playbackState.playbackMetersPerTick(vehicleCtrl ? vehicleCtrl.speed : 0,
                                                    vehicleCtrl && vehicleCtrl.isDriving,
                                                    playbackController.playbackIntervalMs,
                                                    routeTotalDistanceMeters)
    }

    function updateFollowCamera(coordinate) {
        cameraController.updateFollowTarget(coordinate)
    }

    function buildFallbackRouteSteps() {
        return routeState.buildFallbackRouteSteps(routeDistanceMiles(), destinationLabel())
    }

    function coordinatePathFromPoints(pathPoints) {
        return routeState.coordinatePathFromPoints(pathPoints)
    }

    function localizedStepsFromService(steps) {
        return routeState.localizedStepsFromService(steps, localizePlaceName)
    }

    function serviceRouteToOption(routeData, index) {
        return routeState.serviceRouteToOption(routeData, index, localizePlaceName)
    }

    function scoreRouteOptions(options) {
        return routeState.scoreRouteOptions(options, routePreference)
    }

    function applyRouteOption(option, statusText) {
        if (!option || !option.path || !option.path.length)
            return

        routePath = option.path
        drivePath = resampleDrivePath(routePath)
        routeRenderPath = simplifyRenderPath(routePath, 90, 10)
        routeInteractionPath = simplifyRenderPath(routePath, 220, 18)
        routeSteps = option.steps || []
        routeCursorIndex = 0
        routeSegmentIndex = 0
        routeProgressDistanceMeters = 0
        updatePlaybackPace()
        rebuildRouteDistanceCache()
        routeStatus = statusText
        currentLocationMarker.coordinate = drivePath.length ? drivePath[0] : routePath[0]
        currentLocationMarker.visible = true
        startMarker.coordinate = option.snappedStart && option.snappedStart.isValid ? option.snappedStart : routePath[0]
        destinationMarker.coordinate = option.snappedEnd && option.snappedEnd.isValid ? option.snappedEnd : routePath[routePath.length - 1]
        startMarker.visible = true
        destinationMarker.visible = true
        smoothedMapBearing = currentBearing()
        cameraRigLat = currentLocationMarker.coordinate.latitude
        cameraRigLng = currentLocationMarker.coordinate.longitude
        cameraTargetCoordinate = currentLocationMarker.coordinate

        if (navCtrl)
            navCtrl.prepareRoute(destinationLabel(), drivePath.length, routeSteps)

        fitRouteInView()
        routeHint = option.title + " · " + formatMiles(option.distanceMiles) + " · " + formatMinutes(option.durationMinutes)
        playbackController.scheduleRoutePreview()
    }

    function selectRouteOption(index) {
        if (index < 0 || index >= routeOptions.length)
            return

        activeRouteIndex = index
        applyRouteOption(routeOptions[index], routeStatus === "fallback" ? "fallback" : "ready")
    }

    function fitRouteInView() {
        cameraController.fitRouteInView()
    }

    function updatePlaybackPace() {
        if (!drivePath.length) {
            routePlaybackStep = 1
            return
        }

        var baseStep = Math.max(1, Math.floor(drivePath.length / 650))
        var speed = vehicleCtrl && vehicleCtrl.isDriving ? vehicleCtrl.speed : 45
        var speedFactor = speed < 35 ? 1 : speed < 85 ? 2 : 3
        routePlaybackStep = baseStep * speedFactor
    }

    function startNavigation() {
        if (!routePath.length) {
            routeHint = routeRequestInFlight ? "路线规划中，请稍候" : "请先搜索或点击地图选择目的地"
            if (!routeRequestInFlight)
                requestRoute()
            return
        }

        if (navCtrl)
            navCtrl.startRoute()

        routeHint = "导航已开始 · 跟随路线行驶"
        startMarker.visible = false
        currentLocationMarker.visible = true
        isRoutingStart = true
        setCameraMode("follow")
        routeProgressDistanceMeters = Math.min(routeProgressDistanceMeters, routeTotalDistanceMeters)
        playbackController.beginDrivePlayback()
    }

    function stopNavigation() {
        playbackController.stopDrivePlayback()
        isRoutingStart = false
        cameraController.stopRig()
        if (navCtrl)
            navCtrl.stopRoute()
        if (routePath.length)
            routeHint = "导航已暂停 · 可继续或重算路线"
    }

    function toggleNavigation() {
        if (navCtrl && navCtrl.isNavigating)
            stopNavigation()
        else
            startNavigation()
    }

    function syncDrivePlayback() {
        playbackController.syncDrivePlayback()
    }

    function requestRoute() {
        resetRouteState(true)
        routeStatus = "loading"
        routeHint = "正在请求最优路线"
        routeRequestInFlight = true
        playbackController.cancelFallbackRoute()
        if (mapDataService) {
            // 在线路线规划统一收口到 C++，QML 只处理交互和展示。
            mapDataService.requestRoute(
                currentLoc.latitude,
                currentLoc.longitude,
                destinationLoc.latitude,
                destinationLoc.longitude
            )
        }
    }

    function parseCoordinateQuery(query) {
        return searchState.parseCoordinateQuery(query)
    }

    function searchPlaces(query, committed) {
        var normalizedQuery = query === undefined || query === null ? "" : String(query).trim()
        if (normalizedQuery.length < 2) {
            if (committed)
                searchState.showQuickSuggestions("常用地点")
            else {
                searchState.searchResults = []
                searchState.showSearchResults = false
                searchState.searchHint = ""
            }
            return
        }

        var coordinate = parseCoordinateQuery(normalizedQuery)
        if (coordinate && committed) {
            // 明确提交且识别为坐标时，直接设为目的地，不再走在线地点搜索。
            searchState.searchResults = []
            searchState.showSearchResults = false
            searchState.searchHint = "已按坐标定位"
            setDestinationFromCoordinate(coordinate, "坐标 " + coordinateLabel(coordinate))
            return
        }

        var localResults = localSearchResults(normalizedQuery)
        searchResults = localResults
        showSearchResults = localResults.length > 0
        searchState.searchHint = localResults.length ? "本地匹配 · 在线补全中" : "在线搜索中"
        if (mapDataService) {
            mapDataService.searchPlaces(
                normalizedQuery,
                currentLoc.latitude,
                currentLoc.longitude
            )
        } else if (!localResults.length) {
            searchState.searchHint = "搜索服务不可用"
        }
    }

    function localSearchResults(query) {
        return searchState.localSearchResults(query)
    }

    function applyLocalSearchResults(query, message) {
        searchState.applyLocalSearchResults(query, message)
    }

    function mergedSearchResults(onlineResults, query) {
        var normalizedOnline = []
        for (var index = 0; index < onlineResults.length; index++) {
            normalizedOnline.push({
                name: localizePlaceName(onlineResults[index].name || "搜索结果"),
                latitude: Number(onlineResults[index].latitude),
                longitude: Number(onlineResults[index].longitude),
                sourceType: onlineResults[index].sourceType || "online",
                sourceLabel: onlineResults[index].sourceLabel || "在线"
            })
        }
        return searchState.mergeSearchResults(normalizedOnline, query, 8)
    }

    function chooseSearchPlace(place) {
        if (!place)
            return

        navPanel.searchText = place.name
        setDestinationFromCoordinate(QtPositioning.coordinate(place.latitude, place.longitude), place.name)
    }

    function setCurrentDestinationAsHome() {
        searchState.setHomePlace({
            name: destinationLabel(),
            latitude: destinationLoc.latitude,
            longitude: destinationLoc.longitude
        })
        searchHint = "已设为 Home"
        searchState.showQuickSuggestions("常用地点已更新")
    }

    function setCurrentDestinationAsWork() {
        searchState.setWorkPlace({
            name: destinationLabel(),
            latitude: destinationLoc.latitude,
            longitude: destinationLoc.longitude
        })
        searchHint = "已设为 Work"
        searchState.showQuickSuggestions("常用地点已更新")
    }

    function toggleCurrentDestinationFavorite() {
        var added = searchState.toggleFavorite({
            name: destinationLabel(),
            latitude: destinationLoc.latitude,
            longitude: destinationLoc.longitude
        })
        searchHint = added ? "已加入收藏" : "已取消收藏"
        searchState.showQuickSuggestions("常用地点已更新")
    }

    function requestReverseDestinationName(coordinate) {
        if (mapDataService)
            mapDataService.reverseGeocode(coordinate.latitude, coordinate.longitude)
    }

    Connections {
        target: vehicleCtrl

        function onIsDrivingChanged() {
            pageMap.syncDrivePlayback()
        }

        function onSpeedChanged() {
            pageMap.syncDrivePlayback()
        }
    }

    Connections {
        target: navCtrl

        function onIsNavigatingChanged() {
            if (!navCtrl.isNavigating) {
                playbackController.stopDrivePlayback()
                isRoutingStart = false
                cameraController.stopRig()
            } else {
                pageMap.setCameraMode("follow")
                pageMap.syncDrivePlayback()
            }
        }
    }

    Connections {
        target: mapDataService

        function onRouteReady(serviceRoutes) {
            routeRequestInFlight = false
            if (!serviceRoutes.length) {
                routeStatus = "empty"
                routeHint = "未找到可用路线"
                return
            }

            var options = []
            for (var index = 0; index < serviceRoutes.length; index++)
                options.push(serviceRouteToOption(serviceRoutes[index], index))

            playbackController.cancelFallbackRoute()
            routeOptions = scoreRouteOptions(options)
            activeRouteIndex = 0
            applyRouteOption(routeOptions[0], "ready")
        }

        function onRouteFailed(message) {
            routeRequestInFlight = false
            routeStatus = "network-error"
            routeHint = message && message.length ? message : "路线服务暂不可用"
            playbackController.scheduleFallbackRoute()
        }

        function onSearchCompleted(query, onlineResults, success, message) {
            var activeQuery = navPanel.searchText ? String(navPanel.searchText).trim() : ""
            if (String(query) !== activeQuery)
                return

            if (!success) {
                applyLocalSearchResults(query, message)
                return
            }

            var results = mergedSearchResults(onlineResults, query)
            if (!results.length) {
                applyLocalSearchResults(query, message && message.length ? message : "未找到在线结果")
                return
            }

            searchResults = results
            showSearchResults = true
            searchHint = "共 " + results.length + " 条结果"
        }

        function onReverseGeocodeResolved(lat, lng, displayName) {
            if (Math.abs(destinationLoc.latitude - lat) > 0.000001 || Math.abs(destinationLoc.longitude - lng) > 0.000001)
                return

            destinationName = displayName
            if (navCtrl && routePath.length)
                navCtrl.prepareRoute(destinationLabel(), drivePath.length, routeSteps)
        }
    }

    PositionSource {
        id: devicePosition
        active: useDevicePosition
        updateInterval: 1000

        onPositionChanged: {
            if (position.coordinate && position.coordinate.isValid)
                updateLiveCoordinate(position.coordinate, "GPS")
        }

        onSourceErrorChanged: {
            if (sourceError !== PositionSource.NoError) {
                useDevicePosition = false
                liveLocationStatus = "GPS 不可用"
            }
        }
    }

    NavigationMapCanvas {
        id: mapCanvas
        tileSourceState: tileSourceState
        tileSettingsObject: pageMap.tileSettingsObject
        mapDataServiceObject: pageMap.mapDataServiceObject
        adaptive: pageMap.adaptive
        currentLoc: pageMap.currentLoc
        routeOptions: pageMap.routeOptions
        activeRouteIndex: pageMap.activeRouteIndex
        routeRenderPath: pageMap.routeRenderPath
        routeInteractionPath: pageMap.routeInteractionPath
        mapViewportInteracting: pageMap.mapViewportInteracting
        markerAnimationDuration: Math.max(70, playbackController.playbackIntervalMs + 18)

        Behavior on center {
            enabled: pageMap.cameraMode !== "follow" && !pageMap.mapViewportInteracting
            CoordinateAnimation { duration: 180 }
        }

        onViewportInteractionBegan: function() { pageMap.beginViewportInteraction() }
        onViewportInteractionEnded: function() { pageMap.endViewportInteraction() }
        onWheelZoomRequested: function(screenPoint, zoomDelta) { pageMap.queueWheelZoom(screenPoint, zoomDelta) }
        onStartCoordinateRequested: function(coordinate) { pageMap.setStartFromCoordinate(coordinate) }
        onDestinationCoordinateRequested: function(coordinate, label) { pageMap.setDestinationFromCoordinate(coordinate, label) }
        onFollowTargetCoordinateChanged: function(coordinate) { pageMap.updateFollowCamera(coordinate) }
    }

    RoutePanel {
        id: navPanel
        visible: pageMap.navPanelVisible
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 28
        anchors.topMargin: 88
        panelScale: pageMap.navPanelScale
        compactMode: pageMap.navPanelCompactMode
        routePreference: pageMap.routePreference
        routeOptions: pageMap.routeOptions
        activeRouteIndex: pageMap.activeRouteIndex
        routeStatus: pageMap.routeStatus
        routeHint: pageMap.routeHint
        searchHint: pageMap.searchHint
        routeRequestInFlight: pageMap.routeRequestInFlight
        navCtrl: pageMap.navigationController
        searchState: pageMap.searchStateObject
        searchResults: pageMap.searchResults
        favoritePlace: ({
                            name: pageMap.destinationLabel(),
                            latitude: pageMap.destinationLoc.latitude,
                            longitude: pageMap.destinationLoc.longitude
                        })
        destinationLabel: pageMap.destinationLabel()
        showSearchResults: pageMap.showSearchResults
        cameraMode: pageMap.cameraMode
        useDevicePosition: pageMap.useDevicePosition
        onSearchRequested: function(query, committed) { pageMap.searchPlaces(query, committed) }
        onPlaceSelected: function(place) { pageMap.chooseSearchPlace(place) }
        onHomeRequested: function() { pageMap.setCurrentDestinationAsHome() }
        onWorkRequested: function() { pageMap.setCurrentDestinationAsWork() }
        onFavoriteRequested: function() { pageMap.toggleCurrentDestinationFavorite() }
        onRoutePreferenceSelected: function(preference) {
            pageMap.routePreference = preference
            if (pageMap.routeOptions.length) {
                pageMap.routeOptions = pageMap.scoreRouteOptions(pageMap.routeOptions)
                pageMap.selectRouteOption(0)
            }
        }
        onRouteOptionSelected: function(index) { pageMap.selectRouteOption(index) }
        onNavigationToggled: function() { pageMap.toggleNavigation() }
        onRecalculateRequested: function() { pageMap.requestRoute() }
        onCameraModeToggleRequested: function() { pageMap.setCameraMode(pageMap.cameraMode === "follow" ? "overview" : "follow") }
        onGpsToggleRequested: function() {
            pageMap.useDevicePosition = !pageMap.useDevicePosition
            pageMap.liveLocationStatus = pageMap.useDevicePosition ? "GPS 等待中" : "手动定位 " + pageMap.coordinateLabel(pageMap.currentLoc)
        }
        onDemoRequested: function() { pageMap.resetToDemoRoute() }
        onHideRequested: function() { pageMap.navPanelVisible = false }
        onCompactModeToggled: function(compact) { pageMap.navPanelCompactMode = compact }
    }

    DesktopButton {
        id: navPanelRestore
        visible: !navPanelVisible
        z: 21
        text: "Navigation"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 28
        anchors.topMargin: 82
        implicitWidth: 80
        implicitHeight: 32
        tone: "ghost"
        compact: true
        onClicked: navPanelVisible = true
    }

    Rectangle {
        visible: navPanelVisible && routeStatus === "idle" && routeOptions.length === 0 && navPanel.searchText.length < 1
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 24
        anchors.topMargin: 70
        radius: 999
        color: "#74000000"
        border.width: 1
        border.color: "#2E414A"
        z: 10
        implicitWidth: routeEditHint.implicitWidth + 22
        implicitHeight: routeEditHint.implicitHeight + 10

        Text {
            id: routeEditHint
            anchors.centerIn: parent
            text: "点击地图开始规划"
            color: "#D8F6FF"
            font.family: Style.fontFamily
            font.pixelSize: 11
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 24
        anchors.topMargin: navPanelVisible && routeStatus === "idle" && routeOptions.length === 0 && navPanel.searchText.length < 1
            ? 106
            : 70
        radius: 999
        color: tileSourceState.tileSourceColor()
        border.width: 1
        border.color: tileSourceState.tileSourceBorderColor()
        z: 10
        implicitWidth: tileSourceRow.implicitWidth + 20
        implicitHeight: 28

        RowLayout {
            id: tileSourceRow
            anchors.centerIn: parent
            spacing: 7

            Rectangle {
                width: 7
                height: 7
                radius: 4
                color: tileSourceState.tileSourceBorderColor()
            }

            Text {
                text: mapTileSettings ? mapTileSettings.tileSourceLabel : "瓦片源未知"
                font.family: Style.fontFamily
                font.bold: Font.DemiBold
                font.pixelSize: 10
                color: "#E8F7FF"
            }

            Text {
                visible: mapTileSettings && mapTileSettings.tileSourceDetail.length > 0
                text: mapTileSettings ? mapTileSettings.tileSourceDetail : ""
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.maximumWidth: 180
                font.family: Style.fontFamily
                font.pixelSize: 9
                color: "#AFC4CE"
            }
        }
    }

    Rectangle {
        visible: showDebugControls
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 24
        anchors.topMargin: 108
        radius: 8
        color: "#8A000000"
        border.width: 1
        border.color: "#333333"
        z: 10
        implicitWidth: coordinateReadout.implicitWidth + 20
        implicitHeight: coordinateReadout.implicitHeight + 12

        Text {
            id: coordinateReadout
            anchors.centerIn: parent
            text: "车辆 " + coordinateLabel(currentLocationMarker.coordinate)
                + "  中心 " + coordinateLabel(mapObject.center)
                + "  缩放 " + mapObject.zoomLevel.toFixed(1)
            color: "#F2F2F2"
            font.family: Style.fontFamily
            font.pixelSize: 12
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: navPanel.bottom
        anchors.leftMargin: 18
        anchors.topMargin: 10
        radius: 8
        color: "#8A000000"
        border.width: 1
        border.color: "#333333"
        visible: showDebugControls
        z: 10
        implicitWidth: routeInfoText.implicitWidth + 18
        implicitHeight: routeInfoText.implicitHeight + 10

        Text {
            id: routeInfoText
            anchors.centerIn: parent
            color: "#F2F2F2"
            font.family: Style.fontFamily
            font.pixelSize: 13
            text: "路线: " + routeStatus
                + "  方案: " + routeOptions.length
                + "  原始/行驶点: " + routePath.length + "/" + drivePath.length
        }
    }

    NavigationPlaybackController {
        id: playbackController
        pageMap: pageMap
    }
}
