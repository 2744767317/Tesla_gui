#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QByteArray>
#include <QDir>
#include <QLibraryInfo>
#include <QQuickWindow>
#include <QSGRendererInterface>

#include "VehicleController.h"
#include "MediaController.h"
#include "BluetoothController.h"
#include "NavigationController.h"
#include "AutowareBridge.h"
#include "ADController.h"
#include "MapTileSettings.h"
#include "MapDataService.h"
#include "SearchStorage.h"

namespace {
QString qtPluginsPath()
{
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    return QLibraryInfo::path(QLibraryInfo::PluginsPath);
#else
    return QLibraryInfo::location(QLibraryInfo::PluginsPath);
#endif
}

bool hasPlatformInputContextPlugin(const QString &name)
{
    const QDir pluginDir(qtPluginsPath() + QStringLiteral("/platforminputcontexts"));
    return pluginDir.exists(QStringLiteral("lib%1platforminputcontextplugin.so").arg(name));
}

void configureLinuxInputMethod()
{
#if defined(Q_OS_LINUX)
    // Qt 只能使用自己插件目录里存在的输入法插件；本机 Qt 6.11 没有 fcitx 插件时，
    // 如果继续沿用 QT_IM_MODULE=fcitx，QML TextField 会退到 compose，表现为无法中文输入。
    const QByteArray requestedModule = qgetenv("QT_IM_MODULE").toLower();
    const bool fcitxRequested = requestedModule == "fcitx" || requestedModule == "fcitx5";
    const bool ibusAvailable = hasPlatformInputContextPlugin(QStringLiteral("ibus"));
    const bool fcitxAvailable = hasPlatformInputContextPlugin(QStringLiteral("fcitx"))
                                || hasPlatformInputContextPlugin(QStringLiteral("fcitx5"));

    if (qEnvironmentVariableIsEmpty("QT_IM_MODULE") || (fcitxRequested && !fcitxAvailable)) {
        if (ibusAvailable)
            qputenv("QT_IM_MODULE", "ibus");
        else if (hasPlatformInputContextPlugin(QStringLiteral("compose")))
            qputenv("QT_IM_MODULE", "xim");
    }
#endif
}
}

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#else
    // 部分 Linux/VM/老显卡环境在 Qt 6 默认 OpenGL RHI 下会直接启动失败，
    // 这里优先切到 software 后端，先保证 HMI 能稳定启动。
    QCoreApplication::setAttribute(Qt::AA_UseSoftwareOpenGL);
    if (qEnvironmentVariableIsEmpty("QSG_RHI_BACKEND"))
        qputenv("QSG_RHI_BACKEND", "software");
    if (qEnvironmentVariableIsEmpty("QT_QUICK_BACKEND"))
        qputenv("QT_QUICK_BACKEND", "software");
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
#endif
    // 公开 OSRM/Nominatim 服务偶发 HTTP/2 stream 异常，统一禁用可降低 Qt 网络层崩溃风险。
    qputenv("QT_LOGGING_RULES", "qt.network.http2=false");
    configureLinuxInputMethod();

    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("TeslaHMI"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("tesla-hmi.local"));
    QCoreApplication::setApplicationName(QStringLiteral("Tesla_Dashboard_UI"));
    // GeoClue/桌面门户依赖 desktop file name 识别应用，设置后可减少定位相关警告。
    QGuiApplication::setDesktopFileName(QStringLiteral("Tesla_Dashboard_UI"));

    VehicleController vehicleCtrl;
    MediaController mediaCtrl;
    BluetoothController btCtrl;
    NavigationController navCtrl;
    AutowareBridge autowareBridge;
    ADController adController;
    MapTileSettings mapTileSettings;
    MapDataService mapDataService;
    SearchStorage searchStorage;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("vehicleCtrl", &vehicleCtrl);
    engine.rootContext()->setContextProperty("mediaCtrl", &mediaCtrl);
    engine.rootContext()->setContextProperty("btCtrl", &btCtrl);
    engine.rootContext()->setContextProperty("navCtrl", &navCtrl);
    engine.rootContext()->setContextProperty("autowareBridge", &autowareBridge);
    engine.rootContext()->setContextProperty("adController", &adController);
    engine.rootContext()->setContextProperty("mapTileSettings", &mapTileSettings);
    engine.rootContext()->setContextProperty("mapDataService", &mapDataService);
    engine.rootContext()->setContextProperty("searchStorage", &searchStorage);
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
