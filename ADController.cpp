#include "ADController.h"

ADController::ADController(QObject *parent) : QObject(parent)
{
    publishContractState();
}

void ADController::enableAD()
{
    m_adEnabled = true;
    m_autoSteering = true;
    m_autoBrake = true;
    m_autoAccelerate = true;
    m_laneAssist = true;
    m_targetSpeed = m_cruiseSpeed;
    setOperationMode(QStringLiteral("autonomous"));
    setGoalState(QStringLiteral("monitoring"));
    setEmergencyState(QStringLiteral("normal"));
    updateADStatus("Active");
    
    emit adEnabledChanged();
    emit targetSpeedChanged();
    emit autoSteeringChanged();
    emit autoBrakeChanged();
    emit autoAccelerateChanged();
    emit laneAssistChanged();
    publishContractState();
}

void ADController::disableAD()
{
    m_adEnabled = false;
    m_autoSteering = false;
    m_autoBrake = false;
    m_autoAccelerate = false;
    m_targetSpeed = 0.0;
    setOperationMode(QStringLiteral("manual"));
    setGoalState(QStringLiteral("idle"));
    updateADStatus("Ready");
    
    emit adEnabledChanged();
    emit targetSpeedChanged();
    emit autoSteeringChanged();
    emit autoBrakeChanged();
    emit autoAccelerateChanged();
    publishContractState();
}

void ADController::setCruiseSpeed(double kmh)
{
    m_cruiseSpeed = qMax(0.0, qMin(120.0, kmh));
    if (m_adEnabled) {
        m_targetSpeed = m_cruiseSpeed;
        emit targetSpeedChanged();
    }
    emit cruiseSpeedChanged();
    publishContractState();
}

void ADController::toggleLaneAssist()
{
    m_laneAssist = !m_laneAssist;
    emit laneAssistChanged();
}

void ADController::toggleAutoSteering()
{
    m_autoSteering = !m_autoSteering;
    if (m_autoSteering && !m_adEnabled) {
        enableAD();
    }
    emit autoSteeringChanged();
}

void ADController::overrideControl()
{
    if (m_adEnabled) {
        m_adEnabled = false;
        m_autoSteering = false;
        m_targetSpeed = 0.0;
        setOperationMode(QStringLiteral("manual-override"));
        setGoalState(QStringLiteral("paused"));
        updateADStatus("Override");
        emit adEnabledChanged();
        emit autoSteeringChanged();
        emit targetSpeedChanged();
        publishContractState();
    }
}

void ADController::updateADStatus(const std::string& status)
{
    m_adStatus = status;
    emit adStatusChanged();
}

void ADController::setOperationMode(const QString &mode)
{
    if (m_operationMode == mode)
        return;

    m_operationMode = mode;
    emit operationModeChanged();
}

void ADController::setGoalState(const QString &state)
{
    if (m_goalState == state)
        return;

    m_goalState = state;
    emit goalStateChanged();
}

void ADController::setEmergencyState(const QString &state)
{
    if (m_emergencyState == state)
        return;

    m_emergencyState = state;
    emit emergencyStateChanged();
}

void ADController::publishContractState()
{
    m_vehiclePose = {
        {QStringLiteral("frameId"), QStringLiteral("map")},
        {QStringLiteral("latitude"), 0.0},
        {QStringLiteral("longitude"), 0.0},
        {QStringLiteral("heading"), 0.0}
    };
    m_vehicleVelocity = {
        {QStringLiteral("speedKmh"), m_adEnabled ? m_cruiseSpeed : 0.0},
        {QStringLiteral("targetSpeedKmh"), m_targetSpeed},
        {QStringLiteral("operationMode"), m_operationMode}
    };
    m_trajectory = {};

    emit vehiclePoseChanged();
    emit vehicleVelocityChanged();
    emit trajectoryChanged();
}
