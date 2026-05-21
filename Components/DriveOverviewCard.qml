import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

Rectangle {
    id: card

    signal hmiRequested()

    property bool hmiPanelActive: false
    property string driveState: vehicleCtrl && vehicleCtrl.isDriving ? "Drive" : "Park"
    property string routeTitle: navCtrl && navCtrl.destination.length ? navCtrl.destination : "No destination"
    property string routeSubtitle: navCtrl && navCtrl.isNavigating
        ? navCtrl.etaMinutes + " min · " + navCtrl.nextManeuver
        : "2D preview ready"

    implicitWidth: 206
    implicitHeight: 202
    radius: 18
    clip: true
    color: Style.isDark ? "#D80E1217" : "#F7F9FC"
    border.width: 1
    border.color: Style.isDark ? "#222B34" : "#D8DEE8"

    function warningCount() {
        // 左侧卡片只显示聚合告警数量，不在这里展开具体来源。
        var total = 0
        if (vehicleCtrl && vehicleCtrl.warningDoor)
            total += 1
        if (vehicleCtrl && vehicleCtrl.warningSeatbelt)
            total += 1
        if (vehicleCtrl && vehicleCtrl.warningEngine)
            total += 1
        if (vehicleCtrl && vehicleCtrl.warningBattery)
            total += 1
        if (vehicleCtrl && vehicleCtrl.warningOil)
            total += 1
        return total
    }

    function mph(value) {
        return Math.round(value * 0.621371)
    }

    Rectangle {
        anchors.fill: parent
        opacity: Style.isDark ? 1.0 : 0.82
        gradient: Gradient {
            GradientStop { position: 0.0; color: Style.isDark ? "#17212A" : "#FFFFFF" }
            GradientStop { position: 1.0; color: Style.isDark ? "#0B0F14" : "#EEF3F8" }
        }
    }

    Rectangle {
        width: parent.width * 0.78
        height: width
        radius: width / 2
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -width * 0.48
        anchors.topMargin: -width * 0.55
        color: card.hmiPanelActive ? "#1E7F69" : "#1E5E7A"
        opacity: 0.12
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 11
        spacing: 7

        // 摘要卡遵循“车状态 > 当前目的地 > 告警/HMI入口”的视觉层级。
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: "Model 3"
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.bold: Font.Bold
                    font.pixelSize: 15
                    color: Style.isDark ? Style.white : Style.black10
                }

                Text {
                    Layout.fillWidth: true
                    text: "2D desktop"
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.pixelSize: 9
                    color: Style.black20
                }
            }

            Rectangle {
                radius: 999
                color: vehicleCtrl && vehicleCtrl.isDriving ? "#1D9B6C" : "#20262D"
                border.width: 1
                border.color: vehicleCtrl && vehicleCtrl.isDriving ? "#45DEAD" : "#38424D"
                implicitWidth: stateText.implicitWidth + 16
                implicitHeight: 24

                Text {
                    id: stateText
                    anchors.centerIn: parent
                    text: card.driveState
                    font.family: Style.fontFamily
                    font.bold: Font.DemiBold
                    font.pixelSize: 10
                    color: Style.white
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 44

            Image {
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.5, 86)
                height: width * 0.42
                source: "qrc:/icons/app_icons/model-3.svg"
                fillMode: Image.PreserveAspectFit
                opacity: 0.86
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: parent.width * 0.32
                height: 5
                radius: 999
                color: Style.isDark ? "#2F3944" : "#DCE4EC"
                opacity: 0.45
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 14
            color: Style.isDark ? "#86111820" : "#DDF7F9FC"
            border.width: 1
            border.color: Style.isDark ? "#242D36" : "#DCE3EB"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                MetricReadout {
                    Layout.fillWidth: true
                    label: "Speed"
                    value: vehicleCtrl ? card.mph(vehicleCtrl.speed) : 0
                    unit: "mph"
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: 10
                    color: Style.isDark ? "#2B343D" : "#DCE3EB"
                }

                MetricReadout {
                    Layout.fillWidth: true
                    label: "Charge"
                    value: vehicleCtrl ? Math.round(vehicleCtrl.fuel) : 0
                    unit: "%"
                    accent: vehicleCtrl && vehicleCtrl.fuel < 20 ? "#FF8A65" : "#49D3A8"
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 43
            radius: 14
            color: Style.isDark ? "#70111820" : "#D8FFFFFF"
            border.width: 1
            border.color: Style.isDark ? "#242D36" : "#DCE3EB"

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 7
                anchors.bottomMargin: 7
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: card.routeTitle
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.bold: Font.DemiBold
                    font.pixelSize: 10
                    color: Style.isDark ? Style.white : Style.black10
                }

                Text {
                    Layout.fillWidth: true
                    text: card.routeSubtitle
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.pixelSize: 9
                    color: Style.black20
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 27
            spacing: 7

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: card.warningCount() > 0
                    ? (Style.isDark ? "#33251F" : "#FFF0E8")
                    : (Style.isDark ? "#14231D" : "#EAF8F1")
                border.width: 1
                border.color: card.warningCount() > 0 ? "#FF8A65" : "#355F4D"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    spacing: 6

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: card.warningCount() > 0 ? "#FF8A65" : "#49D3A8"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: card.warningCount() > 0 ? card.warningCount() + " alerts" : "Systems nominal"
                        elide: Text.ElideRight
                        font.family: Style.fontFamily
                        font.bold: Font.DemiBold
                        font.pixelSize: 9
                        color: Style.isDark ? Style.white : Style.black10
                    }
                }
            }

            DesktopButton {
                text: card.hmiPanelActive ? "Close" : "HMI"
                tone: card.hmiPanelActive ? "accent" : "ghost"
                compact: true
                implicitWidth: 48
                implicitHeight: 27
                onClicked: card.hmiRequested()
            }
        }
    }

    component MetricReadout: ColumnLayout {
        property string label: ""
        property string value: ""
        property string unit: ""
        property color accent: Style.isDark ? Style.white : Style.black10

        spacing: 1

        Text {
            Layout.fillWidth: true
            text: label
            elide: Text.ElideRight
            font.family: Style.fontFamily
            font.pixelSize: 8
            color: Style.black20
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                text: value
                elide: Text.ElideRight
                font.family: Style.fontFamily
                font.bold: Font.Bold
                font.pixelSize: 13
                color: accent
            }

            Text {
                Layout.fillWidth: true
                text: unit
                elide: Text.ElideRight
                font.family: Style.fontFamily
                font.pixelSize: 8
                color: Style.black20
            }
        }
    }
}
