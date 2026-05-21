import QtQuick 2.9
import QtPositioning

Item {
    id: root
    visible: false
    width: 0
    height: 0

    property var pageMap: null
    property var mapObject: null
    property var vehicleMarker: null
    property var routePath: []
    property var currentLoc: QtPositioning.coordinate(0, 0)
    property bool routeActive: false
    property bool navigationActive: false
    property string mode: "overview"
    property real cameraRigLat: 0
    property real cameraRigLng: 0
    property real cameraLeadDistanceMeters: 130
    property real cameraFollowEase: 0.085
    property real cameraBearingEase: 0.075
    property var cameraTargetCoordinate: QtPositioning.coordinate(0, 0)
    property real smoothedMapBearing: -28
    property real followZoomLevel: 16
    property real followTiltLevel: 0
    property real inspectTiltLevel: 0
    property real freeMinZoomLevel: 2
    property real freeMaxZoomLevel: 21
    property real pendingZoomLevel: 12.8
    property point wheelZoomAnchorPoint: Qt.point(0, 0)
    property var wheelZoomAnchorCoordinate: QtPositioning.coordinate(0, 0)
    property bool viewportInteracting: false

    property var currentBearingProvider: null
    property var coordinateAheadProvider: null
    property var smoothBearingProvider: null

    function currentBearing() {
        if (currentBearingProvider)
            return currentBearingProvider()
        if (pageMap && pageMap.currentBearing)
            return pageMap.currentBearing()
        return mapObject ? mapObject.bearing : smoothedMapBearing
    }

    function coordinateAhead(distanceMetersAhead) {
        if (coordinateAheadProvider)
            return coordinateAheadProvider(distanceMetersAhead)
        if (pageMap && pageMap.coordinateAheadOfCurrent)
            return pageMap.coordinateAheadOfCurrent(distanceMetersAhead)
        return currentLoc
    }

    function smoothBearing(fromAngle, toAngle, factor) {
        if (smoothBearingProvider)
            return smoothBearingProvider(fromAngle, toAngle, factor)
        if (pageMap && pageMap.smoothBearing)
            return pageMap.smoothBearing(fromAngle, toAngle, factor)
        var delta = ((toAngle - fromAngle + 540) % 360) - 180
        return (fromAngle + delta * factor + 360) % 360
    }

    function setMode(nextMode) {
        mode = nextMode
        if (!mapObject)
            return

        if (nextMode === "overview") {
            cameraRigTimer.stop()
            fitRouteInView()
        } else if (nextMode === "follow") {
            var baseCoordinate = vehicleMarker && vehicleMarker.visible ? vehicleMarker.coordinate : currentLoc
            cameraRigLat = baseCoordinate.latitude
            cameraRigLng = baseCoordinate.longitude
            cameraTargetCoordinate = baseCoordinate
            updateTargetCoordinate()
            smoothedMapBearing = currentBearing()
            mapObject.center = QtPositioning.coordinate(cameraRigLat, cameraRigLng)
            mapObject.bearing = smoothedMapBearing
            mapObject.zoomLevel = followZoomLevel
            pendingZoomLevel = mapObject.zoomLevel
            mapObject.tilt = followTiltLevel
            if (!cameraRigTimer.running)
                cameraRigTimer.start()
        } else if (nextMode === "inspect") {
            cameraRigTimer.stop()
            mapObject.tilt = inspectTiltLevel
        } else {
            cameraRigTimer.stop()
        }
    }

    function beginViewportInteraction() {
        if (viewportInteracting)
            return

        viewportInteractionRelease.stop()
        viewportInteracting = true
        if (mode === "follow")
            setMode("inspect")
    }

    function endViewportInteraction() {
        viewportInteractionRelease.restart()
    }

    function queueWheelZoom(screenPoint, zoomDelta) {
        if (!mapObject)
            return

        beginViewportInteraction()
        wheelZoomAnchorPoint = screenPoint
        wheelZoomAnchorCoordinate = mapObject.toCoordinate(screenPoint, false)
        if (!wheelZoomCommit.running) {
            pendingZoomLevel = mapObject.zoomLevel
            wheelZoomCommit.start()
        }

        pendingZoomLevel = Math.max(freeMinZoomLevel, Math.min(freeMaxZoomLevel, pendingZoomLevel + zoomDelta))
    }

    function fitRouteInView() {
        if (!mapObject || !routePath.length)
            return

        cameraRigTimer.stop()
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

        mapObject.center = QtPositioning.coordinate((minLat + maxLat) / 2, (minLon + maxLon) / 2)
        var span = Math.max(maxLat - minLat, maxLon - minLon)
        mapObject.zoomLevel = span < 0.01 ? 15 : span < 0.03 ? 13.8 : span < 0.08 ? 12.5 : 11.3
        mapObject.bearing = -18
        mapObject.tilt = 0
        mode = "overview"
    }

    function updateTargetCoordinate() {
        if (mode !== "follow" || !routeActive || !vehicleMarker || !vehicleMarker.visible)
            return

        var aheadCoordinate = coordinateAhead(cameraLeadDistanceMeters)
        cameraTargetCoordinate = QtPositioning.coordinate(
            vehicleMarker.coordinate.latitude + (aheadCoordinate.latitude - vehicleMarker.coordinate.latitude) * 0.46,
            vehicleMarker.coordinate.longitude + (aheadCoordinate.longitude - vehicleMarker.coordinate.longitude) * 0.46
        )
    }

    function tickRig() {
        if (mode !== "follow" || !routeActive || !vehicleMarker || !vehicleMarker.visible || !mapObject)
            return

        updateTargetCoordinate()
        cameraRigLat += (cameraTargetCoordinate.latitude - cameraRigLat) * cameraFollowEase
        cameraRigLng += (cameraTargetCoordinate.longitude - cameraRigLng) * cameraFollowEase
        smoothedMapBearing = smoothBearing(smoothedMapBearing, currentBearing(), cameraBearingEase)

        mapObject.center = QtPositioning.coordinate(cameraRigLat, cameraRigLng)
        mapObject.bearing = smoothedMapBearing
    }

    function updateFollowTarget(coordinate) {
        if (mode !== "follow" || !routeActive)
            return

        cameraTargetCoordinate = coordinate
    }

    function stopRig() {
        cameraRigTimer.stop()
    }

    Timer {
        id: cameraRigTimer
        interval: 33
        repeat: true
        running: false
        onTriggered: root.tickRig()
    }

    Timer {
        id: viewportInteractionRelease
        interval: 850
        repeat: false
        onTriggered: {
            root.viewportInteracting = false
            if (!root.navigationActive || !root.routeActive)
                root.setMode("free")
        }
    }

    Timer {
        id: wheelZoomCommit
        interval: 33
        repeat: false
        onTriggered: {
            if (!root.mapObject)
                return

            var previousAnchorCoordinate = root.wheelZoomAnchorCoordinate
            root.mapObject.zoomLevel = root.pendingZoomLevel
            if (previousAnchorCoordinate && previousAnchorCoordinate.isValid) {
                var newAnchorCoordinate = root.mapObject.toCoordinate(root.wheelZoomAnchorPoint, false)
                if (newAnchorCoordinate && newAnchorCoordinate.isValid) {
                    root.mapObject.center = QtPositioning.coordinate(
                        root.mapObject.center.latitude + previousAnchorCoordinate.latitude - newAnchorCoordinate.latitude,
                        root.mapObject.center.longitude + previousAnchorCoordinate.longitude - newAnchorCoordinate.longitude
                    )
                }
            }
            viewportInteractionRelease.restart()
            if (Math.abs(root.mapObject.zoomLevel - root.pendingZoomLevel) > 0.01)
                wheelZoomCommit.start()
        }
    }
}
