#pragma once

#include <QObject>
#include <QString>

class SearchStorage : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString historyJson READ historyJson WRITE setHistoryJson NOTIFY historyJsonChanged)
    Q_PROPERTY(QString favoritesJson READ favoritesJson WRITE setFavoritesJson NOTIFY favoritesJsonChanged)
    Q_PROPERTY(QString homeJson READ homeJson WRITE setHomeJson NOTIFY homeJsonChanged)
    Q_PROPERTY(QString workJson READ workJson WRITE setWorkJson NOTIFY workJsonChanged)

public:
    explicit SearchStorage(QObject *parent = nullptr);

    QString historyJson() const;
    QString favoritesJson() const;
    QString homeJson() const;
    QString workJson() const;

public slots:
    void setHistoryJson(const QString &value);
    void setFavoritesJson(const QString &value);
    void setHomeJson(const QString &value);
    void setWorkJson(const QString &value);

signals:
    void historyJsonChanged();
    void favoritesJsonChanged();
    void homeJsonChanged();
    void workJsonChanged();

private:
    void load();
    void save(const char *key, const QString &value);

    QString m_historyJson = QStringLiteral("[]");
    QString m_favoritesJson = QStringLiteral("[]");
    QString m_homeJson;
    QString m_workJson;
};
