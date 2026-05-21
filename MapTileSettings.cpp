#include "MapTileSettings.h"

#include <QByteArray>
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QUrl>
#include <QUrlQuery>
#include <QtGlobal>
#include <QDebug>

namespace {
constexpr int kBytesPerMb = 1024 * 1024;
constexpr int kQtLocationSafeBytes = 2000 * kBytesPerMb;

int envIntOrDefault(const char *envName, int defaultValue)
{
    bool ok = false;
    const int configuredValue = QString::fromUtf8(qgetenv(envName)).trimmed().toInt(&ok);
    return ok ? configuredValue : defaultValue;
}
}

MapTileSettings::MapTileSettings(QObject *parent)
    : QObject(parent)
{
    // QML Settings 需要应用标识，但 Qt 会因此改变 CacheLocation。瓦片缓存继续使用旧目录，
    // 避免升级搜索历史功能后让已经缓存过的 OSM 瓦片重新下载。
    const QString cacheBasePath = QDir::homePath() + QStringLiteral("/.cache/Tesla_Dashboard_UI");
    const QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);

    m_mapStyle = readMapStyleFromEnvironment();
    m_onlineTileHost = tileHostForStyle(m_mapStyle);

    m_cacheDirectory = directoryFromEnvOrDefault("TESLA_MAP_CACHE_DIR",
                                                 cacheBasePath,
                                                 QStringLiteral("maptiles/%1-v1").arg(m_mapStyle));
    m_offlineDirectory = directoryFromEnvOrDefault("TESLA_MAP_OFFLINE_DIR",
                                                   appDataPath,
                                                   QStringLiteral("offline-tiles"));

    m_customTileHost = normalizeTileHostForQt(QString::fromUtf8(qgetenv("TESLA_MAP_TILE_HOST")).trimmed());
    m_mbtilesPath = QString::fromUtf8(qgetenv("TESLA_MAP_MBTILES")).trimmed();
    m_prefetchingStyle = QString::fromUtf8(qgetenv("TESLA_MAP_PREFETCH_STYLE")).trimmed();
    if (m_prefetchingStyle.isEmpty())
        m_prefetchingStyle = QStringLiteral("TwoNeighbourLayers");

    m_diskCacheSizeBytes = cacheBytesFromEnvMb("TESLA_MAP_DISK_CACHE_MB", 1536, 64, 2000);
    m_memoryCacheSizeBytes = cacheBytesFromEnvMb("TESLA_MAP_MEMORY_CACHE_MB", 192, 32, 1024);
    m_textureCacheSizeBytes = cacheBytesFromEnvMb("TESLA_MAP_TEXTURE_CACHE_MB", 384, 32, 1024);

    QDir().mkpath(m_cacheDirectory);
    QDir().mkpath(m_offlineDirectory);

    configureMbtilesHost();
    updateTileSourceStatus();

    qInfo().noquote()
        << "Map tile cache:" << m_cacheDirectory
        << "diskMB=" << (m_diskCacheSizeBytes / kBytesPerMb)
        << "memoryMB=" << (m_memoryCacheSizeBytes / kBytesPerMb)
        << "textureMB=" << (m_textureCacheSizeBytes / kBytesPerMb)
        << "source=" << m_tileSourceLabel
        << "style=" << m_mapStyle
        << "tileHost=" << (m_customTileHost.isEmpty() ? m_onlineTileHost : m_customTileHost);
}

MapTileSettings::~MapTileSettings()
{
    if (!m_tileServerProcess)
        return;

    m_tileServerProcess->terminate();
    if (!m_tileServerProcess->waitForFinished(1500))
        m_tileServerProcess->kill();
}

QString MapTileSettings::directoryFromEnvOrDefault(const char *envName,
                                                   const QString &basePath,
                                                   const QString &relativePath)
{
    const QString configuredPath = QString::fromUtf8(qgetenv(envName)).trimmed();
    if (!configuredPath.isEmpty()) {
        QDir().mkpath(configuredPath);
        return QDir(configuredPath).absolutePath();
    }

    const QString rootPath = basePath.isEmpty()
        ? QDir::homePath() + QStringLiteral("/.cache/Tesla_Dashboard_UI")
        : basePath;
    const QString resolvedPath = QDir(rootPath).filePath(relativePath);
    QDir().mkpath(resolvedPath);
    return QDir(resolvedPath).absolutePath();
}

int MapTileSettings::cacheBytesFromEnvMb(const char *envName,
                                         int defaultMb,
                                         int minimumMb,
                                         int maximumMb)
{
    const int safeMaximumMb = qMin(maximumMb, kQtLocationSafeBytes / kBytesPerMb);
    const int configuredMb = envIntOrDefault(envName, defaultMb);
    const int clampedMb = qBound(minimumMb, configuredMb, safeMaximumMb);

    return clampedMb * kBytesPerMb;
}

QString MapTileSettings::normalizeTileHostForQt(const QString &host)
{
    QString normalized = host.trimmed();
    if (normalized.isEmpty())
        return QString();

    const QStringList suffixes = {
        QStringLiteral("/%z/%x/%y.png"),
        QStringLiteral("/${z}/${x}/${y}.png"),
        QStringLiteral("/{z}/{x}/{y}.png"),
        QStringLiteral("/%z/%x/%y"),
        QStringLiteral("/${z}/${x}/${y}"),
        QStringLiteral("/{z}/{x}/{y}")
    };

    for (const QString &suffix : suffixes) {
        if (normalized.endsWith(suffix)) {
            normalized.chop(suffix.size());
            break;
        }
    }

    while (normalized.endsWith(QLatin1Char('/')))
        normalized.chop(1);

    return normalized + QLatin1Char('/');
}

QString MapTileSettings::readMapStyleFromEnvironment()
{
    QString style = QString::fromUtf8(qgetenv("TESLA_MAP_STYLE")).trimmed().toLower();
    if (style.isEmpty())
        style = QStringLiteral("carto-voyager");

    if (style == QStringLiteral("osm")
        || style == QStringLiteral("osm-standard")
        || style == QStringLiteral("carto-voyager")
        || style == QStringLiteral("carto-light")
        || style == QStringLiteral("carto-dark")) {
        return style;
    }

    qWarning().noquote() << "Unknown TESLA_MAP_STYLE, falling back to carto-voyager:" << style;
    return QStringLiteral("carto-voyager");
}

QString MapTileSettings::tileHostForStyle(const QString &style)
{
    if (style == QStringLiteral("osm") || style == QStringLiteral("osm-standard"))
        return QStringLiteral("https://tile.openstreetmap.org/");
    if (style == QStringLiteral("carto-light"))
        return QStringLiteral("https://basemaps.cartocdn.com/light_all/");
    if (style == QStringLiteral("carto-dark"))
        return QStringLiteral("https://basemaps.cartocdn.com/dark_all/");

    // Carto Voyager is still OSM-derived, but visually closer to modern in-car navigation.
    return QStringLiteral("https://basemaps.cartocdn.com/rastertiles/voyager/");
}

QString MapTileSettings::findMbtilesServerScript()
{
    const QString configuredScript = QString::fromUtf8(qgetenv("TESLA_MAP_MBTILES_SERVER")).trimmed();
    if (!configuredScript.isEmpty() && QFileInfo::exists(configuredScript))
        return QFileInfo(configuredScript).absoluteFilePath();

    const QString appDir = QCoreApplication::applicationDirPath();
    const QStringList candidates = {
        QDir(appDir).filePath(QStringLiteral("tools/mbtiles_tile_server.py")),
        QDir(appDir).filePath(QStringLiteral("../../tools/mbtiles_tile_server.py")),
        QDir(appDir).filePath(QStringLiteral("../../../tools/mbtiles_tile_server.py")),
        QDir::current().filePath(QStringLiteral("tools/mbtiles_tile_server.py")),
        QDir::current().filePath(QStringLiteral("../../tools/mbtiles_tile_server.py"))
    };

    for (const QString &candidate : candidates) {
        if (QFileInfo::exists(candidate))
            return QFileInfo(candidate).absoluteFilePath();
    }

    return QString();
}

void MapTileSettings::configureMbtilesHost()
{
    if (!m_customTileHost.isEmpty() || m_mbtilesPath.isEmpty())
        return;

    const QFileInfo mbtilesInfo(m_mbtilesPath);
    if (!mbtilesInfo.exists()) {
        qWarning().noquote() << "TESLA_MAP_MBTILES not found:" << m_mbtilesPath;
        return;
    }

    const int port = envIntOrDefault("TESLA_MAP_TILE_PORT", 8765);
    startLocalTileServer(port);
    if (m_localTileServerEnabled)
        m_customTileHost = QStringLiteral("http://127.0.0.1:%1/").arg(port);
}

void MapTileSettings::updateTileSourceStatus()
{
    if (m_localTileServerEnabled) {
        m_tileSourceMode = QStringLiteral("mbtiles");
        m_tileSourceLabel = QStringLiteral("MBTiles 离线源");
        m_tileSourceDetail = QFileInfo(m_mbtilesPath).fileName();
        return;
    }

    if (!m_mbtilesPath.isEmpty()) {
        m_tileSourceMode = QStringLiteral("mbtiles-error");
        m_tileSourceLabel = QStringLiteral("MBTiles 未启用");
        m_tileSourceDetail = QStringLiteral("检查文件或本地服务脚本");
        return;
    }

    if (!m_customTileHost.isEmpty()) {
        const QUrl hostUrl(m_customTileHost);
        const bool localHost = hostUrl.host() == QStringLiteral("127.0.0.1")
                               || hostUrl.host() == QStringLiteral("localhost");
        m_tileSourceMode = localHost ? QStringLiteral("local") : QStringLiteral("custom");
        m_tileSourceLabel = localHost ? QStringLiteral("本地瓦片服务") : QStringLiteral("自定义在线瓦片");
        m_tileSourceDetail = hostUrl.host().isEmpty() ? m_customTileHost : hostUrl.host();
        return;
    }

    m_tileSourceMode = QStringLiteral("online-cache");
    m_tileSourceLabel = QStringLiteral("免费 OSM 车机风格");
    m_tileSourceDetail = QStringLiteral("%1，缓存已启用").arg(m_onlineTileHost);
}

void MapTileSettings::startLocalTileServer(int port)
{
    const QString scriptPath = findMbtilesServerScript();
    if (scriptPath.isEmpty()) {
        qWarning() << "MBTiles tile server script not found. Set TESLA_MAP_MBTILES_SERVER.";
        return;
    }

    const QString python = QStandardPaths::findExecutable(QStringLiteral("python3"));
    if (python.isEmpty()) {
        qWarning() << "python3 not found, cannot start MBTiles tile server.";
        return;
    }

    m_tileServerProcess = std::make_unique<QProcess>();
    m_tileServerProcess->setProgram(python);
    m_tileServerProcess->setArguments({
        scriptPath,
        m_mbtilesPath,
        QStringLiteral("--port"),
        QString::number(port)
    });

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("PYTHONUNBUFFERED"), QStringLiteral("1"));
    m_tileServerProcess->setProcessEnvironment(environment);

    QObject::connect(m_tileServerProcess.get(), &QProcess::readyReadStandardOutput, [this]() {
        qInfo().noquote() << QString::fromUtf8(m_tileServerProcess->readAllStandardOutput()).trimmed();
    });
    QObject::connect(m_tileServerProcess.get(), &QProcess::readyReadStandardError, [this]() {
        qWarning().noquote() << QString::fromUtf8(m_tileServerProcess->readAllStandardError()).trimmed();
    });
    QObject::connect(m_tileServerProcess.get(), &QProcess::errorOccurred, [](QProcess::ProcessError error) {
        qWarning() << "MBTiles tile server process error:" << error;
    });

    m_tileServerProcess->start();
    if (m_tileServerProcess->waitForStarted(2000)) {
        m_localTileServerEnabled = true;
        qInfo().noquote() << "MBTiles tile server started for" << m_mbtilesPath;
        return;
    }

    qWarning() << "Failed to start MBTiles tile server.";
    m_tileServerProcess.reset();
}
