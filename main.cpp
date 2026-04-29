#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "VehicleController.h"
#include "MediaController.h"
#include "BluetoothController.h"
#include "NavigationController.h"

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    qputenv("QT_LOGGING_RULES", "qt.network.http2=false");

    QGuiApplication app(argc, argv);

    VehicleController vehicleCtrl;
    MediaController mediaCtrl;
    BluetoothController btCtrl;
    NavigationController navCtrl;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("vehicleCtrl", &vehicleCtrl);
    engine.rootContext()->setContextProperty("mediaCtrl", &mediaCtrl);
    engine.rootContext()->setContextProperty("btCtrl", &btCtrl);
    engine.rootContext()->setContextProperty("navCtrl", &navCtrl);
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    qmlRegisterSingletonType(QUrl("qrc:/Style.qml"), "Style", 1, 0, "Style");
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
