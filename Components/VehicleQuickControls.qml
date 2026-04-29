import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

Control {
    id: root
    implicitWidth: 684
    implicitHeight: 86

    function mphToKmh(mph) {
        return mph / 0.621371
    }

    function setCruiseMph(mph) {
        if (!vehicleCtrl)
            return

        if (!vehicleCtrl.isDriving)
            vehicleCtrl.toggleDriving()

        vehicleCtrl.setTargetSpeed(mphToKmh(mph))
    }

    function stopDriving() {
        if (!vehicleCtrl)
            return

        vehicleCtrl.park()
    }

    background: Rectangle {
        radius: 8
        color: Style.isDark ? Style.alphaColor(Style.black, 0.62) : Style.alphaColor(Style.white, 0.84)
        border.width: 1
        border.color: Style.isDark ? "#303030" : "#DADADA"
    }

    contentItem: RowLayout {
        id: panel
        spacing: 12

        ColumnLayout {
            Layout.leftMargin: 14
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                text: vehicleCtrl ? Math.round(vehicleCtrl.speed * 0.621371) : 0
                font.family: Style.fontFamily
                font.bold: Font.Bold
                font.pixelSize: 42
                color: Style.isDark ? Style.white : Style.black10
            }

            Text {
                text: "mph"
                font.family: Style.fontFamily
                font.pixelSize: 12
                color: Style.black20
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 1
            height: 52
            color: Style.isDark ? "#3A3A3A" : "#CFCFCF"
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            Text {
                text: vehicleCtrl && vehicleCtrl.isDriving ? "Driving" : "Parked"
                font.family: Style.fontFamily
                font.bold: Font.Bold
                font.pixelSize: 14
                color: Style.isDark ? Style.white : Style.black10
            }

            Text {
                text: vehicleCtrl && vehicleCtrl.isDriving
                    ? "target " + Math.round(vehicleCtrl.targetSpeed * 0.621371) + " mph"
                    : "select target mph"
                font.family: Style.fontFamily
                font.pixelSize: 11
                color: Style.black20
            }
        }

        Button {
            id: driveButton
            Layout.alignment: Qt.AlignVCenter
            text: vehicleCtrl && vehicleCtrl.isDriving ? "Stop" : "Drive"
            implicitWidth: 72
            implicitHeight: 36
            onClicked: vehicleCtrl && vehicleCtrl.isDriving ? root.stopDriving() : root.setCruiseMph(35)
            background: Rectangle {
                radius: 6
                color: vehicleCtrl && vehicleCtrl.isDriving ? Style.red : "#2A8C6A"
            }
            contentItem: Text {
                text: driveButton.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: Style.fontFamily
                font.bold: Font.Bold
                font.pixelSize: 13
                color: Style.white
            }
        }

        Repeater {
            model: [50, 90, 120]

            Button {
                id: speedButton
                Layout.alignment: Qt.AlignVCenter
                text: modelData + " mph"
                implicitWidth: 68
                implicitHeight: 36
                onClicked: root.setCruiseMph(modelData)
                background: Rectangle {
                    radius: 6
                    color: Style.isDark ? "#262626" : "#E7E7E7"
                    border.width: 1
                    border.color: Style.isDark ? "#3A3A3A" : "#D4D4D4"
                }
                contentItem: Text {
                    text: speedButton.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: Style.fontFamily
                    font.bold: Font.DemiBold
                    font.pixelSize: 13
                    color: Style.isDark ? Style.white : Style.black10
                }
            }
        }

        Button {
            id: doorButton
            Layout.alignment: Qt.AlignVCenter
            text: vehicleCtrl && vehicleCtrl.warningDoor ? "Door Open" : "Door"
            implicitWidth: 86
            implicitHeight: 36
            onClicked: if (vehicleCtrl) vehicleCtrl.toggleDoor()
            background: Rectangle {
                radius: 6
                color: vehicleCtrl && vehicleCtrl.warningDoor ? Style.yellow : (Style.isDark ? "#262626" : "#E7E7E7")
                border.width: vehicleCtrl && vehicleCtrl.warningDoor ? 0 : 1
                border.color: Style.isDark ? "#3A3A3A" : "#D4D4D4"
            }
            contentItem: Text {
                text: doorButton.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: Style.fontFamily
                font.bold: Font.DemiBold
                font.pixelSize: 13
                color: vehicleCtrl && vehicleCtrl.warningDoor ? Style.black : (Style.isDark ? Style.white : Style.black10)
            }
        }

        Button {
            id: beltButton
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 14
            text: vehicleCtrl && vehicleCtrl.warningSeatbelt ? "Belt Off" : "Belt"
            implicitWidth: 76
            implicitHeight: 36
            onClicked: if (vehicleCtrl) vehicleCtrl.toggleSeatbelt()
            background: Rectangle {
                radius: 6
                color: vehicleCtrl && vehicleCtrl.warningSeatbelt ? Style.red : (Style.isDark ? "#262626" : "#E7E7E7")
                border.width: vehicleCtrl && vehicleCtrl.warningSeatbelt ? 0 : 1
                border.color: Style.isDark ? "#3A3A3A" : "#D4D4D4"
            }
            contentItem: Text {
                text: beltButton.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: Style.fontFamily
                font.bold: Font.DemiBold
                font.pixelSize: 13
                color: vehicleCtrl && vehicleCtrl.warningSeatbelt ? Style.white : (Style.isDark ? Style.white : Style.black10)
            }
        }
    }
}
