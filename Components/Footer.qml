import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

Item {
    height: 120
    width: parent.width
    property int leftCabinTemp: 72
    property int rightCabinTemp: 72
    signal openLauncher()
    Rectangle {
        anchors.fill: parent
        color: Style.black
    }

    Icon{
        id: leftControl
        icon.source: "qrc:/icons/app_icons/model-3.svg"
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 36
        onClicked: openLauncher()
    }

    Item {
        height: parent.height
        anchors.left: leftControl.right
        anchors.right: middleLayout.left
        anchors.verticalCenter: parent.verticalCenter

        StepperControl {
            anchors.centerIn: parent
            value: leftCabinTemp
            minimumValue: 60
            maximumValue: 85
            onValueEdited: leftCabinTemp = value
        }
    }

    RowLayout {
        id: middleLayout
        anchors.centerIn: parent
        spacing: 20

        Icon{
            icon.source: "qrc:/icons/app_icons/phone.svg"
            isGlow: btCtrl && (btCtrl.hasIncoming || btCtrl.isInCall)
            onClicked: {
                if (!btCtrl)
                    return
                if (!btCtrl.isConnected)
                    btCtrl.connectDevice("iPhone 15 Pro")
                else if (btCtrl.hasIncoming)
                    btCtrl.answerCall()
                else if (btCtrl.isInCall)
                    btCtrl.endCall()
            }
        }

        Icon{
            icon.source: "qrc:/icons/app_icons/radio.svg"
        }

        Icon{
            icon.source: "qrc:/icons/app_icons/bluetooth.svg"
            isGlow: btCtrl && btCtrl.isConnected
            onClicked: {
                if (!btCtrl)
                    return
                btCtrl.isConnected ? btCtrl.disconnectDevice() : btCtrl.connectDevice("iPhone 15 Pro")
            }
        }

        Icon{
            icon.source: "qrc:/icons/app_icons/spotify.svg"
            isGlow: mediaCtrl && mediaCtrl.isPlaying
            opacity: mediaCtrl && mediaCtrl.isPlaying ? 1.0 : 0.68
            scale: mediaCtrl && mediaCtrl.isPlaying ? 1.08 : 1.0
            onClicked: if (mediaCtrl) mediaCtrl.playPause()
        }

        Icon{
            icon.source: "qrc:/icons/app_icons/dashcam.svg"
        }

        Icon{
            icon.source: "qrc:/icons/app_icons/video.svg"
        }

        Icon{
            icon.source: "qrc:/icons/app_icons/tunein.svg"
        }
    }

    Item {
        height: parent.height
        anchors.right: rightControl.left
        anchors.left: middleLayout.right
        anchors.verticalCenter: parent.verticalCenter

        StepperControl {
            anchors.centerIn: parent
            value: rightCabinTemp
            minimumValue: 60
            maximumValue: 85
            onValueEdited: rightCabinTemp = value
        }
    }

    StepperControl {
        id: rightControl
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 36
        value: mediaCtrl ? mediaCtrl.volume : 70
        icon: "qrc:/icons/app_icons/volume.svg"
        onValueEdited: if (mediaCtrl) mediaCtrl.setVolume(value)
    }
}
