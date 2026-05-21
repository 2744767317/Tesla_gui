#include "../MapDataService.h"

#include <QSignalSpy>
#include <QtTest>

class MapDataServiceTests : public QObject
{
    Q_OBJECT

private slots:
    void init()
    {
        qunsetenv("TESLA_ROUTE_TIMEOUT_MS");
        qunsetenv("OSRM_TIMEOUT_MS");
        qunsetenv("TESLA_GEOCODE_TIMEOUT_MS");
        qunsetenv("NOMINATIM_TIMEOUT_MS");
        qunsetenv("TESLA_GEOCODE_MIN_INTERVAL_MS");
        qunsetenv("NOMINATIM_MIN_INTERVAL_MS");
        qunsetenv("TESLA_GEOCODE_FAILURE_COOLDOWN_MS");
        qunsetenv("NOMINATIM_FAILURE_COOLDOWN_MS");
        qunsetenv("TESLA_ROUTE_CACHE_ENABLED");
        qunsetenv("TESLA_MAP_STYLE");
        qunsetenv("TESLA_MAP_TILE_HOST");
        qunsetenv("TESLA_GEOCODE_HOST");
        qunsetenv("TESLA_GEOCODE_PROVIDER");
        qunsetenv("GEOCODE_PROVIDER");
        qunsetenv("TESLA_PHOTON_HOST");
        qunsetenv("TESLA_NOMINATIM_HOST");
        qunsetenv("NOMINATIM_HOST");
    }

    void routeTimeoutIsClampedFromEnvironment()
    {
        qputenv("TESLA_ROUTE_TIMEOUT_MS", "1");

        MapDataService service;

        QCOMPARE(service.routeTimeoutMs(), 1500);
    }

    void geocodeTimeoutIsClampedFromEnvironment()
    {
        qputenv("TESLA_GEOCODE_TIMEOUT_MS", "999999");

        MapDataService service;

        QCOMPARE(service.geocodeTimeoutMs(), 20000);
    }

    void geocodeRateLimitSettingsAreClampedFromEnvironment()
    {
        qputenv("TESLA_GEOCODE_MIN_INTERVAL_MS", "0");
        qputenv("TESLA_GEOCODE_FAILURE_COOLDOWN_MS", "999999");

        MapDataService service;

        QCOMPARE(service.geocodeMinIntervalMs(), 250);
        QCOMPARE(service.geocodeFailureCooldownMs(), 60000);
    }

    void geocodeHostAndProviderCanBeConfigured()
    {
        qputenv("TESLA_GEOCODE_HOST", "127.0.0.1:7070");
        qputenv("TESLA_GEOCODE_PROVIDER", "photon");

        MapDataService service;

        QCOMPARE(service.geocodeHost(), QStringLiteral("http://127.0.0.1:7070"));
        QCOMPARE(service.geocodeProvider(), QStringLiteral("photon"));
    }

    void photonHostInfersProvider()
    {
        qputenv("TESLA_PHOTON_HOST", "https://example.com/photon");

        MapDataService service;

        QCOMPARE(service.geocodeHost(), QStringLiteral("https://example.com/photon"));
        QCOMPARE(service.geocodeProvider(), QStringLiteral("photon"));
    }

    void photonProviderDefaultsToPhotonHost()
    {
        qputenv("TESLA_GEOCODE_PROVIDER", "photon");

        MapDataService service;

        QCOMPARE(service.geocodeHost(), QStringLiteral("https://photon.komoot.io"));
        QCOMPARE(service.geocodeProvider(), QStringLiteral("photon"));
    }

    void invalidRouteCoordinatesFailSynchronously()
    {
        MapDataService service;
        QSignalSpy failedSpy(&service, &MapDataService::routeFailedDetailed);

        service.requestRoute(91.0, 116.0, 39.0, 116.0);

        QCOMPARE(failedSpy.count(), 1);
        QCOMPARE(failedSpy.takeFirst().at(0).toString(), QStringLiteral("invalid-coordinate"));
        QCOMPARE(service.routeRequestState(), QStringLiteral("error"));
    }

    void shortSearchQueryCompletesWithoutNetwork()
    {
        MapDataService service;
        QSignalSpy completedSpy(&service, &MapDataService::searchCompleted);

        service.searchPlaces(QStringLiteral("a"), 39.9042, 116.4074);

        QCOMPARE(completedSpy.count(), 1);
        const QList<QVariant> arguments = completedSpy.takeFirst();
        QCOMPARE(arguments.at(0).toString(), QStringLiteral("a"));
        QCOMPARE(arguments.at(2).toBool(), false);
    }

    void repeatedSearchRequestsCancelSafely()
    {
        qputenv("TESLA_GEOCODE_MIN_INTERVAL_MS", "250");

        MapDataService service;
        QSignalSpy completedSpy(&service, &MapDataService::searchCompleted);

        service.searchPlaces(QStringLiteral("山东"), 39.9042, 116.4074);
        service.searchPlaces(QStringLiteral("山东省"), 39.9042, 116.4074);
        service.searchPlaces(QStringLiteral("济南"), 39.9042, 116.4074);

        QTest::qWait(40);
        QCOMPARE(completedSpy.count(), 0);
    }
};

QTEST_MAIN(MapDataServiceTests)

#include "map_data_service_tests.moc"
