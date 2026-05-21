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
    title: qsTr("Tesla Dashboard")
    property bool fusionPanelVisible: false
    property bool autowarePanelVisible: false
    readonly property var autowareBridgeObject: autowareBridge
    readonly property var adControllerObject: adController
    readonly property int desktopPaneWidth: Math.max(216, Math.min(236, root.width * 0.17))
    readonly property int footerHeight: footerLayout.height
    readonly property int headerHeight: headerLayout.height

    Connections {
        target: vehicleCtrl

        function onIsDrivingChanged() {
            if (!vehicleCtrl.isDriving && navCtrl && navCtrl.isNavigating)
                navCtrl.stopRoute()
        }
    }

    Connections {
        target: autowareBridge
        function onConnectedChanged() {
            console.log("Autoware connected:", autowareBridge.connected)
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
        anchors.leftMargin: 12
        anchors.topMargin: 4
    }

    RowLayout {
        id: mapLayout
        visible: Style.mapAreaVisible
        spacing: 0
        anchors.fill: parent

        Item {
            id: desktopPane
            Layout.preferredWidth: root.desktopPaneWidth
            Layout.fillHeight: true

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -20
                source: Style.isDark ? "qrc:/icons/light/sidebar.png" : "qrc:/icons/dark/sidebar-light.png"
                opacity: 0.04
                scale: 0.76
            }

            Rectangle {
                anchors.fill: parent
                color: Style.isDark ? Style.alphaColor(Style.black, 0.18) : Style.alphaColor(Style.white, 0.14)
            }

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: Style.isDark ? "#242A31" : "#DDE3EA"
            }

            DriveOverviewCard {
                id: driveOverview
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.footerHeight + 22
                width: Math.min(206, parent.width - 20)
                height: root.autowarePanelVisible
                    ? 224
                    : Math.min(202, Math.max(190, parent.height - root.headerHeight - root.footerHeight - 180))
                hmiPanelActive: root.autowarePanelVisible
                onHmiRequested: root.autowarePanelVisible = !root.autowarePanelVisible
                z: 3
            }

            AutowareStatusPanel {
                id: autowarePanel
                visible: root.autowarePanelVisible
                width: driveOverview.width
                height: 96
                anchors.horizontalCenter: driveOverview.horizontalCenter
                anchors.bottom: driveOverview.top
                anchors.bottomMargin: 12
                autowareBridge: root.autowareBridgeObject
                adController: root.adControllerObject
                z: 4
            }

            DesktopButton {
                id: connectBtn
                visible: false
                width: 102
                height: 30
                anchors.right: autowarePanel.right
                anchors.bottom: autowarePanel.top
                anchors.bottomMargin: 10
                text: autowareBridge && autowareBridge.connected ? "Disconnect" : "Connect"
                tone: autowareBridge && autowareBridge.connected ? "danger" : "accent"
                compact: true
                onClicked: {
                    if (autowareBridge) {
                        if (autowareBridge.connected) {
                            autowareBridge.disconnectFromAutoware()
                        } else {
                            autowareBridge.connectToAutoware()
                        }
                    }
                }
            }
        }

        NavigationMapHelperScreen {
            id: mapDesktop
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
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: footerLayout.height + 12
    }

    Button {
        id: fusionToggle
        z: 100
        width: 128
        height: 38
        text: root.fusionPanelVisible ? "Dock  v" : "Dock  ^"
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: footerLayout.height + (root.fusionPanelVisible ? fusionPanel.height + 22 : 18)
        onClicked: root.fusionPanelVisible = !root.fusionPanelVisible

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 260; easing.type: Easing.InOutQuad }
        }

        background: Rectangle {
            radius: 8
            color: root.fusionPanelVisible ? "#2A8C6A" : "#20262D"
            border.width: 1
            border.color: root.fusionPanelVisible ? "#49D3A8" : "#3A424B"
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
