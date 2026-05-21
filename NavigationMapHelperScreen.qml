import QtQuick 2.9
import QtLocation 6.10
import QtQml 2.3
import QtQuick.Controls 2.5
import QtPositioning


Rectangle{

    property bool runMenuAnimation: false
    color: "black"
    visible: true
    clip: true

    // Main stack view of application
    StackView{
        id: mainApplicationStackView
        anchors.fill: parent

        // Sliding in animation
        pushEnter: Transition {
            NumberAnimation {
                properties: "x"
                from: mainApplicationStackView.width
                to: 0
                duration: 1000 // Milliseconds for push animation
                easing.type: Easing.InOutQuad
            }
        }

        // Sliding out animation
        pushExit: Transition {
            NumberAnimation {
                properties: "x"
                from: 0
                to: -mainApplicationStackView.width
                duration: 1000 // Milliseconds for push animation
                easing.type: Easing.InOutQuad
            }
        }
    }

    // Map Page
    NavigationMapScreen {
        id: pageMap
        enableGradient: true
        visible: false
    }

    Component.onCompleted: {
        mainApplicationStackView.push(pageMap)
        pageMap.startAnimation()
    }
}
