import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

Item {
    id: root
    implicitWidth: parent ? parent.width : 1280
    implicitHeight: 142
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
        color: Style.isDark ? Style.alphaColor(Style.black, 0.82) : Style.alphaColor(Style.white, 0.9)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        spacing: 22

        VehicleQuickControls {
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 1
            Layout.preferredHeight: 86
            color: Style.isDark ? "#303030" : "#D8D8D8"
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 310
            spacing: 8

            RowLayout {
                spacing: 8
                Text {
                    text: mediaCtrl && mediaCtrl.isPlaying ? "Playing now" : "Media paused"
                    font.family: Style.fontFamily
                    font.pixelSize: 12
                    color: mediaCtrl && mediaCtrl.isPlaying ? "#2BEA72" : Style.black20
                }
                Text {
                    Layout.fillWidth: true
                    text: mediaCtrl ? mediaCtrl.trackTitle : "No Track"
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.bold: Font.Bold
                    font.pixelSize: 17
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
            }

            RowLayout {
                spacing: 8
                Button { text: "<"; implicitWidth: 42; implicitHeight: 30; onClicked: if (mediaCtrl) mediaCtrl.prevTrack() }
                Button { text: mediaCtrl && mediaCtrl.isPlaying ? "Pause" : "Play"; implicitWidth: 70; implicitHeight: 30; onClicked: if (mediaCtrl) mediaCtrl.playPause() }
                Button { text: ">"; implicitWidth: 42; implicitHeight: 30; onClicked: if (mediaCtrl) mediaCtrl.nextTrack() }
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
            Layout.preferredHeight: 86
            color: Style.isDark ? "#303030" : "#D8D8D8"
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: 8

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
                    font.pixelSize: 17
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
            }

            RowLayout {
                spacing: 8
                Button {
                    text: navCtrl && navCtrl.isNavigating ? "结束导航" : "开始导航"
                    implicitWidth: 104
                    implicitHeight: 30
                    enabled: vehicleCtrl && vehicleCtrl.isDriving
                    onClicked: {
                        if (!navCtrl)
                            return
                        if (navCtrl.isNavigating)
                            navCtrl.stopRoute()
                        else if (vehicleCtrl && vehicleCtrl.isDriving)
                            navCtrl.startRoute()
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
            Layout.preferredHeight: 86
            color: Style.isDark ? "#303030" : "#D8D8D8"
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 190
            spacing: 8

            Text {
                text: btCtrl && btCtrl.isConnected ? btCtrl.deviceName : "Bluetooth"
                elide: Text.ElideRight
                font.family: Style.fontFamily
                font.bold: Font.Bold
                font.pixelSize: 15
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
                Button {
                    text: btCtrl && btCtrl.isConnected ? "Disconnect" : "Connect"
                    implicitWidth: 96
                    implicitHeight: 30
                    onClicked: {
                        if (!btCtrl)
                            return
                        btCtrl.isConnected ? btCtrl.disconnectDevice() : btCtrl.connectDevice("iPhone 15 Pro")
                    }
                }
                Button {
                    visible: btCtrl && (btCtrl.hasIncoming || btCtrl.isInCall)
                    text: btCtrl && btCtrl.hasIncoming ? "Answer" : "End"
                    implicitWidth: 76
                    implicitHeight: 30
                    onClicked: btCtrl.hasIncoming ? btCtrl.answerCall() : btCtrl.endCall()
                }
            }
        }
    }
}
