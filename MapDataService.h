#pragma once

#include <QObject>
#include <QElapsedTimer>
#include <QHash>
#include <QPointer>
#include <QString>
#include <QStringList>
#include <QUrl>
#include <QVariantList>
#include <QtQml/qqml.h>

class QJsonObject;
class QNetworkAccessManager;
class QNetworkReply;
class QTimer;

class MapDataService : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString osrmHost READ osrmHost WRITE setOsrmHost NOTIFY serviceConfigChanged)
    Q_PROPERTY(QString geocodeHost READ geocodeHost WRITE setGeocodeHost NOTIFY serviceConfigChanged)
    Q_PROPERTY(QString geocodeProvider READ geocodeProvider WRITE setGeocodeProvider NOTIFY serviceConfigChanged)
    Q_PROPERTY(QString routeRequestState READ routeRequestState NOTIFY routeRequestStateChanged)
    Q_PROPERTY(QString lastRouteErrorCode READ lastRouteErrorCode NOTIFY routeRequestStateChanged)
    Q_PROPERTY(QString lastRouteErrorMessage READ lastRouteErrorMessage NOTIFY routeRequestStateChanged)
    Q_PROPERTY(int routeTimeoutMs READ routeTimeoutMs WRITE setRouteTimeoutMs NOTIFY serviceConfigChanged)
    Q_PROPERTY(int geocodeTimeoutMs READ geocodeTimeoutMs WRITE setGeocodeTimeoutMs NOTIFY serviceConfigChanged)
    Q_PROPERTY(int geocodeMinIntervalMs READ geocodeMinIntervalMs WRITE setGeocodeMinIntervalMs NOTIFY serviceConfigChanged)
    Q_PROPERTY(int geocodeFailureCooldownMs READ geocodeFailureCooldownMs WRITE setGeocodeFailureCooldownMs NOTIFY serviceConfigChanged)
    Q_PROPERTY(bool routeCacheEnabled READ routeCacheEnabled WRITE setRouteCacheEnabled NOTIFY serviceConfigChanged)
    Q_PROPERTY(int routeCacheSize READ routeCacheSize NOTIFY routeCacheChanged)

public:
    explicit MapDataService(QObject *parent = nullptr);
    ~MapDataService() override;

    QString osrmHost() const;
    QString geocodeHost() const;
    QString geocodeProvider() const;
    QString routeRequestState() const;
    QString lastRouteErrorCode() const;
    QString lastRouteErrorMessage() const;
    int routeTimeoutMs() const;
    int geocodeTimeoutMs() const;
    int geocodeMinIntervalMs() const;
    int geocodeFailureCooldownMs() const;
    bool routeCacheEnabled() const;
    int routeCacheSize() const;

public slots:
    // 请求 OSRM 路线；入参统一使用业务侧的 lat/lng，内部再转成 OSRM 需要的 lon,lat。
    void requestRoute(double startLat, double startLng, double endLat, double endLng);
    // 运行时切换 OSRM 服务地址；支持公共服务和本地 OSRM，例如 http://127.0.0.1:5000。
    void setOsrmHost(const QString &host);
    // 运行时切换地理编码服务；支持公共/本地 Nominatim 和 Photon。
    void setGeocodeHost(const QString &host);
    void setGeocodeProvider(const QString &provider);
    // 控制路线请求超时时间，避免公共网络抖动把 HMI 卡在“规划中”。
    void setRouteTimeoutMs(int timeoutMs);
    // 控制地点搜索和反向地理编码超时，避免公共 Nominatim 服务卡住交互。
    void setGeocodeTimeoutMs(int timeoutMs);
    // 限制 Nominatim 请求频率，连续输入时自动延迟最新一次请求。
    void setGeocodeMinIntervalMs(int intervalMs);
    // 公共服务失败后短暂冷却，避免弱网/限流时持续重试。
    void setGeocodeFailureCooldownMs(int cooldownMs);
    // 缓存相同起终点的规划结果，减少缩放/重算过程中的重复网络请求。
    void setRouteCacheEnabled(bool enabled);
    void clearRouteCache();
    // 请求地点搜索；nearLat/nearLng 用于优先返回车辆附近结果。
    void searchPlaces(const QString &query, double nearLat, double nearLng);
    // 点击地图选点后反查可读地址，用于更新目的地名称。
    void reverseGeocode(double lat, double lng);

signals:
    void routeReady(const QVariantList &options);
    // 兼容旧 QML：页面仍可以只关心可读错误文案。
    void routeFailed(const QString &message);
    // 新增结构化错误码，后续页面可以根据 timeout/http-error 等做更细的提示和重试入口。
    void routeFailedDetailed(const QString &code, const QString &message);
    void routeRequestStateChanged();
    void serviceConfigChanged();
    void routeCacheChanged();
    void searchCompleted(const QString &query, const QVariantList &results, bool success, const QString &message);
    void reverseGeocodeResolved(double lat, double lng, const QString &displayName);

private:
    // 解析 OSRM route JSON，输出 QML 友好的 QVariantList，避免 QML 直接处理复杂 JSON。
    QVariantList parseRouteOptions(const QJsonObject &root) const;
    QVariantList parseSearchResults(const QByteArray &payload,
                                    double nearLat,
                                    double nearLng,
                                    const QString &query) const;
    QString parseReverseDisplayName(const QByteArray &payload) const;
    QUrl buildRouteUrl(double startLat, double startLng, double endLat, double endLng) const;
    QString routeCacheKey(double startLat, double startLng, double endLat, double endLng) const;
    void storeRouteCache(const QString &cacheKey, const QVariantList &options);
    void setRouteRequestState(const QString &state,
                              const QString &errorCode = QString(),
                              const QString &errorMessage = QString());
    void finishRouteWithError(const QString &code, const QString &message);
    // nearbyBias=true 表示用当前位置给在线搜索排序加权；不再硬限制在附近，避免外地搜索失败。
    QUrl buildSearchUrl(const QString &query, double nearLat, double nearLng, bool nearbyBias) const;
    QUrl buildReverseUrl(double lat, double lng) const;
    void queueSearchRequest(const QString &query, double nearLat, double nearLng, bool nearbyBias);
    void startSearchRequest(const QString &query, double nearLat, double nearLng, bool nearbyBias);
    void dispatchPendingSearchRequest();
    void queueReverseRequest(double lat, double lng);
    void startReverseRequest(double lat, double lng);
    void dispatchPendingReverseRequest();

    void cancelRouteRequest();
    void cancelSearchRequest();
    void cancelReverseRequest();
    // 连续输入时取消旧请求，防止过期结果覆盖最新搜索内容。
    void cancelReply(QPointer<QNetworkReply> &reply);
    bool geocodeInFailureCooldown() const;
    int geocodeRateLimitDelayMs() const;
    void reserveGeocodeRequestSlot();
    void enterGeocodeFailureCooldown();

    QNetworkAccessManager *m_network = nullptr;
    QPointer<QNetworkReply> m_routeReply;
    QPointer<QNetworkReply> m_searchReply;
    QPointer<QNetworkReply> m_reverseReply;
    QPointer<QTimer> m_routeTimeoutTimer;
    QPointer<QTimer> m_searchTimeoutTimer;
    QPointer<QTimer> m_reverseTimeoutTimer;
    QPointer<QTimer> m_searchDelayTimer;
    QPointer<QTimer> m_reverseDelayTimer;
    QString m_osrmHost;
    QString m_geocodeHost;
    QString m_geocodeProvider;
    QString m_routeRequestState = QStringLiteral("idle");
    QString m_lastRouteErrorCode;
    QString m_lastRouteErrorMessage;
    int m_routeTimeoutMs = 9000;
    int m_geocodeTimeoutMs = 6000;
    int m_geocodeMinIntervalMs = 1100;
    int m_geocodeFailureCooldownMs = 10000;
    bool m_routeCacheEnabled = true;
    QHash<QString, QVariantList> m_routeCache;
    QStringList m_routeCacheOrder;
    QElapsedTimer m_clock;
    qint64 m_nextGeocodeAllowedAtMs = 0;
    qint64 m_geocodeFailureCooldownUntilMs = 0;
    QString m_pendingSearchQuery;
    double m_pendingSearchNearLat = 0.0;
    double m_pendingSearchNearLng = 0.0;
    bool m_pendingSearchNearbyBias = true;
    bool m_hasPendingSearch = false;
    double m_pendingReverseLat = 0.0;
    double m_pendingReverseLng = 0.0;
    bool m_hasPendingReverse = false;
};
