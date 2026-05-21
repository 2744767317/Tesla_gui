#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <memory>

class MapTileSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString cacheDirectory READ cacheDirectory CONSTANT)
    Q_PROPERTY(QString offlineDirectory READ offlineDirectory CONSTANT)
    Q_PROPERTY(QString customTileHost READ customTileHost CONSTANT)
    Q_PROPERTY(QString onlineTileHost READ onlineTileHost CONSTANT)
    Q_PROPERTY(QString mapStyle READ mapStyle CONSTANT)
    Q_PROPERTY(QString mbtilesPath READ mbtilesPath CONSTANT)
    Q_PROPERTY(QString prefetchingStyle READ prefetchingStyle CONSTANT)
    Q_PROPERTY(QString tileSourceMode READ tileSourceMode CONSTANT)
    Q_PROPERTY(QString tileSourceLabel READ tileSourceLabel CONSTANT)
    Q_PROPERTY(QString tileSourceDetail READ tileSourceDetail CONSTANT)
    Q_PROPERTY(int diskCacheSizeBytes READ diskCacheSizeBytes CONSTANT)
    Q_PROPERTY(int memoryCacheSizeBytes READ memoryCacheSizeBytes CONSTANT)
    Q_PROPERTY(int textureCacheSizeBytes READ textureCacheSizeBytes CONSTANT)
    Q_PROPERTY(bool localTileServerEnabled READ localTileServerEnabled CONSTANT)

public:
    explicit MapTileSettings(QObject *parent = nullptr);
    ~MapTileSettings() override;

    QString cacheDirectory() const { return m_cacheDirectory; }
    QString offlineDirectory() const { return m_offlineDirectory; }
    QString customTileHost() const { return m_customTileHost; }
    QString onlineTileHost() const { return m_onlineTileHost; }
    QString mapStyle() const { return m_mapStyle; }
    QString mbtilesPath() const { return m_mbtilesPath; }
    QString prefetchingStyle() const { return m_prefetchingStyle; }
    QString tileSourceMode() const { return m_tileSourceMode; }
    QString tileSourceLabel() const { return m_tileSourceLabel; }
    QString tileSourceDetail() const { return m_tileSourceDetail; }
    int diskCacheSizeBytes() const { return m_diskCacheSizeBytes; }
    int memoryCacheSizeBytes() const { return m_memoryCacheSizeBytes; }
    int textureCacheSizeBytes() const { return m_textureCacheSizeBytes; }
    bool localTileServerEnabled() const { return m_localTileServerEnabled; }

private:
    static QString directoryFromEnvOrDefault(const char *envName,
                                             const QString &basePath,
                                             const QString &relativePath);
    static int cacheBytesFromEnvMb(const char *envName,
                                   int defaultMb,
                                   int minimumMb,
                                   int maximumMb);
    static QString findMbtilesServerScript();
    static QString normalizeTileHostForQt(const QString &host);
    static QString readMapStyleFromEnvironment();
    static QString tileHostForStyle(const QString &style);

    void configureMbtilesHost();
    void startLocalTileServer(int port);
    void updateTileSourceStatus();

    QString m_cacheDirectory;
    QString m_offlineDirectory;
    QString m_customTileHost;
    QString m_onlineTileHost;
    QString m_mapStyle;
    QString m_mbtilesPath;
    QString m_prefetchingStyle;
    QString m_tileSourceMode;
    QString m_tileSourceLabel;
    QString m_tileSourceDetail;
    int m_diskCacheSizeBytes = 0;
    int m_memoryCacheSizeBytes = 0;
    int m_textureCacheSizeBytes = 0;
    bool m_localTileServerEnabled = false;
    std::unique_ptr<QProcess> m_tileServerProcess;
};
