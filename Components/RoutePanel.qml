import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

Rectangle {
    id: root

    property var navCtrl: null
    property var searchState: null
    property var searchResults: []
    property var favoritePlace: null
    property var routeOptions: []
    property int activeRouteIndex: 0
    property string routeStatus: "idle"
    property string routeHint: ""
    property string searchHint: ""
    property bool routeRequestInFlight: false
    property bool compactMode: true
    property real panelScale: 1.0
    property string routePreference: "fastest"
    property string cameraMode: "overview"
    property bool useDevicePosition: false
    property string destinationLabel: ""
    property alias searchText: searchPanel.searchText
    property bool showSearchResults: false

    signal searchRequested(string query, bool committed)
    signal placeSelected(var place)
    signal homeRequested()
    signal workRequested()
    signal favoriteRequested()
    signal routePreferenceSelected(string preference)
    signal routeOptionSelected(int index)
    signal navigationToggled()
    signal recalculateRequested()
    signal cameraModeToggleRequested()
    signal gpsToggleRequested()
    signal demoRequested()
    signal hideRequested()
    signal compactModeToggled(bool compact)

    radius: 18
    color: Style.isDark ? "#D90E1217" : "#F7FAFC"
    border.width: 1
    border.color: Style.isDark ? "#26323C" : "#D8E0E8"
    clip: true

    width: Math.min(root.compactMode ? 244 : 312, parent ? parent.width * 0.28 : 312) * root.panelScale
    height: Math.min(root.compactMode && root.showSearchResults ? 386 : (root.compactMode ? 260 : 398),
                     parent ? parent.height - 180 : 398) * root.panelScale

    Behavior on width {
        NumberAnimation { duration: 160; easing.type: Easing.InOutQuad }
    }

    Behavior on height {
        NumberAnimation { duration: 160; easing.type: Easing.InOutQuad }
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: root.compactMode ? 6 : 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: "Navigation"
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.bold: Font.Bold
                    font.pixelSize: 12
                    color: Style.isDark ? Style.white : Style.black10
                }

                Text {
                    Layout.fillWidth: true
                    text: root.searchHint.length ? root.searchHint : (root.routeRequestInFlight ? "规划中" : root.routeHint)
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.pixelSize: 9
                    color: Style.black20
                }
            }

            DesktopButton {
                text: root.compactMode ? "More" : "Less"
                compact: true
                tone: "ghost"
                implicitWidth: 44
                implicitHeight: 26
                onClicked: root.compactModeToggled(!root.compactMode)
            }

            DesktopButton {
                text: "Hide"
                compact: true
                tone: "ghost"
                implicitWidth: 42
                implicitHeight: 26
                onClicked: root.hideRequested()
            }
        }

        SearchPanel {
            id: searchPanel
            Layout.fillWidth: true
            searchState: root.searchState
            searchResults: root.searchResults
            compactMode: root.compactMode
            showSearchResults: root.showSearchResults
            destinationLabel: root.destinationLabel
            favoritePlace: root.favoritePlace

            onSearchRequested: function(query, committed) { root.searchRequested(query, committed) }
            onPlaceSelected: function(place) { root.placeSelected(place) }
            onHomeRequested: function() { root.homeRequested() }
            onWorkRequested: function() { root.workRequested() }
            onFavoriteRequested: function() { root.favoriteRequested() }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: !root.compactMode
            spacing: 6

            DesktopButton {
                text: "最快"
                checkable: true
                checked: root.routePreference === "fastest"
                implicitHeight: 28
                Layout.fillWidth: true
                compact: true
                onClicked: root.routePreferenceSelected("fastest")
            }

            DesktopButton {
                text: "最短"
                checkable: true
                checked: root.routePreference === "shortest"
                implicitHeight: 28
                Layout.fillWidth: true
                compact: true
                onClicked: root.routePreferenceSelected("shortest")
            }

            DesktopButton {
                text: "均衡"
                checkable: true
                checked: root.routePreference === "balanced"
                implicitHeight: 28
                Layout.fillWidth: true
                compact: true
                onClicked: root.routePreferenceSelected("balanced")
            }
        }

        ListView {
            id: routeList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(root.compactMode ? 38 : 126, root.routeOptions.length * 38)
            visible: !root.showSearchResults && root.routeOptions.length > 0 && (!root.compactMode || root.routeStatus !== "idle")
            clip: true
            model: root.routeOptions
            spacing: 6

            delegate: Rectangle {
                width: ListView.view.width
                height: 32
                radius: 8
                color: index === root.activeRouteIndex
                    ? "#2D7F75"
                    : (Style.isDark ? "#20252B" : "#F4F5F7")
                border.width: 1
                border.color: index === root.activeRouteIndex ? "#11E3F3" : (Style.isDark ? "#2E3740" : "#E0E5EB")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    spacing: 7

                    Text {
                        Layout.fillWidth: true
                        text: modelData.title
                        elide: Text.ElideRight
                        font.family: Style.fontFamily
                        font.bold: Font.Bold
                        font.pixelSize: 10
                        color: Style.white
                    }

                    Text {
                        visible: !root.compactMode || index === root.activeRouteIndex
                        text: root.formatMiles(modelData.distanceMiles) + "  " + root.formatMinutes(modelData.durationMinutes)
                        font.family: Style.fontFamily
                        font.pixelSize: 9
                        color: index === root.activeRouteIndex ? "#D8F6FF" : Style.black20
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.routeOptionSelected(index)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: !root.compactMode
            Layout.preferredHeight: 1
            color: Style.isDark ? "#303030" : "#D8D8D8"
        }

        Text {
            Layout.fillWidth: true
            text: root.navCtrl ? root.navCtrl.destination : root.destinationLabel
            elide: Text.ElideRight
            maximumLineCount: 1
            wrapMode: Text.Wrap
            font.family: Style.fontFamily
            font.bold: Font.Bold
            font.pixelSize: 11
            color: Style.isDark ? Style.white : Style.black10
        }

        Text {
            Layout.fillWidth: true
            text: root.navCtrl ? root.navCtrl.nextManeuver : "路线尚未准备"
            elide: Text.ElideRight
            maximumLineCount: 1
            wrapMode: Text.Wrap
            font.family: Style.fontFamily
            font.pixelSize: 10
            color: "#11E3F3"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.navCtrl ? root.formatMiles(root.navCtrl.distanceToNext) + " 后" : ""
                font.family: Style.fontFamily
                font.pixelSize: 9
                color: Style.black20
            }

            Text {
                text: root.navCtrl ? root.navCtrl.etaMinutes + " 分钟到达" : ""
                font.family: Style.fontFamily
                font.pixelSize: 9
                color: Style.black20
            }
        }

        DesktopButton {
            text: root.navCtrl && root.navCtrl.isNavigating ? "结束导航" : "开始导航"
            Layout.fillWidth: true
            implicitHeight: 32
            tone: root.navCtrl && root.navCtrl.isNavigating ? "danger" : "accent"
            enabled: root.routeOptions.length > 0 || !root.routeRequestInFlight
            onClicked: root.navigationToggled()
        }

        ProgressBar {
            Layout.fillWidth: true
            visible: !root.compactMode || (root.navCtrl && root.navCtrl.routeProgress > 0)
            from: 0
            to: 1
            value: root.navCtrl ? root.navCtrl.routeProgress : 0
            background: Rectangle {
                implicitHeight: 5
                radius: 999
                color: Style.isDark ? "#2E363F" : "#DDE4EC"
            }
            contentItem: Item {
                implicitHeight: 5
                Rectangle {
                    width: parent.width * (root.navCtrl ? root.navCtrl.routeProgress : 0)
                    height: parent.height
                    radius: 999
                    color: "#11E3F3"
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: !root.compactMode
            spacing: 8

            DesktopButton {
                text: "重算"
                Layout.fillWidth: true
                implicitHeight: 34
                compact: true
                onClicked: root.recalculateRequested()
            }

            DesktopButton {
                text: root.cameraMode === "follow" ? "总览" : "跟随"
                Layout.fillWidth: true
                implicitHeight: 34
                compact: true
                onClicked: root.cameraModeToggleRequested()
            }

            DesktopButton {
                text: root.useDevicePosition ? "GPS 已开" : "GPS"
                Layout.fillWidth: true
                implicitHeight: 34
                compact: true
                onClicked: root.gpsToggleRequested()
            }

            DesktopButton {
                text: "北京"
                Layout.fillWidth: true
                implicitHeight: 34
                compact: true
                onClicked: root.demoRequested()
            }
        }
    }
}
