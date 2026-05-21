#pragma once
#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqml.h>

class ADController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool adAvailable READ adAvailable NOTIFY adAvailableChanged)
    Q_PROPERTY(bool adEnabled READ adEnabled NOTIFY adEnabledChanged)
    Q_PROPERTY(std::string adStatus READ adStatus NOTIFY adStatusChanged)
    Q_PROPERTY(int adLevel READ adLevel NOTIFY adLevelChanged)
    Q_PROPERTY(QString operationMode READ operationMode NOTIFY operationModeChanged)
    Q_PROPERTY(QString goalState READ goalState NOTIFY goalStateChanged)
    Q_PROPERTY(QString emergencyState READ emergencyState NOTIFY emergencyStateChanged)
    Q_PROPERTY(QVariantMap vehiclePose READ vehiclePose NOTIFY vehiclePoseChanged)
    Q_PROPERTY(QVariantMap vehicleVelocity READ vehicleVelocity NOTIFY vehicleVelocityChanged)
    Q_PROPERTY(QVariantList trajectory READ trajectory NOTIFY trajectoryChanged)

    Q_PROPERTY(double targetSpeed READ targetSpeed NOTIFY targetSpeedChanged)
    Q_PROPERTY(double cruiseSpeed READ cruiseSpeed NOTIFY cruiseSpeedChanged)
    Q_PROPERTY(bool laneAssist READ laneAssist NOTIFY laneAssistChanged)
    Q_PROPERTY(bool autoSteering READ autoSteering NOTIFY autoSteeringChanged)
    Q_PROPERTY(bool autoBrake READ autoBrake NOTIFY autoBrakeChanged)
    Q_PROPERTY(bool autoAccelerate READ autoAccelerate NOTIFY autoAccelerateChanged)

    Q_PROPERTY(std::string nextAction READ nextAction NOTIFY nextActionChanged)
    Q_PROPERTY(double distanceToAction READ distanceToAction NOTIFY distanceToActionChanged)
    Q_PROPERTY(int timeToAction READ timeToAction NOTIFY timeToActionChanged)

    Q_PROPERTY(bool obstacleAhead READ obstacleAhead NOTIFY obstacleAheadChanged)
    Q_PROPERTY(double obstacleDistance READ obstacleDistance NOTIFY obstacleDistanceChanged)
    Q_PROPERTY(bool collisionWarning READ collisionWarning NOTIFY collisionWarningChanged)

public:
    explicit ADController(QObject *parent = nullptr);

    bool adAvailable() const { return m_adAvailable; }
    bool adEnabled() const { return m_adEnabled; }
    std::string adStatus() const { return m_adStatus; }
    int adLevel() const { return m_adLevel; }
    QString operationMode() const { return m_operationMode; }
    QString goalState() const { return m_goalState; }
    QString emergencyState() const { return m_emergencyState; }
    QVariantMap vehiclePose() const { return m_vehiclePose; }
    QVariantMap vehicleVelocity() const { return m_vehicleVelocity; }
    QVariantList trajectory() const { return m_trajectory; }

    double targetSpeed() const { return m_targetSpeed; }
    double cruiseSpeed() const { return m_cruiseSpeed; }
    bool laneAssist() const { return m_laneAssist; }
    bool autoSteering() const { return m_autoSteering; }
    bool autoBrake() const { return m_autoBrake; }
    bool autoAccelerate() const { return m_autoAccelerate; }

    std::string nextAction() const { return m_nextAction; }
    double distanceToAction() const { return m_distanceToAction; }
    int timeToAction() const { return m_timeToAction; }

    bool obstacleAhead() const { return m_obstacleAhead; }
    double obstacleDistance() const { return m_obstacleDistance; }
    bool collisionWarning() const { return m_collisionWarning; }

public slots:
    void enableAD();
    void disableAD();
    void setCruiseSpeed(double kmh);
    void toggleLaneAssist();
    void toggleAutoSteering();
    void overrideControl();

signals:
    void adAvailableChanged();
    void adEnabledChanged();
    void adStatusChanged();
    void adLevelChanged();
    void operationModeChanged();
    void goalStateChanged();
    void emergencyStateChanged();
    void vehiclePoseChanged();
    void vehicleVelocityChanged();
    void trajectoryChanged();
    void targetSpeedChanged();
    void cruiseSpeedChanged();
    void laneAssistChanged();
    void autoSteeringChanged();
    void autoBrakeChanged();
    void autoAccelerateChanged();
    void nextActionChanged();
    void distanceToActionChanged();
    void timeToActionChanged();
    void obstacleAheadChanged();
    void obstacleDistanceChanged();
    void collisionWarningChanged();

private:
    void updateADStatus(const std::string& status);
    void setOperationMode(const QString &mode);
    void setGoalState(const QString &state);
    void setEmergencyState(const QString &state);
    void publishContractState();

    bool m_adAvailable = true;
    bool m_adEnabled = false;
    std::string m_adStatus = "Ready";
    int m_adLevel = 2;
    QString m_operationMode = QStringLiteral("manual");
    QString m_goalState = QStringLiteral("idle");
    QString m_emergencyState = QStringLiteral("normal");
    QVariantMap m_vehiclePose;
    QVariantMap m_vehicleVelocity;
    QVariantList m_trajectory;

    double m_targetSpeed = 0.0;
    double m_cruiseSpeed = 60.0;
    bool m_laneAssist = false;
    bool m_autoSteering = false;
    bool m_autoBrake = false;
    bool m_autoAccelerate = false;

    std::string m_nextAction = "Keep Lane";
    double m_distanceToAction = 0.0;
    int m_timeToAction = 0;

    bool m_obstacleAhead = false;
    double m_obstacleDistance = 100.0;
    bool m_collisionWarning = false;
};
