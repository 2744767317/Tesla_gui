import QtQuick 2.9
import QtPositioning

QtObject {
    property var routePath: []
    property var drivePath: []
    property var routeDistanceCache: []
    property var routeRenderPath: []
    property var routeInteractionPath: []
    property var routeSteps: []
    property var routeOptions: []
    property int activeRouteIndex: 0
    property int routeCursorIndex: 0
    property int routeSegmentIndex: 0
    property real routeTotalDistanceMeters: 0
    property string routeStatus: "idle"
    property string routeHint: "搜索目的地，选择路线后开始导航"
    property string routePreference: "fastest"
    property bool routeRequestInFlight: false

    function routeDistanceMiles(path) {
        var sourcePath = path && path.length ? path : routePath
        if (!sourcePath || sourcePath.length < 2)
            return 0

        var meters = 0
        for (var index = 1; index < sourcePath.length; index++)
            meters += sourcePath[index - 1].distanceTo(sourcePath[index])
        return meters / 1609.344
    }

    function buildDemoRoute(startCoordinate, endCoordinate, pointCount) {
        var points = []
        var totalPoints = typeof pointCount === "number" ? pointCount : 180

        for (var index = 0; index <= totalPoints; index++) {
            var progress = index / totalPoints
            var latitude = startCoordinate.latitude + (endCoordinate.latitude - startCoordinate.latitude) * progress
            var longitude = startCoordinate.longitude + (endCoordinate.longitude - startCoordinate.longitude) * progress
            var wave = Math.sin(progress * Math.PI * 1.6) * 0.0026

            points.push(QtPositioning.coordinate(latitude + wave * 0.55, longitude + wave))
        }

        return points
    }

    function bearingBetween(fromCoord, toCoord) {
        var lat1 = fromCoord.latitude * Math.PI / 180
        var lat2 = toCoord.latitude * Math.PI / 180
        var dLon = (toCoord.longitude - fromCoord.longitude) * Math.PI / 180
        var y = Math.sin(dLon) * Math.cos(lat2)
        var x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon)
        return (Math.atan2(y, x) * 180 / Math.PI + 360) % 360
    }

    function angleDeltaDegrees(firstAngle, secondAngle) {
        return Math.abs(((secondAngle - firstAngle + 540) % 360) - 180)
    }

    function shortestAngleDelta(fromAngle, toAngle) {
        return ((toAngle - fromAngle + 540) % 360) - 180
    }

    function smoothBearing(fromAngle, toAngle, factor) {
        return (fromAngle + shortestAngleDelta(fromAngle, toAngle) * factor + 360) % 360
    }

    function interpolateCoordinate(fromCoord, toCoord, ratio) {
        return QtPositioning.coordinate(
            fromCoord.latitude + (toCoord.latitude - fromCoord.latitude) * ratio,
            fromCoord.longitude + (toCoord.longitude - fromCoord.longitude) * ratio
        )
    }

    function densifySegment(segmentStart, segmentEnd, stepMeters, output) {
        var segmentLength = segmentStart.distanceTo(segmentEnd)
        if (segmentLength < 0.2) {
            output.push(segmentEnd)
            return
        }

        var steps = Math.max(1, Math.ceil(segmentLength / Math.max(6, stepMeters)))
        for (var stepIndex = 1; stepIndex <= steps; stepIndex++)
            output.push(interpolateCoordinate(segmentStart, segmentEnd, stepIndex / steps))
    }

    function resampleDrivePath(path) {
        if (!path || path.length < 2)
            return path || []

        var resampled = [path[0]]
        for (var index = 0; index < path.length - 1; index++) {
            var current = path[index]
            var next = path[index + 1]
            var previousBearing = index > 0 ? bearingBetween(path[index - 1], current) : bearingBetween(current, next)
            var nextBearing = bearingBetween(current, next)
            var turnAngle = angleDeltaDegrees(previousBearing, nextBearing)
            var segmentLength = current.distanceTo(next)
            var stepMeters = 36

            if (turnAngle > 60)
                stepMeters = 6
            else if (turnAngle > 28)
                stepMeters = 12
            else if (segmentLength > 1800)
                stepMeters = 65
            else if (segmentLength > 600)
                stepMeters = 44
            else if (segmentLength > 180)
                stepMeters = 24

            densifySegment(current, next, stepMeters, resampled)
        }

        return resampled
    }

    function simplifyRenderPath(path, minPointDistanceMeters, keepTurnDegrees) {
        if (!path || path.length < 3)
            return path || []

        var simplified = [path[0]]
        var lastKept = path[0]
        for (var index = 1; index < path.length - 1; index++) {
            var previous = path[index - 1]
            var current = path[index]
            var next = path[index + 1]
            var turnAngle = angleDeltaDegrees(bearingBetween(previous, current), bearingBetween(current, next))
            var distanceFromLast = lastKept.distanceTo(current)

            // 直线段减少折点，转弯段保留细节，缩放时更省。
            if (turnAngle >= keepTurnDegrees || distanceFromLast >= minPointDistanceMeters) {
                simplified.push(current)
                lastKept = current
            }
        }

        simplified.push(path[path.length - 1])
        return simplified
    }

    function rebuildRouteDistanceCache(path) {
        var sourcePath = path && path.length ? path : drivePath
        routeDistanceCache = []
        routeTotalDistanceMeters = 0
        routeCursorIndex = 0
        routeSegmentIndex = 0

        if (!sourcePath || !sourcePath.length)
            return

        routeDistanceCache.push(0)
        if (sourcePath.length < 2)
            return

        for (var index = 1; index < sourcePath.length; index++) {
            routeTotalDistanceMeters += sourcePath[index - 1].distanceTo(sourcePath[index])
            routeDistanceCache.push(routeTotalDistanceMeters)
        }
    }

    function coordinateAtRouteDistance(distanceMeters, updatePlaybackCursor) {
        if (!drivePath.length)
            return QtPositioning.coordinate(0, 0)
        if (drivePath.length === 1)
            return drivePath[0]

        var clampedDistance = Math.max(0, Math.min(distanceMeters, routeTotalDistanceMeters))
        if (!routeDistanceCache.length)
            rebuildRouteDistanceCache(drivePath)

        var low = 0
        var high = routeDistanceCache.length - 1
        while (low < high) {
            var mid = Math.floor((low + high) / 2)
            if (routeDistanceCache[mid] < clampedDistance)
                low = mid + 1
            else
                high = mid
        }

        var upperIndex = Math.max(1, low)
        var segmentIndex = Math.max(0, upperIndex - 1)
        var segmentStart = drivePath[segmentIndex]
        var segmentEnd = drivePath[Math.min(drivePath.length - 1, segmentIndex + 1)]
        var segmentStartDistance = routeDistanceCache[segmentIndex]
        var segmentEndDistance = routeDistanceCache[Math.min(routeDistanceCache.length - 1, segmentIndex + 1)]
        var segmentLength = Math.max(0.01, segmentEndDistance - segmentStartDistance)

        if (updatePlaybackCursor !== false) {
            routeSegmentIndex = segmentIndex
            routeCursorIndex = segmentIndex
        }

        var ratio = Math.max(0, Math.min(1, (clampedDistance - segmentStartDistance) / segmentLength))
        return interpolateCoordinate(segmentStart, segmentEnd, ratio)
    }

    function coordinateAheadOfCurrent(distanceMetersAhead, currentProgressMeters) {
        return coordinateAtRouteDistance(Math.min(routeTotalDistanceMeters, currentProgressMeters + distanceMetersAhead), false)
    }

    function buildFallbackRouteSteps(distanceMiles, destinationLabel) {
        return [
            {
                type: "depart",
                modifier: "straight",
                street: "已选起点",
                distanceMiles: Math.max(0.1, distanceMiles * 0.28),
                durationMinutes: 2
            },
            {
                type: "turn",
                modifier: "slight right",
                street: "演示路线",
                distanceMiles: Math.max(0.2, distanceMiles * 0.62),
                durationMinutes: 7
            },
            {
                type: "arrive",
                modifier: "straight",
                street: destinationLabel,
                distanceMiles: Math.max(0.05, distanceMiles * 0.1),
                durationMinutes: 1
            }
        ]
    }

    function localizedStepsFromService(steps, localizePlaceNameFn) {
        var normalized = []
        var formatter = typeof localizePlaceNameFn === "function" ? localizePlaceNameFn : function(value) { return value }
        for (var index = 0; index < steps.length; index++) {
            var step = steps[index]
            normalized.push({
                type: step.type || "",
                modifier: step.modifier || "",
                street: step.street && step.street.length ? formatter(step.street) : "未命名道路",
                distanceMiles: Number(step.distanceMiles || 0),
                durationMinutes: Number(step.durationMinutes || 0)
            })
        }
        return normalized
    }

    function coordinatePathFromPoints(pathPoints) {
        var convertedPath = []
        for (var index = 0; index < pathPoints.length; index++) {
            var point = pathPoints[index]
            convertedPath.push(QtPositioning.coordinate(Number(point.lat), Number(point.lng)))
        }
        return convertedPath
    }

    function coordinateFromPoint(point) {
        if (!point || point.lat === undefined || point.lng === undefined)
            return null
        return QtPositioning.coordinate(Number(point.lat), Number(point.lng))
    }

    function serviceRouteToOption(routeData, index, localizePlaceNameFn) {
        return {
            index: index,
            title: index === 0 ? "推荐路线" : "路线 " + (index + 1),
            path: coordinatePathFromPoints(routeData.pathPoints || []),
            snappedStart: coordinateFromPoint(routeData.snappedStart),
            snappedEnd: coordinateFromPoint(routeData.snappedEnd),
            steps: localizedStepsFromService(routeData.steps || [], localizePlaceNameFn),
            distanceMiles: Number(routeData.distanceMiles || 0),
            durationMinutes: Number(routeData.durationMinutes || 0),
            score: Number(routeData.score || 0)
        }
    }

    function scoreRouteOptions(options, preferenceValue) {
        if (!options.length)
            return options

        var preference = preferenceValue && preferenceValue.length ? preferenceValue : routePreference
        var minDistance = options[0].distanceMiles
        var minDuration = options[0].durationMinutes

        for (var index = 1; index < options.length; index++) {
            minDistance = Math.min(minDistance, options[index].distanceMiles)
            minDuration = Math.min(minDuration, options[index].durationMinutes)
        }

        for (var optionIndex = 0; optionIndex < options.length; optionIndex++) {
            var option = options[optionIndex]
            if (preference === "shortest")
                option.score = option.distanceMiles
            else if (preference === "balanced")
                option.score = option.durationMinutes / Math.max(1, minDuration) + option.distanceMiles / Math.max(0.1, minDistance)
            else
                option.score = option.durationMinutes
        }

        options.sort(function(left, right) { return left.score - right.score })
        for (var sortedIndex = 0; sortedIndex < options.length; sortedIndex++)
            options[sortedIndex].title = sortedIndex === 0 ? "推荐路线" : "备选路线 " + sortedIndex

        return options
    }
}
