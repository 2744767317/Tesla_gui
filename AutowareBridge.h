#pragma once
#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqml.h>
#include <memory>
#include <string>

class AutowareBridge : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(std::string status READ status NOTIFY statusChanged)
    Q_PROPERTY(QVariantMap vehiclePose READ vehiclePose NOTIFY vehiclePoseChanged)
    Q_PROPERTY(QVariantMap vehicleVelocity READ vehicleVelocity NOTIFY vehicleVelocityChanged)
    Q_PROPERTY(QVariantList trajectory READ trajectory NOTIFY trajectoryChanged)
    Q_PROPERTY(QString backendMode READ backendMode WRITE setBackendMode NOTIFY backendModeChanged)
    Q_PROPERTY(QString operationMode READ operationMode NOTIFY operationModeChanged)
    Q_PROPERTY(QString goalState READ goalState NOTIFY goalStateChanged)
    Q_PROPERTY(QString emergencyState READ emergencyState NOTIFY emergencyStateChanged)

    Q_PROPERTY(double vehicleSpeed READ vehicleSpeed NOTIFY vehicleSpeedChanged)
    Q_PROPERTY(double steeringAngle READ steeringAngle NOTIFY steeringAngleChanged)
    Q_PROPERTY(double throttle READ throttle NOTIFY throttleChanged)
    Q_PROPERTY(double brake READ brake NOTIFY brakeChanged)
    Q_PROPERTY(int gear READ gear NOTIFY gearChanged)
    Q_PROPERTY(bool isAutonomous READ isAutonomous NOTIFY isAutonomousChanged)
    Q_PROPERTY(bool isEmergencyStop READ isEmergencyStop NOTIFY isEmergencyStopChanged)

    Q_PROPERTY(double lat READ lat NOTIFY latChanged)
    Q_PROPERTY(double lng READ lng NOTIFY lngChanged)
    Q_PROPERTY(double heading READ heading NOTIFY headingChanged)
    Q_PROPERTY(double odomX READ odomX NOTIFY odomXChanged)
    Q_PROPERTY(double odomY READ odomY NOTIFY odomYChanged)

    Q_PROPERTY(bool pathAvailable READ pathAvailable NOTIFY pathAvailableChanged)
    Q_PROPERTY(QVariantList pathPoints READ pathPoints NOTIFY pathPointsChanged)

    Q_PROPERTY(double targetSpeed READ targetSpeed NOTIFY targetSpeedChanged)
    Q_PROPERTY(std::string currentMission READ currentMission NOTIFY currentMissionChanged)
    Q_PROPERTY(int missionProgress READ missionProgress NOTIFY missionProgressChanged)

public:
    explicit AutowareBridge(QObject *parent = nullptr);
    ~AutowareBridge();

    bool connected() const { return m_connected; }
    std::string status() const { return m_status; }
    QVariantMap vehiclePose() const { return m_vehiclePose; }
    QVariantMap vehicleVelocity() const { return m_vehicleVelocity; }
    QVariantList trajectory() const { return m_trajectory; }
    QString backendMode() const { return m_backendMode; }
    QString operationMode() const { return m_operationMode; }
    QString goalState() const { return m_goalState; }
    QString emergencyState() const { return m_emergencyState; }

    double vehicleSpeed() const { return m_vehicleSpeed; }
    double steeringAngle() const { return m_steeringAngle; }
    double throttle() const { return m_throttle; }
    double brake() const { return m_brake; }
    int gear() const { return m_gear; }
    bool isAutonomous() const { return m_isAutonomous; }
    bool isEmergencyStop() const { return m_isEmergencyStop; }

    double lat() const { return m_lat; }
    double lng() const { return m_lng; }
    double heading() const { return m_heading; }
    double odomX() const { return m_odomX; }
    double odomY() const { return m_odomY; }

    bool pathAvailable() const { return m_pathAvailable; }
    QVariantList pathPoints() const { return m_pathPoints; }

    double targetSpeed() const { return m_targetSpeed; }
    std::string currentMission() const { return m_currentMission; }
    int missionProgress() const { return m_missionProgress; }

public slots:
    void connectToAutoware();
    void disconnectFromAutoware();
    void setBackendMode(const QString &mode);
    void sendGoal(double lat, double lng);
    void cancelGoal();
    void setAutonomousMode(bool enabled);
    void sendEmergencyStop();
    void clearEmergencyStop();

signals:
    void connectedChanged();
    void statusChanged();
    void vehiclePoseChanged();
    void vehicleVelocityChanged();
    void trajectoryChanged();
    void backendModeChanged();
    void operationModeChanged();
    void goalStateChanged();
    void emergencyStateChanged();
    void vehicleSpeedChanged();
    void steeringAngleChanged();
    void throttleChanged();
    void brakeChanged();
    void gearChanged();
    void isAutonomousChanged();
    void isEmergencyStopChanged();
    void latChanged();
    void lngChanged();
    void headingChanged();
    void odomXChanged();
    void odomYChanged();
    void pathAvailableChanged();
    void pathPointsChanged();
    void targetSpeedChanged();
    void currentMissionChanged();
    void missionProgressChanged();

private slots:
    void tickSimulationBackend();

private:
    void updateStatus(const std::string& status);
    void updateSimulationVehicleData();
    void rebuildSimulationPathData();
    void publishContractState();
    void setOperationMode(const QString &mode);
    void setGoalState(const QString &state);
    void setEmergencyState(const QString &state);

    bool m_connected = false;
    std::string m_status = "Disconnected";
    QVariantMap m_vehiclePose;
    QVariantMap m_vehicleVelocity;
    QVariantList m_trajectory;
    QString m_backendMode = QStringLiteral("simulation");
    QString m_operationMode = QStringLiteral("unknown");
    QString m_goalState = QStringLiteral("idle");
    QString m_emergencyState = QStringLiteral("normal");

    double m_vehicleSpeed = 0.0;
    double m_steeringAngle = 0.0;
    double m_throttle = 0.0;
    double m_brake = 0.0;
    int m_gear = 0;
    bool m_isAutonomous = false;
    bool m_isEmergencyStop = false;

    double m_lat = 28.4595;
    double m_lng = 77.0266;
    double m_heading = 0.0;
    double m_odomX = 0.0;
    double m_odomY = 0.0;

    bool m_pathAvailable = false;
    QVariantList m_pathPoints;

    double m_targetSpeed = 0.0;
    std::string m_currentMission = "Idle";
    int m_missionProgress = 0;

    QTimer m_simTimer;
    int m_simTick = 0;
};
