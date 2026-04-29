import QtQuick 2.9
import QtLocation
import QtQml 2.3
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtPositioning
import Style 1.0

Page {
    id: pageMap

    property var currentLoc: QtPositioning.coordinate(39.9042, 116.4074)
    property var demoStartLoc: QtPositioning.coordinate(39.9042, 116.4074)
    property var demoDestinationLoc: QtPositioning.coordinate(40.4319, 116.5704)
    property var destinationLoc: QtPositioning.coordinate(40.4319, 116.5704)
    property var routePath: []
    property var routeSteps: []
    property var routeOptions: []
    property var searchResults: []
    property var localPlaces: [
        { name: "北京，中国", keywords: "beijing 北京", latitude: 39.9042, longitude: 116.4074 },
        { name: "上海，中国", keywords: "shanghai 上海", latitude: 31.2304, longitude: 121.4737 },
        { name: "深圳，中国", keywords: "shenzhen 深圳", latitude: 22.5431, longitude: 114.0579 },
        { name: "广州，中国", keywords: "guangzhou 广州", latitude: 23.1291, longitude: 113.2644 },
        { name: "杭州，中国", keywords: "hangzhou 杭州", latitude: 30.2741, longitude: 120.1551 },
        { name: "成都，中国", keywords: "chengdu 成都", latitude: 30.5728, longitude: 104.0668 },
        { name: "西安，中国", keywords: "xian xi'an 西安", latitude: 34.3416, longitude: 108.9398 },
        { name: "武汉，中国", keywords: "wuhan 武汉", latitude: 30.5928, longitude: 114.3055 },
        { name: "天安门广场，北京，中国", keywords: "tiananmen 天安门 北京", latitude: 39.9087, longitude: 116.3975 },
        { name: "八达岭长城，北京，中国", keywords: "great wall changcheng 长城 北京", latitude: 40.4319, longitude: 116.5704 },
        { name: "北京南站，北京，中国", keywords: "beijing south railway station 北京南站", latitude: 39.8652, longitude: 116.3785 },
        { name: "首都国际机场，北京，中国", keywords: "beijing capital airport 首都机场", latitude: 40.0799, longitude: 116.6031 },
        { name: "德里国家首都辖区，印度", keywords: "delhi ncr 印度 德里", latitude: 28.4595, longitude: 77.0266 }
    ]
    property int activeRouteIndex: 0
    property int routePlaybackStep: 1
    property int routeCursorIndex: 0
    property string routeStatus: "idle"
    property string routeHint: "搜索目的地，选择路线后开始驾驶"
    property string destinationName: "八达岭长城，北京，中国"
    property string routePreference: "fastest"
    property string cameraMode: "overview"
    property string liveLocationStatus: "手动定位 北京"
    property int followZoomLevel: 16
    property bool isRoutingStart: false
    property bool runMapAnimation: false
    property bool enableGradient: true
    property bool showDebugControls: false
    property bool showSearchResults: false
    property bool routeRequestInFlight: false
    property bool useDevicePosition: false
    property bool mapDragActive: false
    property point mapDragLastPoint: Qt.point(0, 0)
    property bool navPanelVisible: true
    property real navPanelScale: 1.0
    padding: 0

    function resetRouteState(keepMarkers) {
        animationTimer.stop()
        simulateDrive.stop()
        isRoutingStart = false
        currentLocationMarker.coordinate = currentLoc
        simulateDrive.index = 0
        simulateDrive.path = []
        routeCursorIndex = 0
        routePath = []
        routeSteps = []
        routeOptions = []
        activeRouteIndex = 0
        routeStatus = "idle"

        if (!keepMarkers) {
            startMarker.visible = false
            destinationMarker.visible = false
            currentLocationMarker.visible = false
        }
    }

    function adjustNavPanelScale(delta) {
        navPanelScale = Math.max(0.82, Math.min(1.18, navPanelScale + delta))
    }

    function selectCustomMapType() {
        if (!map.supportedMapTypes.length)
            return

        map.activeMapType = map.supportedMapTypes[map.supportedMapTypes.length - 1]
    }

    function startAnimation() {
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
        searchBox.text = ""
        requestRoute()
    }

    function setDestinationFromCoordinate(coordinate, label) {
        destinationLoc = coordinate
        destinationName = label && label.length ? localizePlaceName(label) : "选点 " + coordinateLabel(coordinate)
        routeHint = "目的地已更新"
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
        requestRoute()
    }

    function updateLiveCoordinate(coordinate, sourceName) {
        if (!coordinate || !coordinate.isValid)
            return

        currentLoc = coordinate
        currentLocationMarker.coordinate = coordinate
        currentLocationMarker.visible = true
        liveLocationStatus = sourceName + " " + coordinateLabel(coordinate)

        if (cameraMode === "follow")
            map.center = coordinate
    }

    function setCameraMode(mode) {
        cameraMode = mode
        if (mode === "overview") {
            fitRouteInView()
        } else if (mode === "follow") {
            map.center = currentLocationMarker.visible ? currentLocationMarker.coordinate : currentLoc
            map.zoomLevel = followZoomLevel
            map.tilt = 58
        }
    }

    function routeDistanceMiles() {
        if (!routePath.length)
            return 0

        var meters = 0
        for (var index = 1; index < routePath.length; index++)
            meters += routePath[index - 1].distanceTo(routePath[index])
        return meters / 1609.344
    }

    function buildDemoRoute() {
        var points = []
        var pointCount = 180

        for (var index = 0; index <= pointCount; index++) {
            var progress = index / pointCount
            var latitude = currentLoc.latitude + (destinationLoc.latitude - currentLoc.latitude) * progress
            var longitude = currentLoc.longitude + (destinationLoc.longitude - currentLoc.longitude) * progress
            var wave = Math.sin(progress * Math.PI * 1.6) * 0.0026

            points.push(QtPositioning.coordinate(latitude + wave * 0.55, longitude + wave))
        }

        return points
    }

    function coordinateLabel(coordinate) {
        return coordinate.latitude.toFixed(4) + ", " + coordinate.longitude.toFixed(4)
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
            "Shaanxi": "陕西",
            "Province": "省",
            "Stadium": "体育场",
            "Great Wall of China": "长城",
            "Tiananmen Square": "天安门广场",
            "Beijing South Railway Station": "北京南站",
            "Beijing Capital International Airport": "首都国际机场",
            "Shaanxi Province Stadium": "陕西省体育场",
            "Xi'an City Wall": "西安城墙",
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
            ["Xi'an", "西安"],
            ["Xi’an", "西安"],
            ["Beijing", "北京"],
            ["Shanghai", "上海"],
            ["China", "中国"],
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
        var lat1 = fromCoord.latitude * Math.PI / 180
        var lat2 = toCoord.latitude * Math.PI / 180
        var dLon = (toCoord.longitude - fromCoord.longitude) * Math.PI / 180
        var y = Math.sin(dLon) * Math.cos(lat2)
        var x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon)
        return (Math.atan2(y, x) * 180 / Math.PI + 360) % 360
    }

    function currentBearing() {
        if (routePath.length < 2)
            return map.bearing

        var nextIndex = Math.min(routePath.length - 1, routeCursorIndex + Math.max(1, routePlaybackStep))
        return bearingBetween(routePath[routeCursorIndex], routePath[nextIndex])
    }

    function buildFallbackRouteSteps() {
        return [
            {
                type: "depart",
                modifier: "straight",
                street: "已选起点",
                distanceMiles: Math.max(0.1, routeDistanceMiles() * 0.28),
                durationMinutes: 2
            },
            {
                type: "turn",
                modifier: "slight right",
                street: "演示路线",
                distanceMiles: Math.max(0.2, routeDistanceMiles() * 0.62),
                durationMinutes: 7
            },
            {
                type: "arrive",
                modifier: "straight",
                street: destinationLabel(),
                distanceMiles: Math.max(0.05, routeDistanceMiles() * 0.1),
                durationMinutes: 1
            }
        ]
    }

    function normalizeOsrmSteps(route) {
        if (!route || !route.legs)
            return []

        var normalized = []

        for (var legIndex = 0; legIndex < route.legs.length; legIndex++) {
            var legSteps = route.legs[legIndex].steps || []

            for (var stepIndex = 0; stepIndex < legSteps.length; stepIndex++) {
                var step = legSteps[stepIndex]
                var maneuver = step.maneuver || {}
                normalized.push({
                    type: maneuver.type || "",
                    modifier: maneuver.modifier || "",
                    street: step.name && step.name.length ? localizePlaceName(step.name) : "未命名道路",
                    distanceMiles: (step.distance || 0) / 1609.344,
                    durationMinutes: (step.duration || 0) / 60
                })
            }
        }

        return normalized
    }

    function osrmRouteToOption(route, index) {
        var coordinates = route.geometry.coordinates
        var convertedPath = []

        for (var pointIndex = 0; pointIndex < coordinates.length; pointIndex++)
            convertedPath.push(QtPositioning.coordinate(coordinates[pointIndex][1], coordinates[pointIndex][0]))

        return {
            index: index,
            title: index === 0 ? "推荐路线" : "路线 " + (index + 1),
            path: convertedPath,
            steps: normalizeOsrmSteps(route),
            distanceMiles: (route.distance || 0) / 1609.344,
            durationMinutes: (route.duration || 0) / 60,
            score: 0
        }
    }

    function scoreRouteOptions(options) {
        if (!options.length)
            return options

        var minDistance = options[0].distanceMiles
        var minDuration = options[0].durationMinutes

        for (var index = 1; index < options.length; index++) {
            minDistance = Math.min(minDistance, options[index].distanceMiles)
            minDuration = Math.min(minDuration, options[index].durationMinutes)
        }

        for (var optionIndex = 0; optionIndex < options.length; optionIndex++) {
            var option = options[optionIndex]
            if (routePreference === "shortest")
                option.score = option.distanceMiles
            else if (routePreference === "balanced")
                option.score = option.durationMinutes / Math.max(1, minDuration) + option.distanceMiles / Math.max(0.1, minDistance)
            else
                option.score = option.durationMinutes
        }

        options.sort(function(left, right) { return left.score - right.score })
        for (var sortedIndex = 0; sortedIndex < options.length; sortedIndex++)
            options[sortedIndex].title = sortedIndex === 0 ? "推荐路线" : "备选路线 " + sortedIndex

        return options
    }

    function applyRouteOption(option, statusText) {
        if (!option || !option.path || !option.path.length)
            return

        routePath = option.path
        routeSteps = option.steps || []
        routeCursorIndex = 0
        updatePlaybackPace()
        routeStatus = statusText
        currentLocationMarker.coordinate = routePath[0]
        currentLocationMarker.visible = true
        startMarker.coordinate = currentLoc
        destinationMarker.coordinate = routePath[routePath.length - 1]
        startMarker.visible = true
        destinationMarker.visible = true
        simulateDrive.path = routePath
        simulateDrive.index = 0

        if (navCtrl)
            navCtrl.prepareRoute(destinationLabel(), routePath.length, routeSteps)

        fitRouteInView()
        routeHint = option.title + " · " + formatMiles(option.distanceMiles) + " · " + formatMinutes(option.durationMinutes)
        animationTimer.restart()
    }

    function selectRouteOption(index) {
        if (index < 0 || index >= routeOptions.length)
            return

        activeRouteIndex = index
        applyRouteOption(routeOptions[index], routeStatus === "fallback" ? "fallback" : "ready")
    }

    function fitRouteInView() {
        if (!routePath.length)
            return

        var minLat = routePath[0].latitude
        var maxLat = routePath[0].latitude
        var minLon = routePath[0].longitude
        var maxLon = routePath[0].longitude

        for (var index = 1; index < routePath.length; index++) {
            minLat = Math.min(minLat, routePath[index].latitude)
            maxLat = Math.max(maxLat, routePath[index].latitude)
            minLon = Math.min(minLon, routePath[index].longitude)
            maxLon = Math.max(maxLon, routePath[index].longitude)
        }

        map.center = QtPositioning.coordinate((minLat + maxLat) / 2, (minLon + maxLon) / 2)
        var span = Math.max(maxLat - minLat, maxLon - minLon)
        map.zoomLevel = span < 0.01 ? 15 : span < 0.03 ? 13.8 : span < 0.08 ? 12.5 : 11.3
        map.bearing = -18
        map.tilt = 38
        cameraMode = "overview"
    }

    function updatePlaybackPace() {
        if (!routePath.length) {
            routePlaybackStep = 1
            return
        }

        var baseStep = Math.max(1, Math.floor(routePath.length / 650))
        var speed = vehicleCtrl ? vehicleCtrl.speed : 0
        var speedFactor = speed < 35 ? 1 : speed < 85 ? 2 : 3
        routePlaybackStep = baseStep * speedFactor
    }

    function syncDrivePlayback() {
        if (!routePath.length || !currentLocationMarker.visible)
            return

        if (!navCtrl || !vehicleCtrl || !vehicleCtrl.isDriving || vehicleCtrl.speed < 1) {
            simulateDrive.stop()
            return
        }

        if (!navCtrl.isNavigating)
            navCtrl.startRoute()

        updatePlaybackPace()
        simulateDrive.path = routePath
        isRoutingStart = true
        if (!simulateDrive.running) {
            simulateDrive.index = Math.min(routeCursorIndex, routePath.length - 1)
            simulateDrive.start()
        }
    }

    function requestRoute() {
        resetRouteState(true)
        routeStatus = "loading"
        routeHint = "正在请求最优路线"
        routeRequestInFlight = true
        fallbackRouteTimer.restart()

        var xhr = new XMLHttpRequest()
        var routeUrl = "https://router.project-osrm.org/route/v1/driving/"
            + currentLoc.longitude + "," + currentLoc.latitude
            + ";"
            + destinationLoc.longitude + "," + destinationLoc.latitude
            + "?overview=full&geometries=geojson&steps=true&alternatives=true"

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return

            routeRequestInFlight = false

            if (xhr.status < 200 || xhr.status >= 300) {
                routeStatus = "network-error"
                routeHint = "路线服务暂不可用"
                console.log("Route request failed:", xhr.status, xhr.responseText)
                return
            }

            var response = JSON.parse(xhr.responseText)
            if (!response.routes || !response.routes.length) {
                routeStatus = "empty"
                routeHint = "未找到可用路线"
                console.log("Route response did not contain a usable path")
                return
            }

            var options = []
            for (var index = 0; index < response.routes.length; index++) {
                if (response.routes[index].geometry && response.routes[index].geometry.coordinates.length)
                    options.push(osrmRouteToOption(response.routes[index], index))
            }

            if (!options.length) {
                routeStatus = "empty"
                routeHint = "未找到路线几何数据"
                return
            }

            fallbackRouteTimer.stop()
            routeOptions = scoreRouteOptions(options)
            activeRouteIndex = 0
            applyRouteOption(routeOptions[0], "ready")
        }

        xhr.open("GET", routeUrl)
        xhr.send()
    }

    function searchPlaces(query) {
        if (!query || query.trim().length < 2) {
            searchResults = []
            showSearchResults = false
            return
        }

        searchStatus.text = "搜索中"
        var xhr = new XMLHttpRequest()
        var url = "https://photon.komoot.io/api/?limit=6&lang=en&q="
            + encodeURIComponent(query)
            + "&lat=" + currentLoc.latitude
            + "&lon=" + currentLoc.longitude

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return

            if (xhr.status < 200 || xhr.status >= 300) {
                applyLocalSearchResults(query, "本地匹配")
                return
            }

            var response = JSON.parse(xhr.responseText)
            var results = []
            var features = response.features || []
            for (var index = 0; index < features.length; index++) {
                var feature = features[index]
                if (!feature.geometry || !feature.geometry.coordinates || feature.geometry.coordinates.length < 2)
                    continue

                var props = feature.properties || {}
                results.push({
                    name: placeDisplayName(props),
                    latitude: Number(feature.geometry.coordinates[1]),
                    longitude: Number(feature.geometry.coordinates[0])
                })
            }

            var localResults = localSearchResults(query)
            for (var localIndex = 0; localIndex < localResults.length && results.length < 6; localIndex++)
                results.push(localResults[localIndex])

            if (!results.length) {
                applyLocalSearchResults(query, "未找到在线结果")
                return
            }

            searchResults = results
            showSearchResults = true
            searchStatus.text = "共 " + results.length + " 条结果"
        }

        xhr.open("GET", url)
        xhr.setRequestHeader("Accept", "application/json")
        xhr.send()
    }

    function placeDisplayName(props) {
        var pieces = []
        if (props.name)
            pieces.push(props.name)
        if (props.city && props.city !== props.name)
            pieces.push(props.city)
        if (props.state && pieces.indexOf(props.state) < 0)
            pieces.push(props.state)
        if (props.country)
            pieces.push(props.country)
        return pieces.length ? localizePlaceName(pieces.join(", ")) : "搜索结果"
    }

    function localSearchResults(query) {
        var needle = query.toLowerCase()
        var matches = []
        for (var index = 0; index < localPlaces.length; index++) {
            if (localPlaces[index].name.toLowerCase().indexOf(needle) >= 0)
                matches.push(localPlaces[index])
        }
        return matches
    }

    function applyLocalSearchResults(query, message) {
        var results = localSearchResults(query)
        searchResults = results
        showSearchResults = results.length > 0
        searchStatus.text = results.length ? message : "无本地匹配"
    }

    function requestReverseDestinationName(coordinate) {
        var xhr = new XMLHttpRequest()
        var url = "https://photon.komoot.io/reverse?limit=1&lang=en&lat="
            + coordinate.latitude + "&lon=" + coordinate.longitude

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return

            if (xhr.status < 200 || xhr.status >= 300)
                return

            var response = JSON.parse(xhr.responseText)
            if (response && response.features && response.features.length) {
                destinationName = placeDisplayName(response.features[0].properties || {})
                if (navCtrl && routePath.length)
                    navCtrl.prepareRoute(destinationLabel(), routePath.length, routeSteps)
            }
        }

        xhr.open("GET", url)
        xhr.setRequestHeader("Accept", "application/json")
        xhr.send()
    }

    Connections {
        target: vehicleCtrl

        function onIsDrivingChanged() {
            if (!vehicleCtrl.isDriving) {
                simulateDrive.stop()
                isRoutingStart = false
                if (navCtrl && navCtrl.isNavigating)
                    navCtrl.stopRoute()
            } else if (routePath.length && navCtrl && !navCtrl.isNavigating) {
                navCtrl.startRoute()
            }
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
                simulateDrive.stop()
                isRoutingStart = false
            } else {
                pageMap.setCameraMode("follow")
                pageMap.syncDrivePlayback()
            }
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

    Map {
        id: map

        anchors.fill: parent
        copyrightsVisible: false
        center: currentLoc
        zoomLevel: 12.8
        bearing: -28
        tilt: 38

        onSupportedMapTypesChanged: selectCustomMapType()
        Component.onCompleted: {
            selectCustomMapType()
            currentLocationMarker.visible = true
        }

        Behavior on center {
            CoordinateAnimation { duration: 180 }
        }

        plugin: Plugin {
            name: "osm"
            PluginParameter {
                name: "osm.mapping.custom.host"
                value: Style.isDark
                    ? "https://a.basemaps.cartocdn.com/dark_all/%z/%x/%y.png"
                    : "https://tile.openstreetmap.org/%z/%x/%y.png"
            }
            PluginParameter {
                name: "osm.mapping.providersrepository.disabled"
                value: true
            }
            PluginParameter {
                name: "osm.useragent"
                value: "TeslaDashboardUI/1.0"
            }
            PluginParameter {
                name: "osm.geocoding.host"
                value: "https://nominatim.openstreetmap.org"
            }
        }

        MapPolyline {
            visible: routeOptions.length > 1 && activeRouteIndex !== 1
            line.color: "#607A8791"
            line.width: adaptive.width(7)
            path: routeOptions.length > 1 ? routeOptions[1].path : []
        }

        MapPolyline {
            visible: routeOptions.length > 2 && activeRouteIndex !== 2
            line.color: "#50616B72"
            line.width: adaptive.width(6)
            path: routeOptions.length > 2 ? routeOptions[2].path : []
        }

        MapPolyline {
            line.color: "#4033E4FF"
            line.width: adaptive.width(13)
            path: routePath
        }

        MapPolyline {
            line.color: "#11E3F3"
            line.width: adaptive.width(5)
            path: routePath
        }

        MapQuickItem {
            id: currentLocationMarker

            coordinate: currentLoc
            visible: false
            z: 3
            anchorPoint.x: sourceItem.width / 2
            anchorPoint.y: sourceItem.height / 2

            onCoordinateChanged: {
                if (cameraMode === "follow" && isRoutingStart) {
                    map.center = coordinate
                    map.bearing = currentBearing()
                    map.zoomLevel = followZoomLevel
                    map.tilt = 58
                }
            }

            sourceItem: Item {
                width: adaptive.average(58)
                height: adaptive.average(58)

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: width / 2
                    color: "#22F2187A"
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.72
                    height: parent.height * 0.72
                    radius: width / 2
                    color: "#55FF2A96"
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.36
                    height: parent.height * 0.36
                    radius: width / 2
                    color: "#EA0F7A"
                    border.width: 2
                    border.color: "#FFD0E8"
                }
            }

            Behavior on coordinate {
                CoordinateAnimation {
                    duration: Math.max(220, simulateDrive.interval - 20)
                }
            }
        }

        MapQuickItem {
            id: destinationMarker

            visible: false
            z: 2
            anchorPoint.x: sourceItem.width / 2
            anchorPoint.y: sourceItem.height / 2

            sourceItem: Item {
                width: adaptive.average(20)
                height: adaptive.average(20)

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: width / 2
                    color: "#BB11E3F3"
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.45
                    height: parent.height * 0.45
                    radius: width / 2
                    color: "#FFFFFF"
                }
            }
        }

        MapQuickItem {
            id: startMarker

            visible: false
            z: 2
            anchorPoint.x: sourceItem.width / 2
            anchorPoint.y: sourceItem.height / 2

            sourceItem: Item {
                width: adaptive.average(14)
                height: adaptive.average(14)

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: width / 2
                    color: "#FFFFFFFF"
                    border.width: 1
                    border.color: "#11E3F3"
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.CrossCursor
            z: 1

            onPressed: function(mouse) {
                mapDragActive = false
                mapDragLastPoint = Qt.point(mouse.x, mouse.y)
            }

            onPositionChanged: function(mouse) {
                if (!(mouse.buttons & (Qt.LeftButton | Qt.RightButton)))
                    return

                var currentPoint = Qt.point(mouse.x, mouse.y)
                var dx = currentPoint.x - mapDragLastPoint.x
                var dy = currentPoint.y - mapDragLastPoint.y
                if (Math.abs(dx) + Math.abs(dy) < 3)
                    return

                var before = map.toCoordinate(mapDragLastPoint, false)
                var after = map.toCoordinate(currentPoint, false)
                if (before.isValid && after.isValid) {
                    map.center = QtPositioning.coordinate(
                        map.center.latitude + before.latitude - after.latitude,
                        map.center.longitude + before.longitude - after.longitude
                    )
                    cameraMode = "free"
                    mapDragActive = true
                    mapDragLastPoint = currentPoint
                }
            }

            onWheel: function(wheel) {
                var zoomDelta = wheel.angleDelta.y > 0 ? 0.5 : -0.5
                map.zoomLevel = Math.max(3, Math.min(20, map.zoomLevel + zoomDelta))
                cameraMode = "free"
                wheel.accepted = true
            }

            onClicked: function(mouse) {
                if (mapDragActive)
                    return

                var coordinate = map.toCoordinate(Qt.point(mouse.x, mouse.y), false)
                if (!coordinate.isValid)
                    return

                if (mouse.button === Qt.RightButton) {
                    setStartFromCoordinate(coordinate)
                } else {
                    setDestinationFromCoordinate(coordinate, "选点 " + coordinateLabel(coordinate))
                }
            }
        }
    }

    Rectangle {
        id: navPanel
        visible: navPanelVisible
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 18
        anchors.topMargin: 62
        width: Math.min(376, parent.width * 0.42) * navPanelScale
        height: Math.min(484, parent.height - 150) * navPanelScale
        radius: 8
        color: Style.isDark ? "#E6111111" : "#EFFFFFFF"
        border.width: 1
        border.color: Style.isDark ? "#303030" : "#D8D8D8"
        z: 20
        clip: true

        Behavior on width {
            NumberAnimation { duration: 160; easing.type: Easing.InOutQuad }
        }

        Behavior on height {
            NumberAnimation { duration: 160; easing.type: Easing.InOutQuad }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: Math.max(7, 10 * navPanelScale)

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "导航"
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.bold: Font.Bold
                    font.pixelSize: 14
                    color: Style.isDark ? Style.white : Style.black10
                }

                Button {
                    text: "-"
                    implicitWidth: 34
                    implicitHeight: 28
                    onClicked: adjustNavPanelScale(-0.08)
                }

                Button {
                    text: "+"
                    implicitWidth: 34
                    implicitHeight: 28
                    onClicked: adjustNavPanelScale(0.08)
                }

                Button {
                    text: "x"
                    implicitWidth: 34
                    implicitHeight: 28
                    onClicked: navPanelVisible = false
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextField {
                    id: searchBox
                    Layout.fillWidth: true
                    implicitHeight: 38
                    placeholderText: "搜索目的地"
                    color: Style.isDark ? Style.white : Style.black10
                    selectedTextColor: Style.white
                    selectionColor: "#2E78FF"
                    font.family: Style.fontFamily
                    font.pixelSize: 13
                    onAccepted: searchPlaces(text)
                    background: Rectangle {
                        radius: 8
                        color: Style.isDark ? "#252525" : "#F3F4F6"
                        border.width: 1
                        border.color: searchBox.activeFocus ? "#11E3F3" : (Style.isDark ? "#343434" : "#D6D9DE")
                    }
                }

                Button {
                    text: "搜索"
                    implicitWidth: 58
                    implicitHeight: 38
                    onClicked: searchPlaces(searchBox.text)
                }
            }

            Text {
                id: searchStatus
                Layout.fillWidth: true
                text: routeRequestInFlight ? "在线规划中" : routeHint
                elide: Text.ElideRight
                font.family: Style.fontFamily
                font.pixelSize: 12
                color: Style.black20
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: showSearchResults ? 134 : 0
                visible: showSearchResults
                clip: true
                model: searchResults
                spacing: 6

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 38
                    radius: 8
                    color: Style.isDark ? "#252525" : "#F5F6F8"

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        text: modelData.name
                        elide: Text.ElideRight
                        font.family: Style.fontFamily
                        font.pixelSize: 12
                        color: Style.isDark ? Style.white : Style.black10
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            searchBox.text = modelData.name
                            setDestinationFromCoordinate(QtPositioning.coordinate(modelData.latitude, modelData.longitude), modelData.name)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: "最快"
                    checkable: true
                    checked: routePreference === "fastest"
                    implicitHeight: 32
                    Layout.fillWidth: true
                    onClicked: {
                        routePreference = "fastest"
                        if (routeOptions.length) {
                            routeOptions = scoreRouteOptions(routeOptions)
                            selectRouteOption(0)
                        }
                    }
                }

                Button {
                    text: "最短"
                    checkable: true
                    checked: routePreference === "shortest"
                    implicitHeight: 32
                    Layout.fillWidth: true
                    onClicked: {
                        routePreference = "shortest"
                        if (routeOptions.length) {
                            routeOptions = scoreRouteOptions(routeOptions)
                            selectRouteOption(0)
                        }
                    }
                }

                Button {
                    text: "均衡"
                    checkable: true
                    checked: routePreference === "balanced"
                    implicitHeight: 32
                    Layout.fillWidth: true
                    onClicked: {
                        routePreference = "balanced"
                        if (routeOptions.length) {
                            routeOptions = scoreRouteOptions(routeOptions)
                            selectRouteOption(0)
                        }
                    }
                }
            }

            ListView {
                id: routeList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(142, routeOptions.length * 46)
                visible: routeOptions.length > 0
                clip: true
                model: routeOptions
                spacing: 7

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 40
                    radius: 8
                    color: index === activeRouteIndex
                        ? "#2D7F75"
                        : (Style.isDark ? "#242424" : "#F4F5F7")
                    border.width: 1
                    border.color: index === activeRouteIndex ? "#11E3F3" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: modelData.title
                            elide: Text.ElideRight
                            font.family: Style.fontFamily
                            font.bold: Font.Bold
                            font.pixelSize: 13
                            color: Style.white
                        }

                        Text {
                            text: formatMiles(modelData.distanceMiles) + "  " + formatMinutes(modelData.durationMinutes)
                            font.family: Style.fontFamily
                            font.pixelSize: 12
                            color: index === activeRouteIndex ? "#D8F6FF" : Style.black20
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: selectRouteOption(index)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.isDark ? "#303030" : "#D8D8D8"
            }

            Text {
                Layout.fillWidth: true
                text: navCtrl ? navCtrl.destination : destinationLabel()
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                font.family: Style.fontFamily
                font.bold: Font.Bold
                font.pixelSize: 15
                color: Style.isDark ? Style.white : Style.black10
            }

            Text {
                Layout.fillWidth: true
                text: navCtrl ? navCtrl.nextManeuver : "路线尚未准备"
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                font.family: Style.fontFamily
                font.pixelSize: 13
                color: "#11E3F3"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: navCtrl ? formatMiles(navCtrl.distanceToNext) + " 后" : ""
                    font.family: Style.fontFamily
                    font.pixelSize: 12
                    color: Style.black20
                }

                Text {
                    text: navCtrl ? navCtrl.etaMinutes + " 分钟到达" : ""
                    font.family: Style.fontFamily
                    font.pixelSize: 12
                    color: Style.black20
                }
            }

            ProgressBar {
                Layout.fillWidth: true
                from: 0
                to: 1
                value: navCtrl ? navCtrl.routeProgress : 0
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: "重算"
                    Layout.fillWidth: true
                    implicitHeight: 34
                    onClicked: requestRoute()
                }

                Button {
                    text: cameraMode === "follow" ? "总览" : "跟随"
                    Layout.fillWidth: true
                    implicitHeight: 34
                    onClicked: setCameraMode(cameraMode === "follow" ? "overview" : "follow")
                }

                Button {
                    text: useDevicePosition ? "GPS 已开" : "GPS"
                    Layout.fillWidth: true
                    implicitHeight: 34
                    onClicked: {
                        useDevicePosition = !useDevicePosition
                        liveLocationStatus = useDevicePosition ? "GPS 等待中" : "手动定位 " + coordinateLabel(currentLoc)
                    }
                }

                Button {
                    text: "北京"
                    Layout.fillWidth: true
                    implicitHeight: 34
                    onClicked: resetToDemoRoute()
                }
            }
        }
    }

    Button {
        id: navPanelRestore
        visible: !navPanelVisible
        z: 21
        text: "导航"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 18
        anchors.topMargin: 62
        implicitWidth: 72
        implicitHeight: 34
        onClicked: navPanelVisible = true

        background: Rectangle {
            radius: 8
            color: Style.isDark ? "#E6111111" : "#EFFFFFFF"
            border.width: 1
            border.color: "#11E3F3"
        }

        contentItem: Text {
            text: navPanelRestore.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Style.fontFamily
            font.bold: Font.Bold
            font.pixelSize: 13
            color: "#D8F6FF"
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 28
        anchors.topMargin: 64
        radius: 8
        color: "#8A000000"
        border.width: 1
        border.color: "#333333"
        z: 10
        implicitWidth: routeEditHint.implicitWidth + 20
        implicitHeight: routeEditHint.implicitHeight + 10

        Text {
            id: routeEditHint
            anchors.centerIn: parent
            text: "拖拽平移  滚轮缩放  左键终点  右键起点"
            color: "#D8F6FF"
            font.family: Style.fontFamily
            font.pixelSize: 12
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 28
        anchors.topMargin: 104
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
                + "  中心 " + coordinateLabel(map.center)
                + "  缩放 " + map.zoomLevel.toFixed(1)
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
            text: "路线: " + routeStatus + "  方案: " + routeOptions.length + "  点数: " + routePath.length
        }
    }

    Timer {
        id: animationTimer

        interval: 800
        onTriggered: {
            if (!routePath.length)
                return

            startMarker.visible = false
            currentLocationMarker.visible = true
            isRoutingStart = true
            simulateDrive.path = routePath
            simulateDrive.index = routeCursorIndex

            if (vehicleCtrl && vehicleCtrl.isDriving)
                routeStartAnimation.running = true
            syncDrivePlayback()
        }
    }

    Timer {
        id: simulateDrive

        property var path
        property int index

        interval: vehicleCtrl ? Math.max(140, 760 - Math.round(vehicleCtrl.speed * 4)) : 360
        repeat: true
        onTriggered: {
            if (!vehicleCtrl || !vehicleCtrl.isDriving || vehicleCtrl.speed < 1) {
                simulateDrive.stop()
                return
            }

            updatePlaybackPace()
            if (path && path.length > index) {
                updateLiveCoordinate(path[index], "Route")
                routeCursorIndex = index
                if (navCtrl && path.length > 1)
                    navCtrl.updateRouteProgress(index / (path.length - 1))
                index += routePlaybackStep
            } else {
                simulateDrive.stop()
                isRoutingStart = false
                if (navCtrl)
                    navCtrl.markArrived()
            }
        }
    }

    Timer {
        id: fallbackRouteTimer
        interval: 3500
        repeat: false
        onTriggered: {
            if (!routePath.length) {
                routeRequestInFlight = false
                routeStatus = "fallback"
                routeHint = "使用本地演示路线"
                var fallbackPath = buildDemoRoute()
                routePath = fallbackPath
                var fallbackOption = {
                    index: 0,
                    title: "离线预览",
                    path: fallbackPath,
                    steps: buildFallbackRouteSteps(),
                    distanceMiles: routeDistanceMiles(),
                    durationMinutes: 10,
                    score: 0
                }
                routeOptions = [fallbackOption]
                activeRouteIndex = 0
                applyRouteOption(fallbackOption, "fallback")
            }
        }
    }

    Timer {
        id: searchDebounce
        interval: 450
        repeat: false
        onTriggered: searchPlaces(searchBox.text)
    }

    Connections {
        target: searchBox
        function onTextChanged() {
            if (searchBox.activeFocus)
                searchDebounce.restart()
        }
    }

    ParallelAnimation {
        id: routeStartAnimation

        NumberAnimation {
            target: map
            property: "zoomLevel"
            duration: 1200
            from: map.zoomLevel
            to: followZoomLevel
        }

        NumberAnimation {
            target: map
            property: "tilt"
            duration: 1200
            from: map.tilt
            to: 58
        }
    }
}
