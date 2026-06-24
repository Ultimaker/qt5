#ifndef QCUSTOMPLOTITEM_H
#define QCUSTOMPLOTITEM_H

#include <QQuickPaintedItem>
#include <QQuickItem>
#include "qcustomplot.h"

class QCustomPlotItem : public QQuickPaintedItem
{
    Q_OBJECT

public:
    QCustomPlotItem(QQuickItem *parent = nullptr);
    virtual ~QCustomPlotItem();

    void paint(QPainter *painter) override;

    Q_INVOKABLE void updateData(const QVariantList& timestamps, const QVariantList& humidity, const QVariantList& dehumidifierStates);

protected:
    void hoverMoveEvent(QHoverEvent *event) override;
    void mousePressEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void wheelEvent(QWheelEvent *event) override;

    void geometryChanged(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    QCustomPlot *m_customPlot;
    QCPAxisRect *m_axisRectHumidity;
    QCPAxisRect *m_axisRectDehumidifier;
    QCPGraph *m_humidityGraph;
    QCPBars *m_dehumidifierBars;

private slots:
    void onReplot();
};

#endif // QCUSTOMPLOTITEM_H
