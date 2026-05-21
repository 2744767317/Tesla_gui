import QtQuick 2.9
import QtLocation 6.10
import QtPositioning
import Style 1.0

Map {
    id: root

    property var tileSourceState: null
    property var tileSettingsObject: null
    property var mapDataServiceObject: null
    property var adaptive: null
    property var currentLoc: QtPositioning.coordinate(0, 0)
    property var routeOptions: []
    property int activeRouteIndex: 0
    property var routeRenderPath: []
    property var routeInteractionPath: []
    property bool mapViewportInteracting: false
    property int markerAnimationDuration: 78
    property alias currentLocationMarkerItem: currentLocationMarker
    property alias destinationMarkerItem: destinationMarker
    property alias startMarkerItem: startMarker

    signal viewportInteractionBegan()
    signal viewportInteractionEnded()
    signal wheelZoomRequested(point screenPoint, real zoomDelta)
    signal startCoordinateRequested(var coordinate)
    signal destinationCoordinateRequested(var coordinate, string label)
    signal followTargetCoordinateChanged(var coordinate)

    function adaptiveWidth(value) {
        return adaptive && adaptive.width ? adaptive.width(value) : value
    }

    function adaptiveAverage(value) {
        return adaptive && adaptive.average ? adaptive.average(value) : value
    }

    function selectCustomMapType() {
        if (!supportedMapTypes.length)
            return

        activeMapType = supportedMapTypes[supportedMapTypes.length - 1]
    }

    anchors.fill: parent
    color: tileSourceState ? tileSourceState.mapBackgroundColor() : "black"
    copyrightsVisible: false
    center: currentLoc
    zoomLevel: 12.8
    bearing: -28
    tilt: 0

    onSupportedMapTypesChanged: selectCustomMapType()

    Component.onCompleted: {
        selectCustomMapType()
        currentLocationMarker.visible = true
    }

    plugin: Plugin {
        name: "osm"

        PluginParameter {
            name: "osm.mapping.custom.host"
            value: root.tileSourceState ? root.tileSourceState.activeTileHost() : ""
        }
        PluginParameter {
            name: "osm.mapping.providersrepository.disabled"
            value: true
        }
        PluginParameter {
            name: "osm.mapping.cache.directory"
            value: root.tileSettingsObject ? root.tileSettingsObject.cacheDirectory : ""
        }
        PluginParameter {
            name: "osm.mapping.cache.disk.size"
            value: root.tileSettingsObject ? root.tileSettingsObject.diskCacheSizeBytes : 1610612736
        }
        PluginParameter {
            name: "osm.mapping.cache.memory.size"
            value: root.tileSettingsObject ? root.tileSettingsObject.memoryCacheSizeBytes : 201326592
        }
        PluginParameter {
            name: "osm.mapping.cache.texture.size"
            value: root.tileSettingsObject ? root.tileSettingsObject.textureCacheSizeBytes : 402653184
        }
        PluginParameter {
            name: "osm.useragent"
            value: "TeslaDashboardUI/1.0"
        }
        PluginParameter {
            name: "osm.geocoding.host"
            value: root.mapDataServiceObject ? root.mapDataServiceObject.geocodeHost : "https://nominatim.openstreetmap.org"
        }
    }

    MapPolyline {
        visible: !root.mapViewportInteracting && root.routeOptions.length > 1 && root.activeRouteIndex !== 1
        line.color: "#607A8791"
        line.width: root.adaptiveWidth(7)
        path: root.routeOptions.length > 1 ? root.routeOptions[1].path : []
    }

    MapPolyline {
        visible: !root.mapViewportInteracting && root.routeOptions.length > 2 && root.activeRouteIndex !== 2
        line.color: "#50616B72"
        line.width: root.adaptiveWidth(6)
        path: root.routeOptions.length > 2 ? root.routeOptions[2].path : []
    }

    MapPolyline {
        visible: !root.mapViewportInteracting
        line.color: "#4033E4FF"
        line.width: root.adaptiveWidth(13)
        path: root.routeRenderPath
    }

    MapPolyline {
        line.color: "#11E3F3"
        line.width: root.mapViewportInteracting ? root.adaptiveWidth(3) : root.adaptiveWidth(5)
        path: root.mapViewportInteracting ? root.routeInteractionPath : root.routeRenderPath
    }

    MapQuickItem {
        id: currentLocationMarker

        coordinate: root.currentLoc
        visible: false
        z: 3
        anchorPoint.x: sourceItem.width / 2
        anchorPoint.y: sourceItem.height / 2

        onCoordinateChanged: root.followTargetCoordinateChanged(coordinate)

        sourceItem: Item {
            width: root.mapViewportInteracting ? root.adaptiveAverage(38) : root.adaptiveAverage(58)
            height: width

            Rectangle {
                anchors.centerIn: parent
                visible: !root.mapViewportInteracting
                width: parent.width
                height: parent.height
                radius: width / 2
                color: "#22F2187A"
            }

            Rectangle {
                anchors.centerIn: parent
                visible: !root.mapViewportInteracting
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
                duration: root.markerAnimationDuration
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
            width: root.adaptiveAverage(20)
            height: root.adaptiveAverage(20)

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
            width: root.adaptiveAverage(14)
            height: root.adaptiveAverage(14)

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

        property bool mapDragActive: false
        property point mapDragLastPoint: Qt.point(0, 0)

        onPressed: function(mouse) {
            root.viewportInteractionBegan()
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

            var before = root.toCoordinate(mapDragLastPoint, false)
            var after = root.toCoordinate(currentPoint, false)
            if (before.isValid && after.isValid) {
                root.center = QtPositioning.coordinate(
                    root.center.latitude + before.latitude - after.latitude,
                    root.center.longitude + before.longitude - after.longitude
                )
                mapDragActive = true
                mapDragLastPoint = currentPoint
            }
        }

        onReleased: root.viewportInteractionEnded()
        onCanceled: root.viewportInteractionEnded()

        onWheel: function(wheel) {
            var steps = wheel.angleDelta.y / 120
            if (steps === 0)
                steps = wheel.pixelDelta.y > 0 ? 1 : -1
            root.wheelZoomRequested(Qt.point(wheel.x, wheel.y), steps * 0.45)
            wheel.accepted = true
        }

        onClicked: function(mouse) {
            if (mapDragActive)
                return

            var coordinate = root.toCoordinate(Qt.point(mouse.x, mouse.y), false)
            if (!coordinate.isValid)
                return

            if (mouse.button === Qt.RightButton)
                root.startCoordinateRequested(coordinate)
            else
                root.destinationCoordinateRequested(coordinate, "选点 " + coordinate.latitude.toFixed(4) + ", " + coordinate.longitude.toFixed(4))
        }
    }
}
