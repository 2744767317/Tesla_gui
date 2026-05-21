QT += quick location positioning network

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        main.cpp \
        VehicleController.cpp \
        MediaController.cpp \
        BluetoothController.cpp \
        NavigationController.cpp \
        AutowareBridge.cpp \
        ADController.cpp \
        MapTileSettings.cpp \
        MapDataService.cpp \
        SearchStorage.cpp

HEADERS += \
        VehicleController.h \
        MediaController.h \
        BluetoothController.h \
        NavigationController.h \
        AutowareBridge.h \
        ADController.h \
        MapTileSettings.h \
        MapDataService.h \
        SearchStorage.h

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
