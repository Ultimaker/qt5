TEMPLATE = lib
CONFIG += plugin c++11
QT += core qml quick widgets printsupport

DEFINES += QCUSTOMPLOT_COMPILE_LIBRARY

TARGET = qcustomplotplugin
TARGETPATH = CustomPlot

HEADERS += \
    qcustomplot.h \
    qcustomplotitem.h \
    qcustomplot_plugin.h

SOURCES += \
    qcustomplot.cpp \
    qcustomplotitem.cpp \
    qcustomplot_plugin.cpp

qmldir.files = qmldir
qmldir.path = $$[QT_INSTALL_QML]/CustomPlot
INSTALLS += qmldir

target.path = $$[QT_INSTALL_QML]/CustomPlot
INSTALLS += target
