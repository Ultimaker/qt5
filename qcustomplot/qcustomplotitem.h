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

    Q_INVOKABLE void updateData(const QVariantList& timestamps,
                                const QVariantList& insideHumidity,
                                const QVariantList& outsideHumidity);

protected:
    void hoverMoveEvent(QHoverEvent *event) override;
    void mousePressEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void wheelEvent(QWheelEvent *event) override;

    void geometryChanged(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    QCustomPlot *m_customPlot;
    QCPAxisRect *m_axisRect;
    QCPGraph *m_insideGraph;
    QCPGraph *m_outsideGraph;

private slots:
    void onReplot();
};

#endif // QCUSTOMPLOTITEM_H
