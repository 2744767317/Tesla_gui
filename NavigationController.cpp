#include "NavigationController.h"

#include <QVariantMap>
#include <QtMath>

namespace {
QString formatStreetName(const QString &street)
{
    return street.trimmed().isEmpty() ? QStringLiteral("未命名道路") : street.trimmed();
}

QString iconForManeuver(const QString &type, const QString &modifier)
{
    if (type == QLatin1String("arrive"))
        return QStringLiteral("destination");
    if (type == QLatin1String("depart"))
        return QStringLiteral("straight");
    if (modifier == QLatin1String("left") || modifier == QLatin1String("slight left"))
        return QStringLiteral("turn-left");
    if (modifier == QLatin1String("right") || modifier == QLatin1String("slight right"))
        return QStringLiteral("turn-right");
    if (modifier == QLatin1String("sharp left"))
        return QStringLiteral("keep-left");
    if (modifier == QLatin1String("sharp right"))
        return QStringLiteral("keep-right");
    if (modifier == QLatin1String("uturn"))
        return QStringLiteral("uturn");
    return QStringLiteral("straight");
}

QString capitalizeSentence(const QString &text)
{
    if (text.isEmpty())
        return text;

    QString result = text.trimmed();
    result[0] = result.at(0).toUpper();
    return result;
}

QString buildInstruction(const QString &type, const QString &modifier, const QString &street)
{
    const QString prettyStreet = formatStreetName(street);

    if (type == QLatin1String("depart"))
        return QStringLiteral("驶入%1").arg(prettyStreet);
    if (type == QLatin1String("arrive"))
        return QStringLiteral("到达%1").arg(prettyStreet);
    if (type == QLatin1String("roundabout"))
        return QStringLiteral("通过环岛前往%1").arg(prettyStreet);
    if (type == QLatin1String("merge"))
        return QStringLiteral("并入%1").arg(prettyStreet);
    if (type == QLatin1String("on ramp"))
        return QStringLiteral("进入匝道前往%1").arg(prettyStreet);
    if (type == QLatin1String("off ramp"))
        return QStringLiteral("驶出匝道前往%1").arg(prettyStreet);
    if (type == QLatin1String("fork")) {
        if (modifier.contains(QLatin1String("left")))
            return QStringLiteral("靠左前往%1").arg(prettyStreet);
        if (modifier.contains(QLatin1String("right")))
            return QStringLiteral("靠右前往%1").arg(prettyStreet);
        return QStringLiteral("沿岔路前往%1").arg(prettyStreet);
    }
    if (type == QLatin1String("end of road")) {
        if (modifier.contains(QLatin1String("left")))
            return QStringLiteral("左转进入%1").arg(prettyStreet);
        if (modifier.contains(QLatin1String("right")))
            return QStringLiteral("右转进入%1").arg(prettyStreet);
    }

    if (modifier == QLatin1String("left"))
        return QStringLiteral("左转进入%1").arg(prettyStreet);
    if (modifier == QLatin1String("right"))
        return QStringLiteral("右转进入%1").arg(prettyStreet);
    if (modifier == QLatin1String("slight left"))
        return QStringLiteral("向左前方驶入%1").arg(prettyStreet);
    if (modifier == QLatin1String("slight right"))
        return QStringLiteral("向右前方驶入%1").arg(prettyStreet);
    if (modifier == QLatin1String("sharp left"))
        return QStringLiteral("急左转进入%1").arg(prettyStreet);
    if (modifier == QLatin1String("sharp right"))
        return QStringLiteral("急右转进入%1").arg(prettyStreet);
    if (modifier == QLatin1String("straight"))
        return QStringLiteral("沿%1直行").arg(prettyStreet);
    if (modifier == QLatin1String("uturn"))
        return QStringLiteral("调头前往%1").arg(prettyStreet);

    if (!type.trimmed().isEmpty())
        return capitalizeSentence(type) + QStringLiteral(" %1").arg(prettyStreet);

    return QStringLiteral("沿%1直行").arg(prettyStreet);
}
}

NavigationController::NavigationController(QObject *parent) : QObject(parent)
{
}

void NavigationController::startRoute()
{
    if (!m_isNavigating) {
        m_isNavigating = true;
        emit isNavigatingChanged();
    }
    if (m_routeProgress >= 1.0)
        m_routeProgress = 0.0;
    applyRouteStepForProgress(m_routeProgress);
    emit navigationUpdated();
    emit routeProgressChanged();
}

void NavigationController::stopRoute()
{
    if (!m_isNavigating)
        return;

    m_isNavigating = false;
    emit isNavigatingChanged();
    emit navigationUpdated();
}

void NavigationController::prepareRoute(const QString &destination, int pointCount, const QVariantList &steps)
{
    m_destination = destination.isEmpty() ? QStringLiteral("地图目的地") : destination;
    m_pointCount = qMax(0, pointCount);
    m_routeProgress = 0.0;
    m_carX = 0.0;
    m_carY = 0.0;

    loadRouteSteps(steps);
    applyRouteStepForProgress(0.0);

    emit navigationUpdated();
    emit routeProgressChanged();
    emit carPositionChanged();
}

void NavigationController::updateRouteProgress(double progress)
{
    const double boundedProgress = qBound(0.0, progress, 1.0);
    if (qFuzzyCompare(m_routeProgress + 1.0, boundedProgress + 1.0) && m_isNavigating)
        return;

    m_routeProgress = boundedProgress;

    if (m_routeProgress >= 1.0) {
        markArrived();
        return;
    }

    applyRouteStepForProgress(m_routeProgress);

    emit routeProgressChanged();
    emit navigationUpdated();
}

void NavigationController::markArrived()
{
    m_routeProgress = 1.0;
    m_distanceToNext = 0.0;
    m_etaMinutes = 0;
    m_currentStreet = QStringLiteral("目的地");
    m_nextManeuver = QStringLiteral("已到达");
    m_directionIcon = QStringLiteral("destination");
    if (m_isNavigating) {
        m_isNavigating = false;
        emit isNavigatingChanged();
    }
    emit routeProgressChanged();
    emit navigationUpdated();
}

void NavigationController::loadRouteSteps(const QVariantList &steps)
{
    m_routeSteps.clear();
    m_totalRouteMiles = 0.0;
    m_totalRouteMinutes = 12.0;

    if (steps.isEmpty())
        return;

    double covered = 0.0;
    double totalDistanceMiles = 0.0;
    double totalDurationMinutes = 0.0;

    for (const QVariant &stepValue : steps) {
        const QVariantMap stepMap = stepValue.toMap();
        if (stepMap.isEmpty())
            continue;

        RouteStep step;
        const double distanceMiles = qMax(0.0, stepMap.value(QStringLiteral("distanceMiles")).toDouble());
        const double durationMinutes = qMax(0.0, stepMap.value(QStringLiteral("durationMinutes")).toDouble());
        const QString street = formatStreetName(stepMap.value(QStringLiteral("street")).toString());
        const QString type = stepMap.value(QStringLiteral("type")).toString().trimmed();
        const QString modifier = stepMap.value(QStringLiteral("modifier")).toString().trimmed();

        step.distanceMiles = distanceMiles;
        step.durationMinutes = durationMinutes;
        step.street = street;
        step.directionIcon = iconForManeuver(type, modifier);
        step.instruction = buildInstruction(type, modifier, street);

        totalDistanceMiles += distanceMiles;
        totalDurationMinutes += durationMinutes;
        m_routeSteps.push_back(step);
    }

    if (m_routeSteps.isEmpty())
        return;

    m_totalRouteMiles = totalDistanceMiles;
    m_totalRouteMinutes = totalDurationMinutes > 0.0 ? totalDurationMinutes : 12.0;

    if (m_totalRouteMiles <= 0.0) {
        const double stepSpan = 1.0 / m_routeSteps.size();
        for (int index = 0; index < m_routeSteps.size(); ++index) {
            m_routeSteps[index].startProgress = index * stepSpan;
            m_routeSteps[index].endProgress = index == m_routeSteps.size() - 1 ? 1.0 : (index + 1) * stepSpan;
        }
        return;
    }

    for (int index = 0; index < m_routeSteps.size(); ++index) {
        RouteStep &step = m_routeSteps[index];
        step.startProgress = qBound(0.0, covered / m_totalRouteMiles, 1.0);
        covered += step.distanceMiles;
        step.endProgress = index == m_routeSteps.size() - 1
            ? 1.0
            : qBound(0.0, covered / m_totalRouteMiles, 1.0);
    }
}

void NavigationController::applyRouteStepForProgress(double progress)
{
    if (m_routeSteps.isEmpty()) {
        m_etaMinutes = qMax(0, static_cast<int>(qCeil(12.0 * (1.0 - progress))));
        m_distanceToNext = qMax(0.0, (1.0 - progress) * 0.5);

        if (progress < 0.35) {
            m_currentStreet = QStringLiteral("已选起点");
            m_nextManeuver = QStringLiteral("沿高亮路线直行");
            m_directionIcon = QStringLiteral("straight");
        } else if (progress < 0.75) {
            m_currentStreet = QStringLiteral("路线中段");
            m_nextManeuver = QStringLiteral("沿路线继续行驶");
            m_directionIcon = QStringLiteral("keep-left");
        } else {
            m_currentStreet = QStringLiteral("接近目的地");
            m_nextManeuver = QStringLiteral("准备到达目的地");
            m_directionIcon = QStringLiteral("destination");
        }
        return;
    }

    const RouteStep *currentStep = &m_routeSteps.last();
    int currentIndex = m_routeSteps.size() - 1;
    for (int index = 0; index < m_routeSteps.size(); ++index) {
        const RouteStep &candidate = m_routeSteps[index];
        if (progress <= candidate.endProgress || index == m_routeSteps.size() - 1) {
            currentStep = &candidate;
            currentIndex = index;
            break;
        }
    }

    const double stepSpan = qMax(0.0001, currentStep->endProgress - currentStep->startProgress);
    const double stepLocalProgress = qBound(0.0, (progress - currentStep->startProgress) / stepSpan, 1.0);
    m_distanceToNext = qMax(0.0, currentStep->distanceMiles * (1.0 - stepLocalProgress));

    double remainingMinutes = currentStep->durationMinutes * (1.0 - stepLocalProgress);
    for (int index = currentIndex + 1; index < m_routeSteps.size(); ++index)
        remainingMinutes += m_routeSteps[index].durationMinutes;
    m_etaMinutes = qMax(0, static_cast<int>(qCeil(remainingMinutes)));

    m_currentStreet = currentStep->street;
    m_nextManeuver = currentStep->instruction;
    m_directionIcon = currentStep->directionIcon;
}
