import QtQuick 2.9
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import Style 1.0

ColumnLayout {
    id: root

    property var searchState: null
    property var searchResults: []
    property bool compactMode: true
    property bool showSearchResults: false
    property string destinationLabel: ""
    property var favoritePlace: null
    property alias searchText: searchBox.text

    signal searchRequested(string query, bool committed)
    signal placeSelected(var place)
    signal homeRequested()
    signal workRequested()
    signal favoriteRequested()

    function showQuickSuggestionsIfNeeded() {
        if (searchState && searchState.showQuickSuggestions)
            searchState.showQuickSuggestions("常用地点")
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        TextField {
            id: searchBox
            Layout.fillWidth: true
            implicitHeight: 31
            placeholderText: "搜索目的地"
            leftPadding: 11
            rightPadding: 11
            activeFocusOnTab: true
            selectByMouse: true
            persistentSelection: true
            inputMethodHints: Qt.ImhNoAutoUppercase
            color: Style.isDark ? Style.white : Style.black10
            selectedTextColor: Style.white
            selectionColor: "#2E78FF"
            font.pixelSize: 11

            onActiveFocusChanged: {
                if (activeFocus) {
                    Qt.inputMethod.show()
                    if (text.length === 0)
                        root.showQuickSuggestionsIfNeeded()
                }
            }

            onTextChanged: {
                if (!activeFocus)
                    return
                if (inputMethodComposing)
                    return

                if (text.length === 0) {
                    root.showQuickSuggestionsIfNeeded()
                    return
                }

                searchDebounce.restart()
            }

            onAccepted: root.searchRequested(text, true)

            background: Rectangle {
                radius: 8
                color: Style.isDark ? "#252525" : "#F3F4F6"
                border.width: 1
                border.color: searchBox.activeFocus ? "#11E3F3" : (Style.isDark ? "#343434" : "#D6D9DE")
            }
        }

        DesktopButton {
            text: "搜索"
            implicitWidth: 48
            implicitHeight: 31
            tone: "accent"
            onClicked: root.searchRequested(searchBox.text, true)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? 26 : 0
        visible: searchBox.activeFocus || root.showSearchResults || !root.compactMode
        spacing: 6

        DesktopButton {
            text: searchState && searchState.homePlace ? "Home" : "设Home"
            Layout.fillWidth: true
            implicitHeight: 26
            compact: true
            tone: searchState && searchState.homePlace ? "ghost" : "neutral"
            onClicked: {
                if (searchState && searchState.homePlace)
                    root.placeSelected(searchState.homePlace)
                else
                    root.homeRequested()
            }
        }

        DesktopButton {
            text: searchState && searchState.workPlace ? "Work" : "设Work"
            Layout.fillWidth: true
            implicitHeight: 26
            compact: true
            tone: searchState && searchState.workPlace ? "ghost" : "neutral"
            onClicked: {
                if (searchState && searchState.workPlace)
                    root.placeSelected(searchState.workPlace)
                else
                    root.workRequested()
            }
        }

        DesktopButton {
            text: searchState && favoritePlace && searchState.isFavorite(favoritePlace) ? "已收藏" : "收藏"
            Layout.fillWidth: true
            implicitHeight: 26
            compact: true
            tone: "ghost"
            onClicked: root.favoriteRequested()
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: root.showSearchResults
            ? Math.min(root.compactMode ? 168 : 220, Math.max(1, root.searchResults.length) * 42)
            : 0
        visible: root.showSearchResults
        clip: true
        model: root.searchResults
        spacing: 6

        delegate: Rectangle {
            width: ListView.view.width
            height: 36
            radius: 8
            color: Style.isDark ? "#21262C" : "#F5F6F8"
            border.width: 1
            border.color: Style.isDark ? "#2E3740" : "#E0E5EB"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: modelData.name
                    elide: Text.ElideRight
                    font.family: Style.fontFamily
                    font.pixelSize: 10
                    color: Style.isDark ? Style.white : Style.black10
                }

                Rectangle {
                    visible: modelData.sourceLabel !== undefined && modelData.sourceLabel.length > 0
                    Layout.preferredWidth: sourceLabel.implicitWidth + 12
                    Layout.preferredHeight: 18
                    radius: 9
                    color: modelData.sourceType === "online" ? "#233A5C"
                        : modelData.sourceType === "favorite" ? "#4A3920"
                        : modelData.sourceType === "history" ? "#273949"
                        : modelData.sourceType === "home" || modelData.sourceType === "work" ? "#234A3C"
                        : modelData.sourceType === "region" ? "#3E334C"
                        : modelData.sourceType === "gazetteer" ? "#283746"
                        : "#2A3036"
                    border.width: 1
                    border.color: modelData.sourceType === "online" ? "#4E8DE8"
                        : modelData.sourceType === "favorite" ? "#D3A34A"
                        : modelData.sourceType === "history" ? "#5C8BA8"
                        : modelData.sourceType === "home" || modelData.sourceType === "work" ? "#49D3A8"
                        : modelData.sourceType === "region" ? "#9B7AD3"
                        : modelData.sourceType === "gazetteer" ? "#63A7D8"
                        : "#49525C"

                    Text {
                        id: sourceLabel
                        anchors.centerIn: parent
                        text: modelData.sourceLabel || ""
                        font.family: Style.fontFamily
                        font.pixelSize: 8
                        color: "#E8F7FF"
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.placeSelected(modelData)
            }
        }
    }

    Timer {
        id: searchDebounce
        interval: 450
        repeat: false
        onTriggered: root.searchRequested(searchBox.text, false)
    }
}
