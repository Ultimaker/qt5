#include "qcustomplotitem.h"
#include <QDebug>
#include <QMouseEvent>
#include <QWheelEvent>

QCustomPlotItem::QCustomPlotItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
    , m_customPlot(nullptr)
    , m_axisRectHumidity(nullptr)
    , m_axisRectDehumidifier(nullptr)
    , m_humidityGraph(nullptr)
    , m_dehumidifierBars(nullptr)
{
    setAcceptHoverEvents(true);
    setAcceptedMouseButtons(Qt::AllButtons);

    m_customPlot = new QCustomPlot();
    m_customPlot->setAttribute(Qt::WA_NoSystemBackground);

    connect(m_customPlot, &QCustomPlot::afterReplot, this, &QCustomPlotItem::onReplot);

    m_customPlot->setBackground(QBrush(QColor(26, 26, 26)));
    m_customPlot->plotLayout()->clear();

    m_axisRectHumidity = new QCPAxisRect(m_customPlot);
    m_axisRectDehumidifier = new QCPAxisRect(m_customPlot);

    m_customPlot->plotLayout()->addElement(0, 0, m_axisRectHumidity);
    m_customPlot->plotLayout()->addElement(1, 0, m_axisRectDehumidifier);

    QCPMarginGroup *group = new QCPMarginGroup(m_customPlot);
    m_axisRectHumidity->setMarginGroup(QCP::msLeft | QCP::msRight, group);
    m_axisRectDehumidifier->setMarginGroup(QCP::msLeft | QCP::msRight, group);

    // Humidity subplot
    QCPAxis *xAxisHum = m_axisRectHumidity->axis(QCPAxis::atBottom);
    QCPAxis *yAxisHum = m_axisRectHumidity->axis(QCPAxis::atLeft);
    xAxisHum->setVisible(true);
    yAxisHum->setVisible(true);

    QSharedPointer<QCPAxisTickerDateTime> dateTimeTicker(new QCPAxisTickerDateTime);
    dateTimeTicker->setDateTimeFormat("MM-dd\nHH:mm");
    xAxisHum->setTicker(dateTimeTicker);

    xAxisHum->setTickLabelColor(QColor(200, 200, 200));
    xAxisHum->setBasePen(QPen(QColor(100, 100, 100)));
    xAxisHum->setTickPen(QPen(QColor(100, 100, 100)));
    xAxisHum->setSubTickPen(QPen(QColor(60, 60, 60)));
    xAxisHum->grid()->setPen(QPen(QColor(50, 50, 50), 1, Qt::DotLine));
    xAxisHum->grid()->setZeroLinePen(Qt::NoPen);

    yAxisHum->setTickLabelColor(QColor(200, 200, 200));
    yAxisHum->setBasePen(QPen(QColor(100, 100, 100)));
    yAxisHum->setTickPen(QPen(QColor(100, 100, 100)));
    yAxisHum->setSubTickPen(QPen(QColor(60, 60, 60)));
    yAxisHum->grid()->setPen(QPen(QColor(50, 50, 50), 1, Qt::DotLine));
    yAxisHum->setLabel("Humidity (%)");
    yAxisHum->setLabelColor(QColor(220, 220, 220));
    yAxisHum->setRange(0, 100);

    m_axisRectHumidity->setBackground(QBrush(QColor(36, 36, 36)));

    m_humidityGraph = m_customPlot->addGraph(xAxisHum, yAxisHum);
    QPen bluePen(QColor(0, 173, 181), 2);
    m_humidityGraph->setPen(bluePen);
    m_humidityGraph->setLineStyle(QCPGraph::lsLine);

    QLinearGradient blueGradient(0, 0, 0, 300);
    blueGradient.setColorAt(0, QColor(0, 173, 181, 100));
    blueGradient.setColorAt(1, QColor(0, 173, 181, 0));
    m_humidityGraph->setBrush(QBrush(blueGradient));

    // Dehumidifier subplot
    QCPAxis *xAxisDehum = m_axisRectDehumidifier->axis(QCPAxis::atBottom);
    QCPAxis *yAxisDehum = m_axisRectDehumidifier->axis(QCPAxis::atLeft);
    xAxisDehum->setVisible(true);
    yAxisDehum->setVisible(true);
    xAxisDehum->setTicker(dateTimeTicker);

    xAxisDehum->setTickLabelColor(QColor(200, 200, 200));
    xAxisDehum->setBasePen(QPen(QColor(100, 100, 100)));
    xAxisDehum->setTickPen(QPen(QColor(100, 100, 100)));
    xAxisDehum->setSubTickPen(QPen(QColor(60, 60, 60)));
    xAxisDehum->grid()->setPen(QPen(QColor(50, 50, 50), 1, Qt::DotLine));
    xAxisDehum->grid()->setZeroLinePen(Qt::NoPen);

    yAxisDehum->setTickLabelColor(QColor(200, 200, 200));
    yAxisDehum->setBasePen(QPen(QColor(100, 100, 100)));
    yAxisDehum->setTickPen(QPen(QColor(100, 100, 100)));
    yAxisDehum->setSubTickPen(QPen(QColor(60, 60, 60)));
    yAxisDehum->grid()->setPen(QPen(QColor(50, 50, 50), 1, Qt::DotLine));
    yAxisDehum->setLabel("Dehumidifier State");
    yAxisDehum->setLabelColor(QColor(220, 220, 220));

    QSharedPointer<QCPAxisTickerText> stateTicker(new QCPAxisTickerText);
    stateTicker->addTick(0, "unknown");
    stateTicker->addTick(1, "operational");
    stateTicker->addTick(2, "testing");
    stateTicker->addTick(3, "drying");
    stateTicker->addTick(4, "regenerating");
    stateTicker->addTick(5, "error");
    yAxisDehum->setTicker(stateTicker);
    yAxisDehum->setRange(-0.5, 5.5);

    m_axisRectDehumidifier->setBackground(QBrush(QColor(36, 36, 36)));

    m_dehumidifierBars = new QCPBars(xAxisDehum, yAxisDehum);
    m_dehumidifierBars->setPen(Qt::NoPen);
    m_dehumidifierBars->setBrush(QBrush(QColor(121, 113, 234)));
    m_dehumidifierBars->setWidthType(QCPBars::wtPlotCoords);
    m_dehumidifierBars->setWidth(600);

    connect(xAxisHum, SIGNAL(rangeChanged(QCPRange)), xAxisDehum, SLOT(setRange(QCPRange)));
    connect(xAxisDehum, SIGNAL(rangeChanged(QCPRange)), xAxisHum, SLOT(setRange(QCPRange)));
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

void QCustomPlotItem::updateData(const QVariantList& timestamps, const QVariantList& humidity, const QVariantList& dehumidifierStates)
{
    if (timestamps.isEmpty() || !m_humidityGraph || !m_dehumidifierBars)
        return;

    int size = timestamps.size();
    QVector<double> xData(size), yDataHum(size), yDataDehum(size);

    for (int i = 0; i < size; ++i) {
        xData[i] = timestamps[i].toDouble();
        yDataHum[i] = humidity[i].toDouble();
        yDataDehum[i] = dehumidifierStates[i].toDouble();
    }

    m_humidityGraph->setData(xData, yDataHum);
    m_dehumidifierBars->setData(xData, yDataDehum);

    m_axisRectHumidity->axis(QCPAxis::atBottom)->setRange(xData.first(), xData.last());
    m_axisRectDehumidifier->axis(QCPAxis::atBottom)->setRange(xData.first(), xData.last());

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
