import QtQuick 2.9
import QtPositioning

QtObject {
    property int routePlaybackStep: 1
    property int routeCursorIndex: 0
    property int routeSegmentIndex: 0
    property real routeProgressDistanceMeters: 0
    property real smoothedMapBearing: -28
    property real cameraRigLat: 0
    property real cameraRigLng: 0
    property real cameraLeadDistanceMeters: 130
    property real cameraFollowEase: 0.085
    property real cameraBearingEase: 0.075
    property var cameraTargetCoordinate: QtPositioning.coordinate(0, 0)
    property real followZoomLevel: 16
    property real followTiltLevel: 0
    property real inspectTiltLevel: 0
    property real freeMinZoomLevel: 2
    property real freeMaxZoomLevel: 21
    property real pendingZoomLevel: 12.8
    property point wheelZoomAnchorPoint: Qt.point(0, 0)
    property var wheelZoomAnchorCoordinate: QtPositioning.coordinate(0, 0)
    property bool mapViewportInteracting: false
    property int visualPlaybackTick: 0

    function playbackMetersPerTick(vehicleSpeedKmh, vehicleIsDriving, intervalMs, routeTotalDistanceMeters) {
        var kmh = vehicleIsDriving ? Math.max(vehicleSpeedKmh, 28) : 45
        var realMetersPerSecond = kmh / 3.6
        var demoAcceleration = routeTotalDistanceMeters > 80000 ? 18 : routeTotalDistanceMeters > 25000 ? 12 : 7
        return realMetersPerSecond * demoAcceleration * (intervalMs / 1000.0)
    }
}
