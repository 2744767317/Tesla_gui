import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

Item {
    id: root
    implicitWidth: parent ? parent.width : 1280
    implicitHeight: 118
    property bool expanded: true

    opacity: expanded ? 1 : 0

    transform: Translate {
        id: slideTransform
        y: root.expanded ? 0 : root.height + 10
        Behavior on y {
            NumberAnimation { duration: 260; easing.type: Easing.InOutQuad }
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
    }

    Rectangle {
        anchors.fill: parent
        color: Style.isDark ? "#D911151A" : "#EEF8FAFC"
        radius: 18
        border.width: 1
        border.color: Style.isDark ? "#262B31" : "#D9DEE5"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        spacing: 16

        VehicleQuickControls {
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 1
            Layout.preferredHeight: 78
            color: Style.isDark ? "#2E363F" : "#D8DEE6"
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 310
            spacing: 7

            RowLayout {
                spacing: 8
                Text {
                    text: mediaCtrl && mediaCtrl.isPlaying ? "Playing now" : "Media paused"
                    font.family: Style.fontFamily
                    font.pixelSize: 12
                    color: mediaCtrl && mediaCtrl.isPlaying ? "#49D3A8" : Style.black20
                }
                Text {
                    Layout.fillWidth: true
                    text: mediaCtrl ? mediaCtrl.trackTitle : "No Track"
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.bold: Font.Bold
                    font.pixelSize: 16
                    color: Style.isDark ? Style.white : Style.black10
                }
            }

            Text {
                Layout.fillWidth: true
                text: mediaCtrl ? mediaCtrl.artistName : ""
                elide: Text.ElideRight
                font.family: Style.fontFamily
                font.pixelSize: 12
                color: Style.black20
            }

            ProgressBar {
                Layout.fillWidth: true
                from: 0
                to: 1
                value: mediaCtrl ? mediaCtrl.trackProgress : 0
                background: Rectangle {
                    implicitHeight: 5
                    radius: 999
                    color: Style.isDark ? "#2E363F" : "#DDE4EC"
                }
                contentItem: Item {
                    implicitHeight: 5
                    Rectangle {
                        width: parent.width * (mediaCtrl ? mediaCtrl.trackProgress : 0)
                        height: parent.height
                        radius: 999
                        color: "#49D3A8"
                    }
                }
            }

            RowLayout {
                spacing: 8
                DesktopButton { text: "<"; compact: true; implicitWidth: 40; implicitHeight: 30; onClicked: if (mediaCtrl) mediaCtrl.prevTrack() }
                DesktopButton { text: mediaCtrl && mediaCtrl.isPlaying ? "Pause" : "Play"; tone: "ghost"; compact: true; implicitWidth: 68; implicitHeight: 30; onClicked: if (mediaCtrl) mediaCtrl.playPause() }
                DesktopButton { text: ">"; compact: true; implicitWidth: 40; implicitHeight: 30; onClicked: if (mediaCtrl) mediaCtrl.nextTrack() }
                Text {
                    Layout.leftMargin: 10
                    text: mediaCtrl ? "Vol " + mediaCtrl.volume : ""
                    font.family: Style.fontFamily
                    font.pixelSize: 12
                    color: Style.black20
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 1
            Layout.preferredHeight: 78
            color: Style.isDark ? "#2E363F" : "#D8DEE6"
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: 7

            RowLayout {
                spacing: 10
                Text {
                    text: navCtrl && navCtrl.isNavigating ? "导航中" : "导航"
                    font.family: Style.fontFamily
                    font.pixelSize: 12
                    color: Style.black20
                }
                Text {
                    Layout.fillWidth: true
                    text: navCtrl ? navCtrl.destination : "市中心广场"
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.bold: Font.Bold
                    font.pixelSize: 16
                    color: Style.isDark ? Style.white : Style.black10
                }
            }

            Text {
                Layout.fillWidth: true
                text: !vehicleCtrl || !vehicleCtrl.isDriving
                    ? "已停车 · 路线预览"
                    : navCtrl ? navCtrl.nextManeuver + "  ·  " + navCtrl.etaMinutes + " 分钟" : ""
                elide: Text.ElideRight
                font.family: Style.fontFamily
                font.pixelSize: 12
                color: Style.black20
            }

            ProgressBar {
                Layout.fillWidth: true
                from: 0
                to: 1
                value: navCtrl ? navCtrl.routeProgress : 0
                background: Rectangle {
                    implicitHeight: 5
                    radius: 999
                    color: Style.isDark ? "#2E363F" : "#DDE4EC"
                }
                contentItem: Item {
                    implicitHeight: 5
                    Rectangle {
                        width: parent.width * (navCtrl ? navCtrl.routeProgress : 0)
                        height: parent.height
                        radius: 999
                        color: "#11E3F3"
                    }
                }
            }

            RowLayout {
                spacing: 8
                DesktopButton {
                    text: navCtrl && navCtrl.isNavigating ? "结束导航" : "开始导航"
                    implicitWidth: 104
                    implicitHeight: 30
                    tone: navCtrl && navCtrl.isNavigating ? "danger" : "accent"
                    compact: true
                    enabled: !!navCtrl
                    onClicked: {
                        if (!navCtrl)
                            return
                        if (navCtrl.isNavigating)
                            navCtrl.stopRoute()
                        else {
                            navCtrl.startRoute()
                        }
                    }
                }
                Text {
                    text: navCtrl ? navCtrl.currentStreet : ""
                    font.family: Style.fontFamily
                    font.pixelSize: 12
                    color: Style.black20
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 1
            Layout.preferredHeight: 78
            color: Style.isDark ? "#2E363F" : "#D8DEE6"
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 190
            spacing: 7

            Text {
                text: btCtrl && btCtrl.isConnected ? btCtrl.deviceName : "Bluetooth"
                elide: Text.ElideRight
                font.family: Style.fontFamily
                font.bold: Font.Bold
                font.pixelSize: 14
                color: Style.isDark ? Style.white : Style.black10
            }

            Text {
                text: btCtrl && btCtrl.hasIncoming ? "Incoming: " + btCtrl.callerName
                    : btCtrl && btCtrl.isInCall ? "In call: " + btCtrl.callDuration
                    : btCtrl && btCtrl.isConnected ? "Signal " + btCtrl.signalStrength + "%"
                    : "Not connected"
                elide: Text.ElideRight
                font.family: Style.fontFamily
                font.pixelSize: 12
                color: Style.black20
            }

            RowLayout {
                spacing: 8
                DesktopButton {
                    text: btCtrl && btCtrl.isConnected ? "Disconnect" : "Connect"
                    implicitWidth: 96
                    implicitHeight: 30
                    tone: btCtrl && btCtrl.isConnected ? "danger" : "ghost"
                    compact: true
                    onClicked: {
                        if (!btCtrl)
                            return
                        btCtrl.isConnected ? btCtrl.disconnectDevice() : btCtrl.connectDevice("iPhone 15 Pro")
                    }
                }
                DesktopButton {
                    visible: btCtrl && (btCtrl.hasIncoming || btCtrl.isInCall)
                    text: btCtrl && btCtrl.hasIncoming ? "Answer" : "End"
                    implicitWidth: 76
                    implicitHeight: 30
                    tone: btCtrl && btCtrl.hasIncoming ? "accent" : "danger"
                    compact: true
                    onClicked: btCtrl.hasIncoming ? btCtrl.answerCall() : btCtrl.endCall()
                }
            }
        }
    }
}
