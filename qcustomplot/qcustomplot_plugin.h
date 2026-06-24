#ifndef QCUSTOMPLOT_PLUGIN_H
#define QCUSTOMPLOT_PLUGIN_H

#include <QQmlExtensionPlugin>

class QCustomPlotPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override;
};

#endif // QCUSTOMPLOT_PLUGIN_H
