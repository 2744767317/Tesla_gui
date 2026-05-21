#include "AutowareBridge.h"

#include <cmath>

AutowareBridge::AutowareBridge(QObject *parent) : QObject(parent)
{
    connect(&m_simTimer, &QTimer::timeout, this, &AutowareBridge::tickSimulationBackend);
    publishContractState();
}

AutowareBridge::~AutowareBridge()
{
    disconnectFromAutoware();
}

void AutowareBridge::connectToAutoware()
{
    if (m_backendMode != QLatin1String("simulation")) {
        updateStatus("Backend unavailable");
        setOperationMode(QStringLiteral("backend-unavailable"));
        return;
    }

    m_connected = true;
    updateStatus("Connected");
    setOperationMode(QStringLiteral("local-sim"));
    emit connectedChanged();

    m_simTimer.start(100);
}

void AutowareBridge::disconnectFromAutoware()
{
    m_simTimer.stop();
    m_connected = false;
    updateStatus("Disconnected");
    setOperationMode(QStringLiteral("unknown"));
    setGoalState(QStringLiteral("idle"));
    emit connectedChanged();
}

void AutowareBridge::setBackendMode(const QString &mode)
{
    const QString normalizedMode = mode.trimmed().isEmpty()
        ? QStringLiteral("simulation")
        : mode.trimmed().toLower();
    if (m_backendMode == normalizedMode)
        return;

    disconnectFromAutoware();
    m_backendMode = normalizedMode;
    emit backendModeChanged();

    if (m_backendMode == QLatin1String("simulation")) {
        updateStatus("Disconnected");
        setOperationMode(QStringLiteral("unknown"));
    } else {
        updateStatus("Backend unavailable");
        setOperationMode(QStringLiteral("backend-unavailable"));
    }
}

void AutowareBridge::sendGoal(double lat, double lng)
{
    m_lat = lat;
    m_lng = lng;
    m_pathAvailable = true;
    m_currentMission = "Navigation";
    m_missionProgress = 0;
    setGoalState(QStringLiteral("planning"));
    
    rebuildSimulationPathData();
    emit pathAvailableChanged();
    emit currentMissionChanged();
}

void AutowareBridge::cancelGoal()
{
    m_pathAvailable = false;
    m_pathPoints.clear();
    m_trajectory.clear();
    m_currentMission = "Idle";
    m_missionProgress = 0;
    setGoalState(QStringLiteral("cancelled"));
    
    emit pathAvailableChanged();
    emit pathPointsChanged();
    emit trajectoryChanged();
    emit currentMissionChanged();
    emit missionProgressChanged();
}

void AutowareBridge::setAutonomousMode(bool enabled)
{
    m_isAutonomous = enabled;
    if (enabled) {
        m_currentMission = "Autonomous Driving";
        m_gear = 1;
        setOperationMode(QStringLiteral("autonomous"));
        if (m_pathAvailable)
            setGoalState(QStringLiteral("executing"));
        emit gearChanged();
    } else {
        m_currentMission = "Manual Driving";
        setOperationMode(QStringLiteral("manual"));
    }
    emit isAutonomousChanged();
    emit currentMissionChanged();
}

void AutowareBridge::sendEmergencyStop()
{
    m_isEmergencyStop = true;
    m_vehicleSpeed = 0.0;
    m_throttle = 0.0;
    m_brake = 1.0;
    m_currentMission = "Emergency Stop";
    setEmergencyState(QStringLiteral("emergency_stop"));
    setOperationMode(QStringLiteral("emergency"));
    
    emit isEmergencyStopChanged();
    emit vehicleSpeedChanged();
    emit throttleChanged();
    emit brakeChanged();
    emit currentMissionChanged();
}

void AutowareBridge::clearEmergencyStop()
{
    m_isEmergencyStop = false;
    m_brake = 0.0;
    m_currentMission = "Idle";
    setEmergencyState(QStringLiteral("normal"));
    setOperationMode(m_connected ? QStringLiteral("manual") : QStringLiteral("unknown"));
    
    emit isEmergencyStopChanged();
    emit brakeChanged();
    emit currentMissionChanged();
}

void AutowareBridge::tickSimulationBackend()
{
    m_simTick++;
    
    updateSimulationVehicleData();
    
    if (m_pathAvailable && m_isAutonomous) {
        m_missionProgress = qMin(100, m_missionProgress + 1);
        if (m_missionProgress >= 100)
            setGoalState(QStringLiteral("arrived"));
        emit missionProgressChanged();
    }
}

void AutowareBridge::updateStatus(const std::string& status)
{
    m_status = status;
    emit statusChanged();
}

void AutowareBridge::setOperationMode(const QString &mode)
{
    if (m_operationMode == mode)
        return;

    m_operationMode = mode;
    emit operationModeChanged();
}

void AutowareBridge::setGoalState(const QString &state)
{
    if (m_goalState == state)
        return;

    m_goalState = state;
    emit goalStateChanged();
}

void AutowareBridge::setEmergencyState(const QString &state)
{
    if (m_emergencyState == state)
        return;

    m_emergencyState = state;
    emit emergencyStateChanged();
}

void AutowareBridge::publishContractState()
{
    m_vehiclePose = {
        {QStringLiteral("latitude"), m_lat},
        {QStringLiteral("longitude"), m_lng},
        {QStringLiteral("heading"), m_heading},
        {QStringLiteral("odomX"), m_odomX},
        {QStringLiteral("odomY"), m_odomY},
        {QStringLiteral("frameId"), QStringLiteral("map")}
    };
    m_vehicleVelocity = {
        {QStringLiteral("speedKmh"), m_vehicleSpeed},
        {QStringLiteral("targetSpeedKmh"), m_targetSpeed},
        {QStringLiteral("steeringAngleDeg"), m_steeringAngle},
        {QStringLiteral("throttle"), m_throttle},
        {QStringLiteral("brake"), m_brake}
    };

    emit vehiclePoseChanged();
    emit vehicleVelocityChanged();
}

void AutowareBridge::updateSimulationVehicleData()
{
    if (m_isAutonomous && !m_isEmergencyStop) {
        if (m_vehicleSpeed < 60.0) {
            m_vehicleSpeed += 0.5;
            m_throttle = 0.3;
        } else {
            m_vehicleSpeed = 60.0;
            m_throttle = 0.1;
        }
        
        m_steeringAngle = std::sin(m_simTick * 0.1) * 5.0;
        m_heading += 0.1;
        m_odomX += std::cos(m_heading * 0.01745) * m_vehicleSpeed * 0.01;
        m_odomY += std::sin(m_heading * 0.01745) * m_vehicleSpeed * 0.01;
        m_lat += 0.00001;
        m_lng += 0.00001;
    } else if (!m_isEmergencyStop) {
        m_vehicleSpeed *= 0.95;
        m_throttle = 0.0;
        m_brake = 0.0;
    }
    
    emit vehicleSpeedChanged();
    emit steeringAngleChanged();
    emit throttleChanged();
    emit brakeChanged();
    emit latChanged();
    emit lngChanged();
    emit headingChanged();
    emit odomXChanged();
    emit odomYChanged();
    publishContractState();
}

void AutowareBridge::rebuildSimulationPathData()
{
    m_pathPoints.clear();
    m_trajectory.clear();
    
    double startLat = 28.4595;
    double startLng = 77.0266;
    double endLat = m_lat;
    double endLng = m_lng;
    
    int numPoints = 50;
    for (int i = 0; i <= numPoints; i++) {
        double t = static_cast<double>(i) / numPoints;
        double lat = startLat + (endLat - startLat) * t;
        double lng = startLng + (endLng - startLng) * t;
        
        QVariantMap point;
        point["lat"] = lat;
        point["lng"] = lng;
        m_pathPoints.append(point);

        QVariantMap trajectoryPoint;
        trajectoryPoint["latitude"] = lat;
        trajectoryPoint["longitude"] = lng;
        trajectoryPoint["targetSpeedKmh"] = m_targetSpeed > 0.0 ? m_targetSpeed : 40.0;
        trajectoryPoint["relativeTimeSec"] = i * 0.4;
        m_trajectory.append(trajectoryPoint);
    }
    
    emit pathPointsChanged();
    emit trajectoryChanged();
    setGoalState(QStringLiteral("ready"));
}
