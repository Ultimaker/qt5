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

    // Use the default axis rect so the legend (already at inset index 0) is valid.
    m_axisRect = m_customPlot->axisRect();
    m_axisRect->setBackground(QBrush(QColor(36, 36, 36)));

    QCPAxis *xAxis = m_axisRect->axis(QCPAxis::atBottom);
    QCPAxis *yAxis = m_axisRect->axis(QCPAxis::atLeft);
    xAxis->setVisible(true);
    yAxis->setVisible(true);

    QSharedPointer<QCPAxisTickerDateTime> dateTimeTicker(new QCPAxisTickerDateTime);
    dateTimeTicker->setDateTimeFormat("MM-dd");
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

    // Compact margins — smaller bottom since we dropped the HH:mm row
    m_axisRect->setMinimumMargins(QMargins(4, 4, 4, 2));
    m_customPlot->plotLayout()->setMargins(QMargins(2, 2, 2, 0));

    // Layer for state backgrounds — drawn before grid so it stays behind everything
    m_customPlot->addLayer("statebg", m_customPlot->layer("background"), QCustomPlot::limAbove);
}

QCustomPlotItem::~QCustomPlotItem()
{
    delete m_customPlot;
}

void QCustomPlotItem::paint(QPainter *painter)
{
    if (!m_customPlot || width() <= 0 || height() <= 0)
        return;
    QPixmap pixmap(static_cast<int>(width()), static_cast<int>(height()));
    QCPPainter qcpPainter(&pixmap);
    m_customPlot->toPainter(&qcpPainter, static_cast<int>(width()), static_cast<int>(height()));
    painter->drawPixmap(0, 0, pixmap);
}

void QCustomPlotItem::updateData(const QVariantList& timestamps,
                                  const QVariantList& insideHumidity,
                                  const QVariantList& outsideHumidity,
                                  const QVariantList& dehumidifierStates)
{
    if (timestamps.isEmpty() || !m_insideGraph || !m_outsideGraph)
        return;

    int size = timestamps.size();
    QVector<double> xData(size), yInside(size), yOutside(size), yStates(size);

    for (int i = 0; i < size; ++i) {
        xData[i] = timestamps[i].toDouble();
        yInside[i] = insideHumidity[i].toDouble();
        yOutside[i] = outsideHumidity[i].toDouble();
        yStates[i] = dehumidifierStates.value(i).toDouble();
    }

    // State background rectangles
    for (auto* rect : m_stateRects)
        m_customPlot->removeItem(rect);
    m_stateRects.clear();

    // Colors per state: unknown, operational, testing, drying, regenerating, error
    static const QColor stateColors[6] = {
        QColor(80,  80,  80,  55),   // 0 unknown      - grey
        QColor(0,  150,  80,  45),   // 1 operational  - green
        QColor(0,  120, 200,  45),   // 2 testing      - blue
        QColor(200, 180,   0,  50),  // 3 drying       - yellow
        QColor(210, 110,   0,  55),  // 4 regenerating - orange
        QColor(200,   0,   0,  70),  // 5 error        - red
    };

    QCPAxis *xAxis = m_axisRect->axis(QCPAxis::atBottom);
    QCPAxis *yAxis = m_axisRect->axis(QCPAxis::atLeft);

    for (int i = 0; i < size; ++i) {
        double x0 = xData[i];
        double x1 = (i + 1 < size) ? xData[i + 1]
                                    : xData[i] + (size > 1 ? xData[i] - xData[i - 1] : 1800.0);
        int stateIdx = qBound(0, static_cast<int>(std::round(yStates[i])), 5);

        QCPItemRect *rect = new QCPItemRect(m_customPlot);
        rect->setLayer("statebg");
        rect->setClipToAxisRect(true);
        rect->setClipAxisRect(m_axisRect);
        rect->topLeft->setAxes(xAxis, yAxis);
        rect->topLeft->setCoords(x0, 105);
        rect->bottomRight->setAxes(xAxis, yAxis);
        rect->bottomRight->setCoords(x1, -5);
        rect->setPen(Qt::NoPen);
        rect->setBrush(QBrush(stateColors[stateIdx]));
        m_stateRects.append(rect);
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
    if (m_customPlot && newGeometry.width() > 0 && newGeometry.height() > 0) {
        m_customPlot->setViewport(QRect(0, 0, static_cast<int>(newGeometry.width()), static_cast<int>(newGeometry.height())));
        m_customPlot->replot();
    }
}

void QCustomPlotItem::hoverMoveEvent(QHoverEvent *event) { Q_UNUSED(event); }
void QCustomPlotItem::mousePressEvent(QMouseEvent *event) { Q_UNUSED(event); }
void QCustomPlotItem::mouseReleaseEvent(QMouseEvent *event) { Q_UNUSED(event); }
void QCustomPlotItem::mouseMoveEvent(QMouseEvent *event) { Q_UNUSED(event); }
void QCustomPlotItem::wheelEvent(QWheelEvent *event) { Q_UNUSED(event); }
