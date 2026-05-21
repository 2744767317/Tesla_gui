import QtQuick 2.9
import QtQuick.Controls 2.5
import Style 1.0

Button {
    id: control

    property string tone: "neutral"
    property bool compact: false
    property color accentColor: "#2A8C6A"
    property color accentBorderColor: "#49D3A8"
    property color accentTextColor: Style.white
    property color neutralColor: Style.isDark ? "#23282E" : "#F2F4F6"
    property color neutralBorderColor: Style.isDark ? "#353C44" : "#D7DDE5"
    property color neutralTextColor: Style.isDark ? Style.white : Style.black10
    property color ghostColor: Style.isDark ? "#C111151A" : "#EAF7FAFC"
    property color ghostBorderColor: Style.isDark ? "#394049" : "#D6DCE4"
    property color ghostTextColor: Style.isDark ? "#D8E6F2" : Style.black10
    property color dangerColor: "#8E3845"
    property color dangerBorderColor: "#E17684"
    property color dangerTextColor: Style.white
    property color activeColor: tone === "ghost" ? "#204A63" : accentColor
    property color activeBorderColor: tone === "ghost" ? "#56A7D4" : accentBorderColor
    property color activeTextColor: Style.white

    implicitWidth: compact ? 66 : 78
    implicitHeight: compact ? 30 : 34
    hoverEnabled: true
    padding: 0

    function backgroundColor() {
        if (!enabled)
            return Style.isDark ? "#1A1E23" : "#E7EAEE"
        if (checked)
            return activeColor
        if (tone === "accent")
            return accentColor
        if (tone === "danger")
            return dangerColor
        if (tone === "ghost")
            return ghostColor
        return neutralColor
    }

    function outlineColor() {
        if (!enabled)
            return Style.isDark ? "#2D3238" : "#D0D6DE"
        if (checked)
            return activeBorderColor
        if (tone === "accent")
            return accentBorderColor
        if (tone === "danger")
            return dangerBorderColor
        if (tone === "ghost")
            return ghostBorderColor
        return neutralBorderColor
    }

    function foregroundColor() {
        if (!enabled)
            return Style.isDark ? "#7B8590" : "#93A0AC"
        if (checked)
            return activeTextColor
        if (tone === "accent")
            return accentTextColor
        if (tone === "danger")
            return dangerTextColor
        if (tone === "ghost")
            return ghostTextColor
        return neutralTextColor
    }

    background: Rectangle {
        radius: control.compact ? 7 : 8
        color: control.backgroundColor()
        border.width: 1
        border.color: control.outlineColor()
        opacity: control.enabled ? (control.down ? 0.86 : (control.hovered ? 1.0 : 0.96)) : 0.62

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    contentItem: Text {
        text: control.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        font.family: Style.fontFamily
        font.bold: control.tone === "accent" || control.tone === "danger" || control.checked ? Font.Bold : Font.DemiBold
        font.pixelSize: control.compact ? 12 : 13
        color: control.foregroundColor()
    }
}
