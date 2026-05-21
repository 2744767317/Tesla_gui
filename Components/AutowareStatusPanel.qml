import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

Rectangle {
    id: panel

    property var autowareBridge: null
    property var adController: null

    radius: 16
    clip: true
    color: Style.isDark ? "#E311151A" : "#F7FAFC"
    border.width: 1
    border.color: Style.isDark ? "#26303A" : "#D8E0E8"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Rectangle {
                width: 26
                height: 26
                radius: 11
                color: autowareBridge && autowareBridge.connected ? "#153E34" : "#252B32"
                border.width: 1
                border.color: autowareBridge && autowareBridge.connected ? "#49D3A8" : "#39434D"

                Image {
                    anchors.centerIn: parent
                    width: 15
                    height: 15
                    source: "qrc:/icons/app_icons/model-3.svg"
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.9
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: "HMI adapter"
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.bold: Font.Bold
                    font.pixelSize: 12
                    color: Style.isDark ? Style.white : Style.black10
                }

                Text {
                    Layout.fillWidth: true
                    text: autowareBridge && autowareBridge.connected
                        ? autowareBridge.operationMode + " · " + Math.round(autowareBridge.vehicleSpeed) + " km/h"
                        : "Offline · reserved for Autoware"
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.pixelSize: 9
                    color: Style.black20
                }
            }

            Rectangle {
                radius: 999
                color: autowareBridge && autowareBridge.connected ? "#153E34" : "#2C2226"
                border.width: 1
                border.color: autowareBridge && autowareBridge.connected ? "#49D3A8" : "#6A3C45"
                implicitWidth: bridgeText.implicitWidth + 16
                implicitHeight: 24

                Text {
                    id: bridgeText
                    anchors.centerIn: parent
                    text: autowareBridge && autowareBridge.connected ? "Online" : "Off"
                    font.family: Style.fontFamily
                    font.bold: Font.DemiBold
                    font.pixelSize: 9
                    color: autowareBridge && autowareBridge.connected ? "#9FF4D3" : "#FFB0B8"
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 13
            color: Style.isDark ? "#A90F141A" : "#DDF7F9FC"
            border.width: 1
            border.color: Style.isDark ? "#26303A" : "#DCE3EB"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: autowareBridge
                        ? "Goal " + autowareBridge.goalState + " · " + autowareBridge.emergencyState
                        : (adController && adController.adEnabled ? "AD enabled" : "AD standby")
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.bold: Font.DemiBold
                    font.pixelSize: 10
                    color: adController && adController.adEnabled ? "#9FF4D3" : Style.black20
                }

                Text {
                    text: adController ? adController.operationMode : "manual"
                    font.family: Style.fontFamily
                    font.pixelSize: 10
                    color: Style.black20
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            DesktopButton {
                Layout.fillWidth: true
                text: autowareBridge && autowareBridge.connected ? "Disconnect" : "Connect"
                tone: autowareBridge && autowareBridge.connected ? "danger" : "ghost"
                compact: true
                implicitHeight: 26
                onClicked: {
                    if (!autowareBridge)
                        return
                    autowareBridge.connected ? autowareBridge.disconnectFromAutoware() : autowareBridge.connectToAutoware()
                }
            }

            DesktopButton {
                Layout.fillWidth: true
                text: "E-Stop"
                tone: "danger"
                compact: true
                implicitHeight: 26
                onClicked: if (autowareBridge) autowareBridge.sendEmergencyStop()
            }
        }
    }
}
