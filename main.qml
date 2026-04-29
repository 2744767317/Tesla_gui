import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0
import "Components"
import "qrc:/LayoutManager.js" as Responsive

ApplicationWindow {
    id: root
    width: 1280
    height: 800
    maximumHeight: 1080
    minimumHeight: 600
    maximumWidth: 1920
    minimumWidth: 800
    visible: true
    title: qsTr("Tesla Model 3")
    property bool fusionPanelVisible: true

    Connections {
        target: vehicleCtrl

        function onIsDrivingChanged() {
            if (!vehicleCtrl.isDriving && navCtrl && navCtrl.isNavigating)
                navCtrl.stopRoute()
        }
    }
    onWidthChanged: {
        if(adaptive)
            adaptive.updateWindowWidth(root.width)
    }

    onHeightChanged: {
        if(adaptive)
            adaptive.updateWindowHeight(root.height)
    }
    property var adaptive: new Responsive.AdaptiveLayoutManager(root.width,root.height, root.width,root.height)

    FontLoader {
        id: uniTextFont
        source: "qrc:/Fonts/Unitext Regular.ttf"
    }

    background: Loader {
        anchors.fill: parent
        sourceComponent: Style.mapAreaVisible ? backgroundRect : backgroundImage
    }

    Header {
        z: 99
        id: headerLayout
    }

    footer: Footer{
        id: footerLayout
        onOpenLauncher: launcher.open()
    }

    TopLeftButtonIconColumn {
        z: 99
        anchors.left: parent.left
        anchors.top: headerLayout.bottom
        anchors.leftMargin: 18
    }

    RowLayout {
        id: mapLayout
        visible: Style.mapAreaVisible
        spacing: 0
        anchors.fill: parent
        Item {
            Layout.preferredWidth: 620
            Layout.fillHeight: true
            Image {
                anchors.centerIn: parent
                source: Style.isDark ? "qrc:/icons/light/sidebar.png" : "qrc:/icons/dark/sidebar-light.png"
            }
        }

        NavigationMapHelperScreen {
            Layout.fillWidth: true
            Layout.fillHeight: true
            runMenuAnimation: true
        }
    }

    LaunchPadControl {
        id: launcher
        y: (root.height - height) / 2 + (footerLayout.height)
        x: (root.width - width ) / 2
    }

    SystemFusionPanel {
        id: fusionPanel
        z: 98
        expanded: root.fusionPanelVisible
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: footerLayout.height
    }

    Button {
        id: fusionToggle
        z: 100
        width: 154
        height: 38
        text: root.fusionPanelVisible ? "Status panel  v" : "Status panel  ^"
        anchors.right: parent.right
        anchors.rightMargin: 28
        anchors.bottom: parent.bottom
        anchors.bottomMargin: footerLayout.height + (root.fusionPanelVisible ? fusionPanel.height + 10 : 12)
        onClicked: root.fusionPanelVisible = !root.fusionPanelVisible

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 260; easing.type: Easing.InOutQuad }
        }

        background: Rectangle {
            radius: 8
            color: root.fusionPanelVisible ? "#2A8C6A" : "#E67E22"
            border.width: 1
            border.color: Style.alphaColor(Style.white, 0.45)
        }

        contentItem: Text {
            text: fusionToggle.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Style.fontFamily
            font.bold: Font.Bold
            font.pixelSize: 13
            color: Style.white
        }
    }

    Component {
        id: backgroundRect
        Rectangle {
            color: "#171717"
            anchors.fill: parent
        }
    }

    Component {
        id: backgroundImage
        Image {
            source: Style.getImageBasedOnTheme()
            Icon {
                icon.source: Style.isDark ? "qrc:/icons/car_action_icons/dark/lock.svg" : "qrc:/icons/car_action_icons/lock.svg"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: - 350
                anchors.horizontalCenterOffset: 37
            }

            Icon {
                icon.source: Style.isDark ? "qrc:/icons/car_action_icons/dark/Power.svg" : "qrc:/icons/car_action_icons/Power.svg"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: - 77
                anchors.horizontalCenterOffset: 550
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: - 230
                anchors.horizontalCenterOffset: 440

                Text {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    text: "Trunk"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.bold: Font.DemiBold
                    color: Style.black20
                }
                Text {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    text: "Open"
                    font.family: "Inter"
                    font.pixelSize: 16
                    font.bold: Font.Bold
                    color: Style.isDark ? Style.white : "#171717"
                }
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: - 180
                anchors.horizontalCenterOffset: - 350

                Text {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    text: "Frunk"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.bold: Font.DemiBold
                    color: Style.black20
                }
                Text {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    text: vehicleCtrl && vehicleCtrl.warningDoor ? "Open" : "Closed"
                    font.family: "Inter"
                    font.pixelSize: 16
                    font.bold: Font.Bold
                    color: vehicleCtrl && vehicleCtrl.warningDoor ? Style.redLight : (Style.isDark ? Style.white : "#171717")
                }
            }
        }
    }
}
