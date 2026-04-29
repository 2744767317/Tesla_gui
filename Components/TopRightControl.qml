import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

RowLayout {
    spacing: 48
    property int temp: vehicleCtrl ? Math.round(vehicleCtrl.engineTemp * 9 / 5 + 32) : 72
    property bool airbagOn: vehicleCtrl ? !vehicleCtrl.warningSeatbelt : false
    Text {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        text: vehicleCtrl && vehicleCtrl.isDriving ? "%0 mph".arg(Math.round(vehicleCtrl.speed * 0.621371)) : "Ready"
        font.family: "Inter"
        font.pixelSize: 18
        font.bold: Font.DemiBold
        color: Style.isDark ? Style.white : Style.black20
    }

    Text {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        text: "%0ºF".arg(temp)
        font.family: "Inter"
        font.pixelSize: 18
        font.bold: Font.DemiBold
        color: Style.isDark ? Style.white : Style.black20
    }

    Control {
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        implicitHeight: 38
        background: Rectangle {
            color: Style.isDark ? Style.alphaColor(Style.black,0.55) : Style.black20
            radius: 7
        }
        contentItem: RowLayout {
            spacing: 10
            anchors.centerIn: parent
            Image {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.leftMargin: 10
                source: "qrc:/icons/top_header_icons/airbag_.svg"
            }
            Text {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.rightMargin: 10
                text: airbagOn ? "PASSENGER\nAIRBAG ON" : "PASSENGER\nAIRBAG OFF"
                font.family: Style.fontFamily
                font.bold: Font.Bold
                font.pixelSize: 12
                color: Style.white
            }
        }
    }
}
