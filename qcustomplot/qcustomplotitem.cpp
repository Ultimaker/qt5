#include "qcustomplotitem.h"
#include <QDebug>
#include <QMouseEvent>
#include <QWheelEvent>

QCustomPlotItem::QCustomPlotItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
    , m_customPlot(nullptr)
    , m_axisRect(nullptr)
    , m_insideGraph(nullptr)
    , m_outsideGraph(nullptr)
{
    setAcceptHoverEvents(true);
    setAcceptedMouseButtons(Qt::AllButtons);

    m_customPlot = new QCustomPlot();
    m_customPlot->setAttribute(Qt::WA_NoSystemBackground);

    connect(m_customPlot, &QCustomPlot::afterReplot, this, &QCustomPlotItem::onReplot);

    m_customPlot->setBackground(QBrush(QColor(26, 26, 26)));
    m_customPlot->plotLayout()->clear();

    m_axisRect = new QCPAxisRect(m_customPlot);
    m_customPlot->plotLayout()->addElement(0, 0, m_axisRect);
    m_axisRect->setBackground(QBrush(QColor(36, 36, 36)));

    QCPAxis *xAxis = m_axisRect->axis(QCPAxis::atBottom);
    QCPAxis *yAxis = m_axisRect->axis(QCPAxis::atLeft);
    xAxis->setVisible(true);
    yAxis->setVisible(true);

    QSharedPointer<QCPAxisTickerDateTime> dateTimeTicker(new QCPAxisTickerDateTime);
    dateTimeTicker->setDateTimeFormat("MM-dd\nHH:mm");
    xAxis->setTicker(dateTimeTicker);

    QFont smallFont;
    smallFont.setPointSize(7);

    xAxis->setTickLabelFont(smallFont);
    xAxis->setTickLabelColor(QColor(180, 180, 180));
    xAxis->setBasePen(QPen(QColor(100, 100, 100)));
    xAxis->setTickPen(QPen(QColor(100, 100, 100)));
    xAxis->setSubTickPen(QPen(QColor(60, 60, 60)));
    xAxis->grid()->setPen(QPen(QColor(50, 50, 50), 1, Qt::DotLine));
    xAxis->grid()->setZeroLinePen(Qt::NoPen);

    yAxis->setTickLabelFont(smallFont);
    yAxis->setTickLabelColor(QColor(180, 180, 180));
    yAxis->setBasePen(QPen(QColor(100, 100, 100)));
    yAxis->setTickPen(QPen(QColor(100, 100, 100)));
    yAxis->setSubTickPen(QPen(QColor(60, 60, 60)));
    yAxis->grid()->setPen(QPen(QColor(50, 50, 50), 1, Qt::DotLine));
    yAxis->setRange(0, 100);

    // Inside humidity (teal)
    m_insideGraph = m_customPlot->addGraph(xAxis, yAxis);
    m_insideGraph->setName("Inside");
    m_insideGraph->setPen(QPen(QColor(0, 173, 181), 2));
    m_insideGraph->setLineStyle(QCPGraph::lsLine);

    // Outside / ambient humidity (orange)
    m_outsideGraph = m_customPlot->addGraph(xAxis, yAxis);
    m_outsideGraph->setName("Outside");
    m_outsideGraph->setPen(QPen(QColor(255, 152, 0), 2));
    m_outsideGraph->setLineStyle(QCPGraph::lsLine);

    // Legend
    m_customPlot->legend->setVisible(true);
    m_customPlot->legend->setFont(smallFont);
    m_customPlot->legend->setTextColor(QColor(200, 200, 200));
    m_customPlot->legend->setBrush(QBrush(QColor(40, 40, 40, 200)));
    m_customPlot->legend->setBorderPen(QPen(QColor(80, 80, 80)));
    m_axisRect->insetLayout()->setInsetAlignment(0, Qt::AlignTop | Qt::AlignRight);

    // Compact margins
    m_axisRect->setMinimumMargins(QMargins(4, 4, 4, 4));
    m_customPlot->plotLayout()->setMargins(QMargins(2, 2, 2, 2));
}

QCustomPlotItem::~QCustomPlotItem()
{
    delete m_customPlot;
}

void QCustomPlotItem::paint(QPainter *painter)
{
    if (m_customPlot) {
        QPixmap pixmap(width(), height());
        QCPPainter qcpPainter(&pixmap);
        m_customPlot->toPainter(&qcpPainter, width(), height());
        painter->drawPixmap(0, 0, pixmap);
    }
}

void QCustomPlotItem::updateData(const QVariantList& timestamps,
                                  const QVariantList& insideHumidity,
                                  const QVariantList& outsideHumidity)
{
    if (timestamps.isEmpty() || !m_insideGraph || !m_outsideGraph)
        return;

    int size = timestamps.size();
    QVector<double> xData(size), yInside(size), yOutside(size);

    for (int i = 0; i < size; ++i) {
        xData[i] = timestamps[i].toDouble();
        yInside[i] = insideHumidity[i].toDouble();
        yOutside[i] = outsideHumidity[i].toDouble();
    }

    m_insideGraph->setData(xData, yInside);
    m_outsideGraph->setData(xData, yOutside);

    m_axisRect->axis(QCPAxis::atBottom)->setRange(xData.first(), xData.last());

    m_customPlot->replot();
}

void QCustomPlotItem::onReplot()
{
    update();
}

void QCustomPlotItem::geometryChanged(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickPaintedItem::geometryChanged(newGeometry, oldGeometry);
    if (m_customPlot) {
        m_customPlot->setViewport(QRect(0, 0, newGeometry.width(), newGeometry.height()));
        m_customPlot->replot();
    }
}

void QCustomPlotItem::hoverMoveEvent(QHoverEvent *event) { Q_UNUSED(event); }
void QCustomPlotItem::mousePressEvent(QMouseEvent *event) { Q_UNUSED(event); }
void QCustomPlotItem::mouseReleaseEvent(QMouseEvent *event) { Q_UNUSED(event); }
void QCustomPlotItem::mouseMoveEvent(QMouseEvent *event) { Q_UNUSED(event); }
void QCustomPlotItem::wheelEvent(QWheelEvent *event) { Q_UNUSED(event); }
