#include "VehicleController.h"
#include <QtMath>
#include <QRandomGenerator>

VehicleController::VehicleController(QObject *parent) : QObject(parent)
{
    m_timer.setInterval(100); // 10 Hz，用于模拟车辆状态连续变化。
    connect(&m_timer, &QTimer::timeout, this, &VehicleController::onTick);
    m_timer.start(); // 即使驻车也持续 tick，保证仪表温度/RPM 状态自然变化。
}

void VehicleController::toggleDriving()
{
    m_isDriving = !m_isDriving;
    if (m_isDriving) {
        m_targetSpeed = 120.0;
    } else {
        m_targetSpeed = 0.0;
    }
    emit isDrivingChanged();
    emit targetSpeedChanged();
}

void VehicleController::setTargetSpeed(double kmh)
{
    double boundedSpeed = qBound(0.0, kmh, 220.0);
    if (qFuzzyCompare(m_targetSpeed, boundedSpeed))
        return;

    m_targetSpeed = boundedSpeed;
    emit targetSpeedChanged();
}

void VehicleController::park()
{
    bool wasDriving = m_isDriving;
    m_isDriving = false;
    m_targetSpeed = 0.0;
    m_speed = 0.0;
    updateGear();
    emit targetSpeedChanged();
    emit speedChanged();
    if (wasDriving)
        emit isDrivingChanged();
}

void VehicleController::toggleDoor()
{
    m_warningDoor = !m_warningDoor;
    emit warningDoorChanged();
}

void VehicleController::toggleSeatbelt()
{
    m_warningSeatbelt = !m_warningSeatbelt;
    emit warningSeatbeltChanged();
}

void VehicleController::onTick()
{
    m_tickCount++;

    // 速度采用简单缓动模型，避免 UI 数值瞬间跳变。
    double speedDiff = m_targetSpeed - m_speed;
    double accel = m_isDriving ? 0.8 : 1.5; // 松开驾驶状态时减速更快。
    if (qAbs(speedDiff) < accel) {
        m_speed = m_targetSpeed;
    } else {
        m_speed += (speedDiff > 0 ? accel : -accel);
    }
    m_speed = qBound(0.0, m_speed, 220.0);
    emit speedChanged();

    // RPM 与速度/挡位弱关联，只用于 HMI 仪表模拟，不代表真实动力学。
    updateGear();
    double rpmTarget = 800.0;
    if (m_isDriving || m_speed > 0) {
        // rpm = base + speed * factor / gear
        rpmTarget = 800.0 + (m_speed * 30.0) / qMax(m_gear, 1);
        rpmTarget = qBound(700.0, rpmTarget, 8000.0);
    }
    double rpmDiff = rpmTarget - m_rpm;
    m_rpm += rpmDiff * 0.15;
    emit rpmChanged();

    // 温度缓慢趋近目标值，让左侧状态卡看起来更像连续车辆数据。
    double tempTarget = m_isDriving ? 90.0 : (m_speed > 0 ? 85.0 : 20.0);
    m_engineTemp += (tempTarget - m_engineTemp) * 0.002;
    emit engineTempChanged();

    // 行驶时缓慢掉电/掉油，作为 HMI 视觉演示数据源。
    if (m_isDriving && m_tickCount % 50 == 0) { // every 5s
        m_fuel = qMax(0.0, m_fuel - 0.1);
        emit fuelChanged();
    }

    // 告警保持轻量模拟，后续接 Autoware/车辆总线时可替换为真实信号。
    bool warnEng = (m_engineTemp > 110.0);
    if (warnEng != m_warningEngine) { m_warningEngine = warnEng; emit warningEngineChanged(); }

    bool warnBat = (m_tickCount % 1200 == 0); // blink every 2min
    if (warnBat && !m_warningBattery) {
        m_warningBattery = true; emit warningBatteryChanged();
        QTimer::singleShot(3000, this, [this]{ m_warningBattery = false; emit warningBatteryChanged(); });
    }

    bool warnOil = (m_fuel < 15.0);
    if (warnOil != m_warningOil) { m_warningOil = warnOil; emit warningOilChanged(); }
}

void VehicleController::updateGear()
{
    int newGear;
    if      (m_speed < 20)  newGear = 1;
    else if (m_speed < 40)  newGear = 2;
    else if (m_speed < 70)  newGear = 3;
    else if (m_speed < 100) newGear = 4;
    else if (m_speed < 140) newGear = 5;
    else                    newGear = 6;

    if (newGear != m_gear) {
        m_gear = newGear;
        emit gearChanged();
    }
}
