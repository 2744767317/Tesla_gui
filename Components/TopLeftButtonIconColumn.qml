import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

ColumnLayout {
    spacing: 3
    Icon {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        icon.source: "qrc:/light-icons/Headlight2.svg"
        opacity: vehicleCtrl && vehicleCtrl.warningEngine ? 1.0 : 0.42
        isGlow: vehicleCtrl && vehicleCtrl.warningEngine
    }
    Icon {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        icon.source: "qrc:/light-icons/Property 1=Default.svg"
        opacity: vehicleCtrl && vehicleCtrl.warningDoor ? 1.0 : 0.42
        isGlow: vehicleCtrl && vehicleCtrl.warningDoor
        onClicked: if (vehicleCtrl) vehicleCtrl.toggleDoor()
    }
    Icon {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        icon.source: "qrc:/light-icons/Headlights.svg"
        opacity: vehicleCtrl && vehicleCtrl.warningBattery ? 1.0 : 0.42
        isGlow: vehicleCtrl && vehicleCtrl.warningBattery
    }
    Icon {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        icon.source: "qrc:/light-icons/Seatbelt.svg"
        opacity: vehicleCtrl && vehicleCtrl.warningSeatbelt ? 1.0 : 0.42
        isGlow: vehicleCtrl && vehicleCtrl.warningSeatbelt
        onClicked: if (vehicleCtrl) vehicleCtrl.toggleSeatbelt()
    }
}
