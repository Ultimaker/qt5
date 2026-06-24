#include "qcustomplot_plugin.h"
#include "qcustomplotitem.h"
#include <qqml.h>

void QCustomPlotPlugin::registerTypes(const char *uri)
{
    qmlRegisterType<QCustomPlotItem>(uri, 1, 0, "CustomPlotItem");
}
