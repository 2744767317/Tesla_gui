import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

Control {
    id: root
    implicitWidth: 536
    implicitHeight: 70

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
        radius: 12
        color: Style.isDark ? "#B814181E" : "#EAF7F9FC"
        border.width: 1
        border.color: Style.isDark ? "#2B333C" : "#D8DEE8"
    }

    contentItem: RowLayout {
        id: panel
        spacing: 9

        ColumnLayout {
            Layout.leftMargin: 13
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                text: vehicleCtrl ? Math.round(vehicleCtrl.speed * 0.621371) : 0
                font.family: Style.fontFamily
                font.bold: Font.Bold
                font.pixelSize: 32
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
            height: 46
            color: Style.isDark ? "#303842" : "#D8DEE6"
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

        DesktopButton {
            id: driveButton
            Layout.alignment: Qt.AlignVCenter
            text: vehicleCtrl && vehicleCtrl.isDriving ? "Stop" : "Drive"
            implicitWidth: 66
            implicitHeight: 32
            tone: vehicleCtrl && vehicleCtrl.isDriving ? "danger" : "accent"
            compact: true
            onClicked: vehicleCtrl && vehicleCtrl.isDriving ? root.stopDriving() : root.setCruiseMph(35)
        }

        Repeater {
            model: [50, 90, 120]

            DesktopButton {
                id: speedButton
                Layout.alignment: Qt.AlignVCenter
                text: modelData + " mph"
                implicitWidth: 62
                implicitHeight: 32
                tone: "ghost"
                compact: true
                onClicked: root.setCruiseMph(modelData)
            }
        }

        DesktopButton {
            id: doorButton
            Layout.alignment: Qt.AlignVCenter
            text: vehicleCtrl && vehicleCtrl.warningDoor ? "Door Open" : "Door"
            implicitWidth: 76
            implicitHeight: 32
            tone: vehicleCtrl && vehicleCtrl.warningDoor ? "danger" : "ghost"
            compact: true
            onClicked: if (vehicleCtrl) vehicleCtrl.toggleDoor()
        }

        DesktopButton {
            id: beltButton
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 14
            text: vehicleCtrl && vehicleCtrl.warningSeatbelt ? "Belt Off" : "Belt"
            implicitWidth: 68
            implicitHeight: 32
            tone: vehicleCtrl && vehicleCtrl.warningSeatbelt ? "danger" : "ghost"
            compact: true
            onClicked: if (vehicleCtrl) vehicleCtrl.toggleSeatbelt()
        }
    }
}
