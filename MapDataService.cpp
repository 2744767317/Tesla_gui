#include "MapDataService.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QElapsedTimer>
#include <QTimer>
#include <QUrl>
#include <QUrlQuery>
#include <algorithm>
#include <cmath>

namespace {
constexpr double kMetersPerMile = 1609.344;
constexpr double kEarthRadiusMeters = 6371000.0;
constexpr double kPi = 3.14159265358979323846;
constexpr int kDefaultRouteTimeoutMs = 9000;
constexpr int kDefaultGeocodeTimeoutMs = 6000;
constexpr int kDefaultGeocodeMinIntervalMs = 1100;
constexpr int kDefaultGeocodeFailureCooldownMs = 10000;
constexpr int kMinRouteTimeoutMs = 1500;
constexpr int kMaxRouteTimeoutMs = 30000;
constexpr int kMinGeocodeTimeoutMs = 1500;
constexpr int kMaxGeocodeTimeoutMs = 20000;
constexpr int kMinGeocodeMinIntervalMs = 250;
constexpr int kMaxGeocodeMinIntervalMs = 5000;
constexpr int kMinGeocodeFailureCooldownMs = 1000;
constexpr int kMaxGeocodeFailureCooldownMs = 60000;
constexpr int kMaxRouteCacheEntries = 24;
const QString kDefaultOsrmHost = QStringLiteral("https://router.project-osrm.org");
const QString kDefaultNominatimHost = QStringLiteral("https://nominatim.openstreetmap.org");
const QString kDefaultPhotonHost = QStringLiteral("https://photon.komoot.io");
const QString kProviderNominatim = QStringLiteral("nominatim");
const QString kProviderPhoton = QStringLiteral("photon");

// Haversine 距离用于给 Nominatim 返回的多个地点做“离当前车辆更近”的排序。
double degreesToRadians(double value)
{
    return value * kPi / 180.0;
}

double distanceMeters(double lat1, double lon1, double lat2, double lon2)
{
    const double dLat = degreesToRadians(lat2 - lat1);
    const double dLon = degreesToRadians(lon2 - lon1);
    const double fromLat = degreesToRadians(lat1);
    const double toLat = degreesToRadians(lat2);
    const double a = std::sin(dLat / 2.0) * std::sin(dLat / 2.0)
                     + std::cos(fromLat) * std::cos(toLat)
                           * std::sin(dLon / 2.0) * std::sin(dLon / 2.0);
    const double c = 2.0 * std::atan2(std::sqrt(a), std::sqrt(1.0 - a));
    return kEarthRadiusMeters * c;
}

bool isValidCoordinate(double lat, double lon)
{
    return std::isfinite(lat) && std::isfinite(lon)
           && lat >= -90.0 && lat <= 90.0
           && lon >= -180.0 && lon <= 180.0;
}

QString normalizeOsrmHost(const QString &host)
{
    QString normalized = host.trimmed();
    if (normalized.isEmpty())
        normalized = kDefaultOsrmHost;

    if (!normalized.startsWith(QStringLiteral("http://"), Qt::CaseInsensitive)
        && !normalized.startsWith(QStringLiteral("https://"), Qt::CaseInsensitive)) {
        normalized.prepend(QStringLiteral("http://"));
    }

    while (normalized.endsWith(QLatin1Char('/')))
        normalized.chop(1);

    return normalized.isEmpty() ? kDefaultOsrmHost : normalized;
}

QString normalizeServiceHost(const QString &host, const QString &defaultHost)
{
    QString normalized = host.trimmed();
    if (normalized.isEmpty())
        normalized = defaultHost;

    if (!normalized.startsWith(QStringLiteral("http://"), Qt::CaseInsensitive)
        && !normalized.startsWith(QStringLiteral("https://"), Qt::CaseInsensitive)) {
        normalized.prepend(QStringLiteral("http://"));
    }

    while (normalized.endsWith(QLatin1Char('/')))
        normalized.chop(1);

    return normalized.isEmpty() ? defaultHost : normalized;
}

QString readOsrmHostFromEnvironment()
{
    const QString teslaHost = QString::fromLocal8Bit(qgetenv("TESLA_OSRM_HOST")).trimmed();
    if (!teslaHost.isEmpty())
        return normalizeOsrmHost(teslaHost);

    return normalizeOsrmHost(QString::fromLocal8Bit(qgetenv("OSRM_HOST")));
}

QString readGeocodeHostFromEnvironment()
{
    const QString geocodeHost = QString::fromLocal8Bit(qgetenv("TESLA_GEOCODE_HOST")).trimmed();
    if (!geocodeHost.isEmpty())
        return normalizeServiceHost(geocodeHost, kDefaultNominatimHost);

    const QString photonHost = QString::fromLocal8Bit(qgetenv("TESLA_PHOTON_HOST")).trimmed();
    if (!photonHost.isEmpty())
        return normalizeServiceHost(photonHost, kDefaultPhotonHost);

    const QString teslaNominatimHost = QString::fromLocal8Bit(qgetenv("TESLA_NOMINATIM_HOST")).trimmed();
    if (!teslaNominatimHost.isEmpty())
        return normalizeServiceHost(teslaNominatimHost, kDefaultNominatimHost);

    return normalizeServiceHost(QString::fromLocal8Bit(qgetenv("NOMINATIM_HOST")), kDefaultNominatimHost);
}

QString normalizeGeocodeProvider(const QString &provider, const QString &host)
{
    const QString normalized = provider.trimmed().toLower();
    if (normalized == kProviderNominatim || normalized == kProviderPhoton)
        return normalized;

    const QString normalizedHost = host.toLower();
    if (normalizedHost.contains(QStringLiteral("photon")))
        return kProviderPhoton;

    return kProviderNominatim;
}

QString readGeocodeProviderFromEnvironment(const QString &host)
{
    const QString teslaProvider = QString::fromLocal8Bit(qgetenv("TESLA_GEOCODE_PROVIDER")).trimmed();
    if (!teslaProvider.isEmpty())
        return normalizeGeocodeProvider(teslaProvider, host);

    const QString provider = QString::fromLocal8Bit(qgetenv("GEOCODE_PROVIDER")).trimmed();
    if (!provider.isEmpty())
        return normalizeGeocodeProvider(provider, host);

    if (!QString::fromLocal8Bit(qgetenv("TESLA_PHOTON_HOST")).trimmed().isEmpty())
        return kProviderPhoton;

    return normalizeGeocodeProvider(QString(), host);
}

int readRouteTimeoutFromEnvironment()
{
    bool ok = false;
    int timeoutMs = qEnvironmentVariableIntValue("TESLA_ROUTE_TIMEOUT_MS", &ok);
    if (!ok)
        timeoutMs = qEnvironmentVariableIntValue("OSRM_TIMEOUT_MS", &ok);
    if (!ok)
        timeoutMs = kDefaultRouteTimeoutMs;

    return std::clamp(timeoutMs, kMinRouteTimeoutMs, kMaxRouteTimeoutMs);
}

int readGeocodeTimeoutFromEnvironment()
{
    bool ok = false;
    int timeoutMs = qEnvironmentVariableIntValue("TESLA_GEOCODE_TIMEOUT_MS", &ok);
    if (!ok)
        timeoutMs = qEnvironmentVariableIntValue("NOMINATIM_TIMEOUT_MS", &ok);
    if (!ok)
        timeoutMs = kDefaultGeocodeTimeoutMs;

    return std::clamp(timeoutMs, kMinGeocodeTimeoutMs, kMaxGeocodeTimeoutMs);
}

int readGeocodeMinIntervalFromEnvironment()
{
    bool ok = false;
    int intervalMs = qEnvironmentVariableIntValue("TESLA_GEOCODE_MIN_INTERVAL_MS", &ok);
    if (!ok)
        intervalMs = qEnvironmentVariableIntValue("NOMINATIM_MIN_INTERVAL_MS", &ok);
    if (!ok)
        intervalMs = kDefaultGeocodeMinIntervalMs;

    return std::clamp(intervalMs, kMinGeocodeMinIntervalMs, kMaxGeocodeMinIntervalMs);
}

int readGeocodeFailureCooldownFromEnvironment()
{
    bool ok = false;
    int cooldownMs = qEnvironmentVariableIntValue("TESLA_GEOCODE_FAILURE_COOLDOWN_MS", &ok);
    if (!ok)
        cooldownMs = qEnvironmentVariableIntValue("NOMINATIM_FAILURE_COOLDOWN_MS", &ok);
    if (!ok)
        cooldownMs = kDefaultGeocodeFailureCooldownMs;

    return std::clamp(cooldownMs, kMinGeocodeFailureCooldownMs, kMaxGeocodeFailureCooldownMs);
}

bool readRouteCacheEnabledFromEnvironment()
{
    const QString rawValue = qEnvironmentVariable("TESLA_ROUTE_CACHE_ENABLED").trimmed().toLower();
    if (rawValue.isEmpty())
        return true;

    return !(rawValue == QStringLiteral("0")
             || rawValue == QStringLiteral("false")
             || rawValue == QStringLiteral("off")
             || rawValue == QStringLiteral("no"));
}

QString routeErrorMessageFromOsrmCode(const QString &code)
{
    if (code == QStringLiteral("NoRoute"))
        return QStringLiteral("OSRM 未找到可通行路线");
    if (code == QStringLiteral("NoSegment"))
        return QStringLiteral("起点或终点附近没有可用道路");
    if (code == QStringLiteral("InvalidUrl")
        || code == QStringLiteral("InvalidService")
        || code == QStringLiteral("InvalidVersion")
        || code == QStringLiteral("InvalidOptions")
        || code == QStringLiteral("InvalidQuery")) {
        return QStringLiteral("路线请求参数无效");
    }

    return QStringLiteral("路线服务返回异常");
}

// 分数越低越靠前：名称直接命中要明显优先于仅靠距离/importance 的泛匹配。
double textMatchBonus(const QString &query, const QString &displayName)
{
    const QString normalizedQuery = query.trimmed().toLower();
    const QString normalizedName = displayName.toLower();
    if (normalizedQuery.isEmpty())
        return 0.0;
    if (normalizedName.startsWith(normalizedQuery))
        return -800.0;
    if (normalizedName.contains(normalizedQuery))
        return -500.0;
    return 0.0;
}

// 中文 POI 容易被 Nominatim 模糊成“某某大厦”，需要先判断查询里是否真的包含中文。
bool hasCjkText(const QString &text)
{
    for (const QChar character : text) {
        const ushort code = character.unicode();
        if (code >= 0x4E00 && code <= 0x9FFF)
            return true;
    }
    return false;
}

// 计算最长公共连续子串，用来过滤“秦创原大厦 -> 秦皇岛建设大厦”这类弱匹配。
int maxCommonSubstringLength(const QString &left, const QString &right)
{
    int best = 0;
    for (int leftIndex = 0; leftIndex < left.size(); ++leftIndex) {
        for (int rightIndex = 0; rightIndex < right.size(); ++rightIndex) {
            int length = 0;
            while (leftIndex + length < left.size()
                   && rightIndex + length < right.size()
                   && left.at(leftIndex + length) == right.at(rightIndex + length)) {
                ++length;
            }
            best = std::max(best, length);
        }
    }
    return best;
}

// 对较长中文查询做保守过滤：宁可提示未找到，也不要把路线规划到错误城市。
bool isStrongEnoughTextMatch(const QString &query, const QString &displayName)
{
    const QString normalizedQuery = query.trimmed().toLower();
    const QString normalizedName = displayName.toLower();
    if (normalizedQuery.size() < 4 || !hasCjkText(normalizedQuery))
        return true;

    if (normalizedName.contains(normalizedQuery))
        return true;

    return maxCommonSubstringLength(normalizedQuery, normalizedName) >= 3;
}

QNetworkRequest buildRequest(const QUrl &url)
{
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    // Qt 6 + 公共地图服务偶发 HTTP/2 HEADERS stream 错误，这里强制 HTTP/1.1 更稳。
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    request.setRawHeader("User-Agent", "TeslaDashboardUI/1.0");
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.7");
    return request;
}

QVariantList parseStepList(const QJsonArray &legs)
{
    QVariantList steps;

    // OSRM 的 steps 很细，QML 层只需要转向类型、道路名、距离和时间。
    for (const QJsonValue &legValue : legs) {
        const QJsonArray legSteps = legValue.toObject().value(QStringLiteral("steps")).toArray();
        for (const QJsonValue &stepValue : legSteps) {
            const QJsonObject stepObject = stepValue.toObject();
            const QJsonObject maneuverObject = stepObject.value(QStringLiteral("maneuver")).toObject();

            QVariantMap step;
            step.insert(QStringLiteral("type"), maneuverObject.value(QStringLiteral("type")).toString());
            step.insert(QStringLiteral("modifier"), maneuverObject.value(QStringLiteral("modifier")).toString());
            step.insert(QStringLiteral("street"), stepObject.value(QStringLiteral("name")).toString());
            step.insert(QStringLiteral("distanceMiles"),
                        stepObject.value(QStringLiteral("distance")).toDouble() / kMetersPerMile);
            step.insert(QStringLiteral("durationMinutes"),
                        stepObject.value(QStringLiteral("duration")).toDouble() / 60.0);
            steps.push_back(step);
        }
    }

    return steps;
}
}

MapDataService::MapDataService(QObject *parent)
    : QObject(parent)
    , m_network(new QNetworkAccessManager(this))
    , m_routeTimeoutTimer(new QTimer(this))
    , m_searchTimeoutTimer(new QTimer(this))
    , m_reverseTimeoutTimer(new QTimer(this))
    , m_searchDelayTimer(new QTimer(this))
    , m_reverseDelayTimer(new QTimer(this))
    , m_osrmHost(readOsrmHostFromEnvironment())
    , m_geocodeHost(readGeocodeHostFromEnvironment())
    , m_geocodeProvider(readGeocodeProviderFromEnvironment(m_geocodeHost))
    , m_routeTimeoutMs(readRouteTimeoutFromEnvironment())
    , m_geocodeTimeoutMs(readGeocodeTimeoutFromEnvironment())
    , m_geocodeMinIntervalMs(readGeocodeMinIntervalFromEnvironment())
    , m_geocodeFailureCooldownMs(readGeocodeFailureCooldownFromEnvironment())
    , m_routeCacheEnabled(readRouteCacheEnabledFromEnvironment())
{
    m_clock.start();

    if (m_geocodeProvider == kProviderPhoton && m_geocodeHost == kDefaultNominatimHost)
        m_geocodeHost = kDefaultPhotonHost;

    m_routeTimeoutTimer->setSingleShot(true);
    connect(m_routeTimeoutTimer, &QTimer::timeout, this, [this]() {
        if (!m_routeReply)
            return;

        // 给当前 reply 打上超时标记；finished 阶段再统一走错误收口，避免重复 emit。
        m_routeReply->setProperty("teslaRouteTimedOut", true);
        m_routeReply->abort();
    });

    m_searchTimeoutTimer->setSingleShot(true);
    connect(m_searchTimeoutTimer, &QTimer::timeout, this, [this]() {
        if (!m_searchReply)
            return;

        m_searchReply->setProperty("teslaSearchTimedOut", true);
        m_searchReply->abort();
    });

    m_reverseTimeoutTimer->setSingleShot(true);
    connect(m_reverseTimeoutTimer, &QTimer::timeout, this, [this]() {
        if (!m_reverseReply)
            return;

        m_reverseReply->setProperty("teslaReverseTimedOut", true);
        m_reverseReply->abort();
    });

    m_searchDelayTimer->setSingleShot(true);
    connect(m_searchDelayTimer, &QTimer::timeout, this, &MapDataService::dispatchPendingSearchRequest);

    m_reverseDelayTimer->setSingleShot(true);
    connect(m_reverseDelayTimer, &QTimer::timeout, this, &MapDataService::dispatchPendingReverseRequest);
}

MapDataService::~MapDataService()
{
    cancelRouteRequest();
    cancelSearchRequest();
    cancelReverseRequest();
}

QString MapDataService::osrmHost() const
{
    return m_osrmHost;
}

QString MapDataService::geocodeHost() const
{
    return m_geocodeHost;
}

QString MapDataService::geocodeProvider() const
{
    return m_geocodeProvider;
}

QString MapDataService::routeRequestState() const
{
    return m_routeRequestState;
}

QString MapDataService::lastRouteErrorCode() const
{
    return m_lastRouteErrorCode;
}

QString MapDataService::lastRouteErrorMessage() const
{
    return m_lastRouteErrorMessage;
}

int MapDataService::routeTimeoutMs() const
{
    return m_routeTimeoutMs;
}

int MapDataService::geocodeTimeoutMs() const
{
    return m_geocodeTimeoutMs;
}

int MapDataService::geocodeMinIntervalMs() const
{
    return m_geocodeMinIntervalMs;
}

int MapDataService::geocodeFailureCooldownMs() const
{
    return m_geocodeFailureCooldownMs;
}

bool MapDataService::routeCacheEnabled() const
{
    return m_routeCacheEnabled;
}

int MapDataService::routeCacheSize() const
{
    return m_routeCache.size();
}

void MapDataService::requestRoute(double startLat, double startLng, double endLat, double endLng)
{
    cancelRouteRequest();

    if (!isValidCoordinate(startLat, startLng) || !isValidCoordinate(endLat, endLng)) {
        finishRouteWithError(QStringLiteral("invalid-coordinate"), QStringLiteral("起点或终点坐标无效"));
        return;
    }

    const QString cacheKey = routeCacheKey(startLat, startLng, endLat, endLng);
    if (m_routeCacheEnabled && m_routeCache.contains(cacheKey)) {
        setRouteRequestState(QStringLiteral("cached"));
        emit routeReady(m_routeCache.value(cacheKey));
        return;
    }

    m_routeReply = m_network->get(buildRequest(buildRouteUrl(startLat, startLng, endLat, endLng)));
    QPointer<QNetworkReply> reply = m_routeReply;
    reply->setProperty("teslaRouteCacheKey", cacheKey);
    m_routeTimeoutTimer->start(m_routeTimeoutMs);
    setRouteRequestState(QStringLiteral("loading"));

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (!reply)
            return;

        const bool isActiveRouteReply = m_routeReply == reply;
        if (isActiveRouteReply && m_routeTimeoutTimer)
            m_routeTimeoutTimer->stop();

        if (isActiveRouteReply)
            m_routeReply = nullptr;

        const QNetworkReply::NetworkError errorCode = reply->error();
        const bool timedOut = reply->property("teslaRouteTimedOut").toBool();
        const bool silentCancel = reply->property("teslaRouteSilentCancel").toBool();
        if (errorCode == QNetworkReply::OperationCanceledError) {
            reply->deleteLater();
            if (silentCancel)
                return;

            if (timedOut) {
                finishRouteWithError(QStringLiteral("timeout"),
                                     QStringLiteral("路线请求超时，请检查网络或切换本地 OSRM"));
            } else {
                setRouteRequestState(QStringLiteral("cancelled"),
                                     QStringLiteral("cancelled"),
                                     QStringLiteral("路线请求已取消"));
            }
            return;
        }

        if (errorCode != QNetworkReply::NoError) {
            const QString message = reply->errorString().trimmed();
            reply->deleteLater();
            finishRouteWithError(QStringLiteral("network-error"),
                                 message.isEmpty() ? QStringLiteral("路线服务暂不可用")
                                                   : QStringLiteral("路线服务不可用：%1").arg(message));
            return;
        }

        const QByteArray payload = reply->isOpen() ? reply->readAll() : QByteArray();
        const int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        reply->deleteLater();

        if (httpStatus >= 400) {
            finishRouteWithError(QStringLiteral("http-error"),
                                 QStringLiteral("路线服务返回 HTTP %1").arg(httpStatus));
            return;
        }

        QJsonParseError parseError;
        const QJsonDocument document = QJsonDocument::fromJson(payload, &parseError);
        if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
            finishRouteWithError(QStringLiteral("parse-error"),
                                 QStringLiteral("路线数据解析失败"));
            return;
        }

        const QJsonObject root = document.object();
        const QString serviceCode = root.value(QStringLiteral("code")).toString();
        if (!serviceCode.isEmpty() && serviceCode != QStringLiteral("Ok")) {
            const QString message = root.value(QStringLiteral("message")).toString().trimmed();
            finishRouteWithError(QStringLiteral("service-error"),
                                 message.isEmpty()
                                     ? routeErrorMessageFromOsrmCode(serviceCode)
                                     : QStringLiteral("%1：%2").arg(routeErrorMessageFromOsrmCode(serviceCode), message));
            return;
        }

        const QVariantList options = parseRouteOptions(root);
        if (options.isEmpty()) {
            finishRouteWithError(QStringLiteral("empty-route"), QStringLiteral("未找到可用路线"));
            return;
        }

        storeRouteCache(reply->property("teslaRouteCacheKey").toString(), options);
        setRouteRequestState(QStringLiteral("ready"));
        emit routeReady(options);
    });
}

void MapDataService::setOsrmHost(const QString &host)
{
    const QString normalizedHost = normalizeOsrmHost(host);
    if (m_osrmHost == normalizedHost)
        return;

    cancelRouteRequest();
    m_osrmHost = normalizedHost;
    clearRouteCache();
    setRouteRequestState(QStringLiteral("idle"));
    emit serviceConfigChanged();
}

void MapDataService::setGeocodeHost(const QString &host)
{
    const QString normalizedHost = normalizeServiceHost(host, kDefaultNominatimHost);
    if (m_geocodeHost == normalizedHost)
        return;

    cancelSearchRequest();
    cancelReverseRequest();
    m_geocodeHost = normalizedHost;
    m_geocodeProvider = normalizeGeocodeProvider(m_geocodeProvider, m_geocodeHost);
    m_geocodeFailureCooldownUntilMs = 0;
    emit serviceConfigChanged();
}

void MapDataService::setGeocodeProvider(const QString &provider)
{
    const QString normalizedProvider = normalizeGeocodeProvider(provider, m_geocodeHost);
    if (m_geocodeProvider == normalizedProvider)
        return;

    cancelSearchRequest();
    cancelReverseRequest();
    m_geocodeProvider = normalizedProvider;
    if (m_geocodeHost == kDefaultNominatimHost && m_geocodeProvider == kProviderPhoton)
        m_geocodeHost = kDefaultPhotonHost;
    m_geocodeFailureCooldownUntilMs = 0;
    emit serviceConfigChanged();
}

void MapDataService::setRouteTimeoutMs(int timeoutMs)
{
    const int clampedTimeout = std::clamp(timeoutMs, kMinRouteTimeoutMs, kMaxRouteTimeoutMs);
    if (m_routeTimeoutMs == clampedTimeout)
        return;

    m_routeTimeoutMs = clampedTimeout;
    if (m_routeReply && m_routeTimeoutTimer)
        m_routeTimeoutTimer->start(m_routeTimeoutMs);
    emit serviceConfigChanged();
}

void MapDataService::setGeocodeTimeoutMs(int timeoutMs)
{
    const int clampedTimeout = std::clamp(timeoutMs, kMinGeocodeTimeoutMs, kMaxGeocodeTimeoutMs);
    if (m_geocodeTimeoutMs == clampedTimeout)
        return;

    m_geocodeTimeoutMs = clampedTimeout;
    if (m_searchReply && m_searchTimeoutTimer)
        m_searchTimeoutTimer->start(m_geocodeTimeoutMs);
    if (m_reverseReply && m_reverseTimeoutTimer)
        m_reverseTimeoutTimer->start(m_geocodeTimeoutMs);
    emit serviceConfigChanged();
}

void MapDataService::setGeocodeMinIntervalMs(int intervalMs)
{
    const int clampedInterval = std::clamp(intervalMs, kMinGeocodeMinIntervalMs, kMaxGeocodeMinIntervalMs);
    if (m_geocodeMinIntervalMs == clampedInterval)
        return;

    m_geocodeMinIntervalMs = clampedInterval;
    emit serviceConfigChanged();
}

void MapDataService::setGeocodeFailureCooldownMs(int cooldownMs)
{
    const int clampedCooldown = std::clamp(cooldownMs,
                                          kMinGeocodeFailureCooldownMs,
                                          kMaxGeocodeFailureCooldownMs);
    if (m_geocodeFailureCooldownMs == clampedCooldown)
        return;

    m_geocodeFailureCooldownMs = clampedCooldown;
    emit serviceConfigChanged();
}

void MapDataService::setRouteCacheEnabled(bool enabled)
{
    if (m_routeCacheEnabled == enabled)
        return;

    m_routeCacheEnabled = enabled;
    if (!m_routeCacheEnabled)
        clearRouteCache();
    emit serviceConfigChanged();
}

void MapDataService::clearRouteCache()
{
    if (m_routeCache.isEmpty() && m_routeCacheOrder.isEmpty())
        return;

    m_routeCache.clear();
    m_routeCacheOrder.clear();
    emit routeCacheChanged();
}

void MapDataService::searchPlaces(const QString &queryText, double nearLat, double nearLng)
{
    const QString query = queryText.trimmed();
    if (query.length() < 2) {
        emit searchCompleted(query, {}, false, QStringLiteral("请输入至少两个字符"));
        return;
    }

    // 在线服务只用当前位置做排序提示，不硬限制范围；中文用户经常搜索外地目的地。
    queueSearchRequest(query, nearLat, nearLng, true);
}

QUrl MapDataService::buildSearchUrl(const QString &query, double nearLat, double nearLng, bool nearbyBias) const
{
    const bool photon = m_geocodeProvider == kProviderPhoton;
    QUrl url(photon
             ? QStringLiteral("%1/api/").arg(m_geocodeHost)
             : QStringLiteral("%1/search").arg(m_geocodeHost));
    QUrlQuery queryItems;
    queryItems.addQueryItem(QStringLiteral("q"), query);
    queryItems.addQueryItem(QStringLiteral("limit"), QStringLiteral("8"));

    if (photon) {
        // Photon public service only supports default/de/en/fr. Omit lang so local
        // names from OSM are returned when available; QML then localizes common names.
        if (isValidCoordinate(nearLat, nearLng) && nearbyBias) {
            queryItems.addQueryItem(QStringLiteral("lat"), QString::number(nearLat, 'f', 6));
            queryItems.addQueryItem(QStringLiteral("lon"), QString::number(nearLng, 'f', 6));
        }
    } else {
        const double viewBoxDelta = 2.5;
        queryItems.addQueryItem(QStringLiteral("format"), QStringLiteral("jsonv2"));
        queryItems.addQueryItem(QStringLiteral("addressdetails"), QStringLiteral("1"));
        queryItems.addQueryItem(QStringLiteral("countrycodes"), QStringLiteral("cn"));
        queryItems.addQueryItem(QStringLiteral("accept-language"), QStringLiteral("zh-CN,zh,en"));
        queryItems.addQueryItem(QStringLiteral("dedupe"), QStringLiteral("1"));
        if (isValidCoordinate(nearLat, nearLng) && nearbyBias) {
            // viewbox without bounded=1 biases nearby results but still allows national search.
            queryItems.addQueryItem(QStringLiteral("viewbox"),
                                    QStringLiteral("%1,%2,%3,%4")
                                        .arg(nearLng - viewBoxDelta, 0, 'f', 6)
                                        .arg(nearLat + viewBoxDelta, 0, 'f', 6)
                                        .arg(nearLng + viewBoxDelta, 0, 'f', 6)
                                        .arg(nearLat - viewBoxDelta, 0, 'f', 6));
        }
    }
    url.setQuery(queryItems);
    return url;
}

QUrl MapDataService::buildReverseUrl(double lat, double lng) const
{
    if (m_geocodeProvider == kProviderPhoton) {
        QUrl url(QStringLiteral("%1/reverse").arg(m_geocodeHost));
        QUrlQuery query;
        query.addQueryItem(QStringLiteral("lat"), QString::number(lat, 'f', 6));
        query.addQueryItem(QStringLiteral("lon"), QString::number(lng, 'f', 6));
        query.addQueryItem(QStringLiteral("limit"), QStringLiteral("1"));
        url.setQuery(query);
        return url;
    }

    QUrl url(QStringLiteral("%1/reverse").arg(m_geocodeHost));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("format"), QStringLiteral("jsonv2"));
    query.addQueryItem(QStringLiteral("addressdetails"), QStringLiteral("1"));
    query.addQueryItem(QStringLiteral("zoom"), QStringLiteral("18"));
    query.addQueryItem(QStringLiteral("lat"), QString::number(lat, 'f', 6));
    query.addQueryItem(QStringLiteral("lon"), QString::number(lng, 'f', 6));
    url.setQuery(query);
    return url;
}

void MapDataService::queueSearchRequest(const QString &query, double nearLat, double nearLng, bool nearbyBias)
{
    cancelSearchRequest();

    if (geocodeInFailureCooldown()) {
        emit searchCompleted(query, {}, false, QStringLiteral("在线搜索冷却中，使用本地匹配"));
        return;
    }

    m_pendingSearchQuery = query;
    m_pendingSearchNearLat = nearLat;
    m_pendingSearchNearLng = nearLng;
    m_pendingSearchNearbyBias = nearbyBias;
    m_hasPendingSearch = true;
    dispatchPendingSearchRequest();
}

void MapDataService::dispatchPendingSearchRequest()
{
    if (!m_hasPendingSearch || m_searchReply)
        return;

    if (geocodeInFailureCooldown()) {
        const QString query = m_pendingSearchQuery;
        m_hasPendingSearch = false;
        emit searchCompleted(query, {}, false, QStringLiteral("在线搜索冷却中，使用本地匹配"));
        return;
    }

    const int delayMs = geocodeRateLimitDelayMs();
    if (delayMs > 0) {
        if (m_searchDelayTimer)
            m_searchDelayTimer->start(delayMs);
        return;
    }

    const QString query = m_pendingSearchQuery;
    const double nearLat = m_pendingSearchNearLat;
    const double nearLng = m_pendingSearchNearLng;
    const bool nearbyBias = m_pendingSearchNearbyBias;
    m_hasPendingSearch = false;
    startSearchRequest(query, nearLat, nearLng, nearbyBias);
}

void MapDataService::startSearchRequest(const QString &query, double nearLat, double nearLng, bool nearbyBias)
{
    reserveGeocodeRequestSlot();
    m_searchReply = m_network->get(buildRequest(buildSearchUrl(query, nearLat, nearLng, nearbyBias)));
    QPointer<QNetworkReply> reply = m_searchReply;
    m_searchTimeoutTimer->start(m_geocodeTimeoutMs);

    connect(reply, &QNetworkReply::finished, this, [this, reply, query, nearLat, nearLng]() {
        if (!reply)
            return;

        const bool activeSearchReply = m_searchReply == reply;
        if (activeSearchReply && m_searchTimeoutTimer)
            m_searchTimeoutTimer->stop();

        if (activeSearchReply)
            m_searchReply = nullptr;

        const QNetworkReply::NetworkError errorCode = reply->error();
        const bool timedOut = reply->property("teslaSearchTimedOut").toBool();
        if (errorCode == QNetworkReply::OperationCanceledError) {
            reply->deleteLater();
            if (timedOut) {
                enterGeocodeFailureCooldown();
                emit searchCompleted(query, {}, false, QStringLiteral("在线搜索超时，使用本地匹配"));
            }
            dispatchPendingSearchRequest();
            return;
        }

        const int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (errorCode != QNetworkReply::NoError || httpStatus >= 400) {
            reply->deleteLater();
            if (errorCode != QNetworkReply::NoError || httpStatus >= 400 || timedOut)
                enterGeocodeFailureCooldown();

            const QString message = timedOut
                ? QStringLiteral("在线搜索超时，使用本地匹配")
                : httpStatus == 429
                    ? QStringLiteral("在线搜索被限流，使用本地匹配")
                    : (errorCode == QNetworkReply::NoError
                        ? QStringLiteral("在线搜索服务返回 HTTP %1，使用本地匹配").arg(httpStatus)
                        : QStringLiteral("在线搜索暂不可用，使用本地匹配"));
            emit searchCompleted(query, {}, false, message);
            dispatchPendingSearchRequest();
            return;
        }

        const QByteArray payload = reply->isOpen() ? reply->readAll() : QByteArray();
        reply->deleteLater();

        const QVariantList results = parseSearchResults(payload, nearLat, nearLng, query);

        m_geocodeFailureCooldownUntilMs = 0;
        emit searchCompleted(query, results, !results.isEmpty(), results.isEmpty()
                             ? QStringLiteral("未找到在线结果")
                             : QString());
        dispatchPendingSearchRequest();
    });
}

void MapDataService::reverseGeocode(double lat, double lng)
{
    if (!isValidCoordinate(lat, lng))
        return;
    queueReverseRequest(lat, lng);
}

void MapDataService::queueReverseRequest(double lat, double lng)
{
    cancelReverseRequest();

    m_pendingReverseLat = lat;
    m_pendingReverseLng = lng;
    m_hasPendingReverse = true;
    dispatchPendingReverseRequest();
}

void MapDataService::dispatchPendingReverseRequest()
{
    if (!m_hasPendingReverse || m_reverseReply)
        return;

    const int delayMs = geocodeRateLimitDelayMs();
    if (delayMs > 0) {
        if (m_reverseDelayTimer)
            m_reverseDelayTimer->start(delayMs);
        return;
    }

    const double lat = m_pendingReverseLat;
    const double lng = m_pendingReverseLng;
    m_hasPendingReverse = false;
    startReverseRequest(lat, lng);
}

void MapDataService::startReverseRequest(double lat, double lng)
{
    reserveGeocodeRequestSlot();

    m_reverseReply = m_network->get(buildRequest(buildReverseUrl(lat, lng)));
    QPointer<QNetworkReply> reply = m_reverseReply;
    m_reverseTimeoutTimer->start(m_geocodeTimeoutMs);

    connect(reply, &QNetworkReply::finished, this, [this, reply, lat, lng]() {
        if (!reply)
            return;

        const bool activeReverseReply = m_reverseReply == reply;
        if (activeReverseReply && m_reverseTimeoutTimer)
            m_reverseTimeoutTimer->stop();

        if (activeReverseReply)
            m_reverseReply = nullptr;

        const QNetworkReply::NetworkError errorCode = reply->error();
        const bool timedOut = reply->property("teslaReverseTimedOut").toBool();
        const int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (timedOut || errorCode != QNetworkReply::NoError || httpStatus >= 400)
            enterGeocodeFailureCooldown();

        if (errorCode == QNetworkReply::OperationCanceledError || errorCode != QNetworkReply::NoError || httpStatus >= 400) {
            reply->deleteLater();
            dispatchPendingReverseRequest();
            return;
        }

        const QByteArray payload = reply->isOpen() ? reply->readAll() : QByteArray();
        reply->deleteLater();

        const QString displayName = parseReverseDisplayName(payload);
        if (!displayName.isEmpty()) {
            m_geocodeFailureCooldownUntilMs = 0;
            emit reverseGeocodeResolved(lat, lng, displayName);
        }
        dispatchPendingReverseRequest();
    });
}

QUrl MapDataService::buildRouteUrl(double startLat, double startLng, double endLat, double endLng) const
{
    // OSRM 坐标顺序是 lon,lat；这里统一由 service 层转换，页面只传业务语义的 lat/lng。
    QUrl url(QStringLiteral("%1/route/v1/driving/%2,%3;%4,%5")
                 .arg(m_osrmHost)
                 .arg(startLng, 0, 'f', 6)
                 .arg(startLat, 0, 'f', 6)
                 .arg(endLng, 0, 'f', 6)
                 .arg(endLat, 0, 'f', 6));

    QUrlQuery query;
    query.addQueryItem(QStringLiteral("overview"), QStringLiteral("full"));
    query.addQueryItem(QStringLiteral("geometries"), QStringLiteral("geojson"));
    query.addQueryItem(QStringLiteral("steps"), QStringLiteral("true"));
    query.addQueryItem(QStringLiteral("alternatives"), QStringLiteral("true"));
    url.setQuery(query);
    return url;
}

QString MapDataService::routeCacheKey(double startLat, double startLng, double endLat, double endLng) const
{
    return QStringLiteral("%1|driving|%2,%3|%4,%5")
        .arg(m_osrmHost)
        .arg(startLat, 0, 'f', 6)
        .arg(startLng, 0, 'f', 6)
        .arg(endLat, 0, 'f', 6)
        .arg(endLng, 0, 'f', 6);
}

void MapDataService::storeRouteCache(const QString &cacheKey, const QVariantList &options)
{
    if (!m_routeCacheEnabled || cacheKey.isEmpty() || options.isEmpty())
        return;

    if (m_routeCache.contains(cacheKey))
        m_routeCacheOrder.removeAll(cacheKey);

    m_routeCache.insert(cacheKey, options);
    m_routeCacheOrder.append(cacheKey);

    while (m_routeCacheOrder.size() > kMaxRouteCacheEntries) {
        const QString expiredKey = m_routeCacheOrder.takeFirst();
        m_routeCache.remove(expiredKey);
    }

    emit routeCacheChanged();
}

void MapDataService::setRouteRequestState(const QString &state,
                                          const QString &errorCode,
                                          const QString &errorMessage)
{
    const bool stateChanged = m_routeRequestState != state;
    const bool codeChanged = m_lastRouteErrorCode != errorCode;
    const bool messageChanged = m_lastRouteErrorMessage != errorMessage;

    m_routeRequestState = state;
    m_lastRouteErrorCode = errorCode;
    m_lastRouteErrorMessage = errorMessage;

    if (stateChanged || codeChanged || messageChanged)
        emit routeRequestStateChanged();
}

void MapDataService::finishRouteWithError(const QString &code, const QString &message)
{
    setRouteRequestState(QStringLiteral("error"), code, message);
    emit routeFailedDetailed(code, message);
    emit routeFailed(message);
}

QVariantList MapDataService::parseRouteOptions(const QJsonObject &root) const
{
    const QJsonArray routes = root.value(QStringLiteral("routes")).toArray();
    const QJsonArray waypoints = root.value(QStringLiteral("waypoints")).toArray();
    QVariantList options;
    QVariantMap snappedStart;
    QVariantMap snappedEnd;

    if (waypoints.size() >= 2) {
        const QJsonArray startLocation = waypoints.at(0).toObject().value(QStringLiteral("location")).toArray();
        const QJsonArray endLocation = waypoints.at(1).toObject().value(QStringLiteral("location")).toArray();
        if (startLocation.size() >= 2) {
            snappedStart.insert(QStringLiteral("lat"), startLocation.at(1).toDouble());
            snappedStart.insert(QStringLiteral("lng"), startLocation.at(0).toDouble());
        }
        if (endLocation.size() >= 2) {
            snappedEnd.insert(QStringLiteral("lat"), endLocation.at(1).toDouble());
            snappedEnd.insert(QStringLiteral("lng"), endLocation.at(0).toDouble());
        }
    }

    for (const QJsonValue &routeValue : routes) {
        const QJsonObject routeObject = routeValue.toObject();
        const QJsonArray coordinates = routeObject.value(QStringLiteral("geometry"))
                                           .toObject()
                                           .value(QStringLiteral("coordinates"))
                                           .toArray();
        if (coordinates.isEmpty())
            continue;

        QVariantList pathPoints;
        // OSRM GeoJSON geometry 也是 [lon, lat]，这里统一转成 QML 更易消费的 lat/lng map。
        for (const QJsonValue &coordinateValue : coordinates) {
            const QJsonArray coordinate = coordinateValue.toArray();
            if (coordinate.size() < 2)
                continue;

            QVariantMap point;
            point.insert(QStringLiteral("lat"), coordinate.at(1).toDouble());
            point.insert(QStringLiteral("lng"), coordinate.at(0).toDouble());
            pathPoints.push_back(point);
        }

        if (pathPoints.isEmpty())
            continue;

        QVariantMap option;
        option.insert(QStringLiteral("pathPoints"), pathPoints);
        if (!snappedStart.isEmpty())
            option.insert(QStringLiteral("snappedStart"), snappedStart);
        if (!snappedEnd.isEmpty())
            option.insert(QStringLiteral("snappedEnd"), snappedEnd);
        option.insert(QStringLiteral("steps"), parseStepList(routeObject.value(QStringLiteral("legs")).toArray()));
        option.insert(QStringLiteral("distanceMiles"),
                      routeObject.value(QStringLiteral("distance")).toDouble() / kMetersPerMile);
        option.insert(QStringLiteral("durationMinutes"),
                      routeObject.value(QStringLiteral("duration")).toDouble() / 60.0);
        options.push_back(option);
    }

    return options;
}

QVariantList MapDataService::parseSearchResults(const QByteArray &payload,
                                                double nearLat,
                                                double nearLng,
                                                const QString &query) const
{
    const QJsonDocument document = QJsonDocument::fromJson(payload);
    QList<QVariantMap> rankedResults;

    if (m_geocodeProvider == kProviderPhoton && document.isObject()) {
        const QJsonArray features = document.object().value(QStringLiteral("features")).toArray();
        for (const QJsonValue &featureValue : features) {
            const QJsonObject feature = featureValue.toObject();
            const QJsonObject properties = feature.value(QStringLiteral("properties")).toObject();
            const QJsonArray coordinates = feature.value(QStringLiteral("geometry"))
                                           .toObject()
                                           .value(QStringLiteral("coordinates"))
                                           .toArray();
            if (coordinates.size() < 2)
                continue;

            const double lon = coordinates.at(0).toDouble();
            const double lat = coordinates.at(1).toDouble();
            if (!isValidCoordinate(lat, lon))
                continue;

            QStringList nameParts;
            const QString name = properties.value(QStringLiteral("name")).toString().trimmed();
            const QString street = properties.value(QStringLiteral("street")).toString().trimmed();
            const QString city = properties.value(QStringLiteral("city")).toString().trimmed();
            const QString district = properties.value(QStringLiteral("district")).toString().trimmed();
            const QString state = properties.value(QStringLiteral("state")).toString().trimmed();
            const QString country = properties.value(QStringLiteral("country")).toString().trimmed();
            for (const QString &part : { name, street, district, city, state, country }) {
                if (!part.isEmpty() && !nameParts.contains(part))
                    nameParts.append(part);
            }

            const QString displayName = nameParts.join(QStringLiteral(", "));
            if (!isStrongEnoughTextMatch(query, displayName))
                continue;

            const double distance = distanceMeters(nearLat, nearLng, lat, lon);
            const double score = distance / 1000.0 + textMatchBonus(query, displayName);

            QVariantMap result;
            result.insert(QStringLiteral("name"), displayName.isEmpty() ? QStringLiteral("搜索结果") : displayName);
            result.insert(QStringLiteral("latitude"), lat);
            result.insert(QStringLiteral("longitude"), lon);
            result.insert(QStringLiteral("distanceMeters"), distance);
            result.insert(QStringLiteral("importance"), 0.0);
            result.insert(QStringLiteral("score"), score);
            rankedResults.push_back(result);
        }
    } else if (document.isArray()) {
        const QJsonArray places = document.array();
        for (const QJsonValue &placeValue : places) {
            const QJsonObject place = placeValue.toObject();
            const QString displayName = place.value(QStringLiteral("display_name")).toString().trimmed();
            // 避免把只共享“大厦/道路/园区”等泛词的地点当成有效目的地。
            if (!isStrongEnoughTextMatch(query, displayName))
                continue;

            const QString latText = place.value(QStringLiteral("lat")).toString();
            const QString lonText = place.value(QStringLiteral("lon")).toString();

            bool latOk = false;
            bool lonOk = false;
            const double lat = latText.toDouble(&latOk);
            const double lon = lonText.toDouble(&lonOk);
            if (!latOk || !lonOk || !isValidCoordinate(lat, lon))
                continue;

            const QJsonObject address = place.value(QStringLiteral("address")).toObject();
            const double importance = place.value(QStringLiteral("importance")).toDouble(0.0);
            const double distance = distanceMeters(nearLat, nearLng, lat, lon);
            const QString countryCode = address.value(QStringLiteral("country_code")).toString().toLower();
            const bool inChina = countryCode.isEmpty() || countryCode == QStringLiteral("cn");
            // score 综合距离、OSM importance、文本命中；数值只用于排序，不透出给 QML。
            const double score = distance / 1000.0 - importance * 120.0
                                 + textMatchBonus(query, displayName)
                                 + (inChina ? 0.0 : 5000.0);

            QVariantMap result;
            result.insert(QStringLiteral("name"), displayName.isEmpty() ? QStringLiteral("搜索结果") : displayName);
            result.insert(QStringLiteral("latitude"), lat);
            result.insert(QStringLiteral("longitude"), lon);
            result.insert(QStringLiteral("distanceMeters"), distance);
            result.insert(QStringLiteral("importance"), importance);
            result.insert(QStringLiteral("score"), score);
            rankedResults.push_back(result);
        }
    } else {
        return {};
    }

    std::sort(rankedResults.begin(), rankedResults.end(), [](const QVariantMap &left, const QVariantMap &right) {
        return left.value(QStringLiteral("score")).toDouble() < right.value(QStringLiteral("score")).toDouble();
    });

    QVariantList results;
    for (const QVariantMap &result : rankedResults) {
        QVariantMap cleaned = result;
        cleaned.remove(QStringLiteral("score"));
        results.push_back(cleaned);
    }

    return results;
}

QString MapDataService::parseReverseDisplayName(const QByteArray &payload) const
{
    const QJsonDocument document = QJsonDocument::fromJson(payload);
    if (!document.isObject())
        return {};

    if (m_geocodeProvider == kProviderPhoton) {
        const QJsonArray features = document.object().value(QStringLiteral("features")).toArray();
        if (features.isEmpty())
            return {};

        const QJsonObject properties = features.first().toObject().value(QStringLiteral("properties")).toObject();
        QStringList nameParts;
        const QString name = properties.value(QStringLiteral("name")).toString().trimmed();
        const QString street = properties.value(QStringLiteral("street")).toString().trimmed();
        const QString city = properties.value(QStringLiteral("city")).toString().trimmed();
        const QString district = properties.value(QStringLiteral("district")).toString().trimmed();
        const QString state = properties.value(QStringLiteral("state")).toString().trimmed();
        const QString country = properties.value(QStringLiteral("country")).toString().trimmed();
        for (const QString &part : { name, street, district, city, state, country }) {
            if (!part.isEmpty() && !nameParts.contains(part))
                nameParts.append(part);
        }
        return nameParts.join(QStringLiteral(", ")).trimmed();
    }

    return document.object().value(QStringLiteral("display_name")).toString().trimmed();
}

void MapDataService::cancelRouteRequest()
{
    if (m_routeTimeoutTimer)
        m_routeTimeoutTimer->stop();

    if (m_routeReply)
        m_routeReply->setProperty("teslaRouteSilentCancel", true);

    cancelReply(m_routeReply);
}

void MapDataService::cancelSearchRequest()
{
    if (m_searchTimeoutTimer)
        m_searchTimeoutTimer->stop();
    if (m_searchDelayTimer)
        m_searchDelayTimer->stop();
    m_hasPendingSearch = false;

    cancelReply(m_searchReply);
}

void MapDataService::cancelReverseRequest()
{
    if (m_reverseTimeoutTimer)
        m_reverseTimeoutTimer->stop();
    if (m_reverseDelayTimer)
        m_reverseDelayTimer->stop();
    m_hasPendingReverse = false;

    cancelReply(m_reverseReply);
}

void MapDataService::cancelReply(QPointer<QNetworkReply> &reply)
{
    if (!reply)
        return;

    // abort() can synchronously emit finished() on Qt 6. Clear the owner pointer
    // before aborting so the finished handler cannot race this cleanup path.
    QPointer<QNetworkReply> replyToCancel = reply;
    reply = nullptr;
    replyToCancel->abort();
    if (replyToCancel)
        replyToCancel->deleteLater();
}

bool MapDataService::geocodeInFailureCooldown() const
{
    return m_geocodeFailureCooldownUntilMs > m_clock.elapsed();
}

int MapDataService::geocodeRateLimitDelayMs() const
{
    const qint64 nowMs = m_clock.elapsed();
    if (m_geocodeFailureCooldownUntilMs > nowMs)
        return static_cast<int>(m_geocodeFailureCooldownUntilMs - nowMs);
    if (m_nextGeocodeAllowedAtMs > nowMs)
        return static_cast<int>(m_nextGeocodeAllowedAtMs - nowMs);
    return 0;
}

void MapDataService::reserveGeocodeRequestSlot()
{
    m_nextGeocodeAllowedAtMs = m_clock.elapsed() + m_geocodeMinIntervalMs;
}

void MapDataService::enterGeocodeFailureCooldown()
{
    m_geocodeFailureCooldownUntilMs = m_clock.elapsed() + m_geocodeFailureCooldownMs;
}
