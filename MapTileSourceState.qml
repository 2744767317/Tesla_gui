import QtQuick 2.9

QtObject {
    property var tileSettings: null
    property bool darkTheme: false

    function defaultOnlineTileHost() {
        if (tileSettings && tileSettings.onlineTileHost.length)
            return tileSettings.onlineTileHost
        return "https://basemaps.cartocdn.com/rastertiles/voyager"
    }

    function activeTileHost() {
        if (tileSettings && tileSettings.customTileHost.length)
            return tileSettings.customTileHost
        return defaultOnlineTileHost()
    }

    function mapBackgroundColor() {
        if (tileSettings && tileSettings.mapStyle === "carto-dark")
            return "#141A1F"
        return "#EEF1F2"
    }

    function mapOverlayColor() {
        if (tileSettings && tileSettings.mapStyle === "carto-dark")
            return "#10060A0E"
        return "#00000000"
    }

    function tileSourceColor() {
        if (!tileSettings)
            return "#2A3036"
        if (tileSettings.tileSourceMode === "mbtiles")
            return "#1E4B3D"
        if (tileSettings.tileSourceMode === "local")
            return "#233A5C"
        if (tileSettings.tileSourceMode === "mbtiles-error")
            return "#5A2B32"
        return "#26333B"
    }

    function tileSourceBorderColor() {
        if (!tileSettings)
            return "#49525C"
        if (tileSettings.tileSourceMode === "mbtiles")
            return "#49D3A8"
        if (tileSettings.tileSourceMode === "local")
            return "#4E8DE8"
        if (tileSettings.tileSourceMode === "mbtiles-error")
            return "#E17684"
        return "#4A6570"
    }
}
