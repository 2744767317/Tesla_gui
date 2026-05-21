#include "SearchStorage.h"

#include <QSettings>

namespace {
constexpr char kGroupName[] = "MapSearch";
constexpr char kHistoryKey[] = "historyJson";
constexpr char kFavoritesKey[] = "favoritesJson";
constexpr char kHomeKey[] = "homeJson";
constexpr char kWorkKey[] = "workJson";
}

SearchStorage::SearchStorage(QObject *parent)
    : QObject(parent)
{
    load();
}

QString SearchStorage::historyJson() const
{
    return m_historyJson;
}

QString SearchStorage::favoritesJson() const
{
    return m_favoritesJson;
}

QString SearchStorage::homeJson() const
{
    return m_homeJson;
}

QString SearchStorage::workJson() const
{
    return m_workJson;
}

void SearchStorage::setHistoryJson(const QString &value)
{
    if (m_historyJson == value)
        return;

    m_historyJson = value;
    save(kHistoryKey, value);
    emit historyJsonChanged();
}

void SearchStorage::setFavoritesJson(const QString &value)
{
    if (m_favoritesJson == value)
        return;

    m_favoritesJson = value;
    save(kFavoritesKey, value);
    emit favoritesJsonChanged();
}

void SearchStorage::setHomeJson(const QString &value)
{
    if (m_homeJson == value)
        return;

    m_homeJson = value;
    save(kHomeKey, value);
    emit homeJsonChanged();
}

void SearchStorage::setWorkJson(const QString &value)
{
    if (m_workJson == value)
        return;

    m_workJson = value;
    save(kWorkKey, value);
    emit workJsonChanged();
}

void SearchStorage::load()
{
    QSettings settings;
    settings.beginGroup(QString::fromLatin1(kGroupName));
    m_historyJson = settings.value(QString::fromLatin1(kHistoryKey), QStringLiteral("[]")).toString();
    m_favoritesJson = settings.value(QString::fromLatin1(kFavoritesKey), QStringLiteral("[]")).toString();
    m_homeJson = settings.value(QString::fromLatin1(kHomeKey)).toString();
    m_workJson = settings.value(QString::fromLatin1(kWorkKey)).toString();
    settings.endGroup();
}

void SearchStorage::save(const char *key, const QString &value)
{
    QSettings settings;
    settings.beginGroup(QString::fromLatin1(kGroupName));
    settings.setValue(QString::fromLatin1(key), value);
    settings.endGroup();
    settings.sync();
}
