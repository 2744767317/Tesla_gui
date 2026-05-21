import QtQuick 2.9

Item {
    id: root
    visible: false
    width: 0
    height: 0

    property var pageMap: null
    readonly property int playbackIntervalMs: simulateDrive.interval

    function stopAll() {
        previewActivationTimer.stop()
        simulateDrive.stop()
        fallbackRouteTimer.stop()
        routeStartAnimation.stop()
    }

    function stopDrivePlayback() {
        simulateDrive.stop()
        routeStartAnimation.stop()
    }

    function scheduleRoutePreview() {
        previewActivationTimer.restart()
    }

    function cancelFallbackRoute() {
        fallbackRouteTimer.stop()
    }

    function scheduleFallbackRoute() {
        fallbackRouteTimer.restart()
    }

    function beginDrivePlayback() {
        if (!pageMap || !pageMap.drivePath.length)
            return

        simulateDrive.path = pageMap.drivePath
        simulateDrive.index = Math.min(pageMap.routeCursorIndex, Math.max(0, pageMap.drivePath.length - 1))
        pageMap.routeProgressDistanceMeters = Math.min(pageMap.routeProgressDistanceMeters, pageMap.routeTotalDistanceMeters)
        if (!simulateDrive.running)
            simulateDrive.start()

        routeStartAnimation.stop()
        routeStartAnimation.start()
    }

    function syncDrivePlayback() {
        if (!pageMap || !pageMap.drivePath.length || !pageMap.currentLocationMarker || !pageMap.currentLocationMarker.visible)
            return

        if (!pageMap.navigationController || !pageMap.navigationController.isNavigating) {
            simulateDrive.stop()
            return
        }

        pageMap.updatePlaybackPace()
        simulateDrive.path = pageMap.drivePath
        pageMap.isRoutingStart = true
        pageMap.routeProgressDistanceMeters = Math.max(0, Math.min(pageMap.routeProgressDistanceMeters, pageMap.routeTotalDistanceMeters))
        if (!simulateDrive.running) {
            simulateDrive.index = Math.min(pageMap.routeCursorIndex, Math.max(0, pageMap.drivePath.length - 1))
            simulateDrive.start()
        }
    }

    Timer {
        id: previewActivationTimer

        interval: 800
        onTriggered: {
            if (!pageMap || !pageMap.routePath.length)
                return

            pageMap.startMarker.visible = false
            pageMap.currentLocationMarker.visible = true
            pageMap.isRoutingStart = true

            if (pageMap.navigationController && pageMap.navigationController.isNavigating) {
                routeStartAnimation.stop()
                routeStartAnimation.start()
            }

            root.syncDrivePlayback()
        }
    }

    Timer {
        id: simulateDrive

        property var path
        property int index

        interval: 60
        repeat: true
        onTriggered: {
            if (!pageMap || !pageMap.navigationController || !pageMap.navigationController.isNavigating) {
                simulateDrive.stop()
                return
            }

            if (!path || path.length < 2 || pageMap.routeTotalDistanceMeters <= 0) {
                simulateDrive.stop()
                return
            }

            pageMap.routeProgressDistanceMeters = Math.min(
                pageMap.routeTotalDistanceMeters,
                pageMap.routeProgressDistanceMeters + pageMap.playbackMetersPerTick()
            )

            pageMap.navigationController.updateRouteProgress(pageMap.routeProgressDistanceMeters / pageMap.routeTotalDistanceMeters)

            if (pageMap.routeProgressDistanceMeters >= pageMap.routeTotalDistanceMeters - 0.01) {
                simulateDrive.stop()
                pageMap.isRoutingStart = false
                pageMap.navigationController.markArrived()
                return
            }

            pageMap.visualPlaybackTick += 1
            if (pageMap.mapViewportInteracting && pageMap.visualPlaybackTick % 3 !== 0)
                return

            var interpolatedCoordinate = pageMap.coordinateAtRouteDistance(pageMap.routeProgressDistanceMeters)
            pageMap.updateLiveCoordinate(interpolatedCoordinate, "Route")
        }
    }

    Timer {
        id: fallbackRouteTimer
        interval: 3500
        repeat: false
        onTriggered: {
            if (!pageMap || pageMap.routePath.length)
                return

            // 公网服务超时后切到本地演示路线，保证页面交互不断档。
            pageMap.routeRequestInFlight = false
            pageMap.routeStatus = "fallback"
            pageMap.routeHint = "使用本地演示路线"

            var fallbackPath = pageMap.buildDemoRoute()
            pageMap.routePath = fallbackPath
            var fallbackOption = {
                index: 0,
                title: "离线预览",
                path: fallbackPath,
                steps: pageMap.buildFallbackRouteSteps(),
                distanceMiles: pageMap.routeDistanceMiles(),
                durationMinutes: 10,
                score: 0
            }
            pageMap.routeOptions = [fallbackOption]
            pageMap.activeRouteIndex = 0
            pageMap.applyRouteOption(fallbackOption, "fallback")
        }
    }

    ParallelAnimation {
        id: routeStartAnimation

        NumberAnimation {
            target: root.pageMap ? root.pageMap.mapObject : null
            property: "zoomLevel"
            duration: 1200
            from: root.pageMap && root.pageMap.mapObject ? root.pageMap.mapObject.zoomLevel : 0
            to: root.pageMap ? root.pageMap.followZoomLevel : 16
        }

        NumberAnimation {
            target: root.pageMap ? root.pageMap.mapObject : null
            property: "tilt"
            duration: 1200
            from: root.pageMap && root.pageMap.mapObject ? root.pageMap.mapObject.tilt : 0
            to: root.pageMap ? root.pageMap.followTiltLevel : 0
        }
    }
}
