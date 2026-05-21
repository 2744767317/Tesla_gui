QT += testlib network qml
CONFIG += testcase console
CONFIG -= app_bundle

TARGET = map_data_service_tests

SOURCES += \
    map_data_service_tests.cpp \
    ../MapDataService.cpp

HEADERS += \
    ../MapDataService.h
