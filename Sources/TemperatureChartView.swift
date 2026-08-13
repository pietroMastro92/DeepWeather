import SwiftUI
import Charts

struct TemperatureChartView: View {
    let points: [WeatherStore.ChartPoint]
    let midnights: [Date]
    let now: Date
    let unitSymbol: String
    let observedTemp: Double?

    @Environment(\.menuPanelMetrics) private var metrics

    private static let areaGradient = LinearGradient(
        colors: [Color.orange.opacity(0.30), Color.orange.opacity(0.04)],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Temperature (\(unitSymbol))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(points) { point in
                if let temperature = point.temperature {
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Temperature", temperature)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Self.areaGradient)
                    .accessibilityHidden(true)

                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Temperature", temperature)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                if let first = points.first?.date, let last = points.last?.date,
                   now >= first, now <= last {
                    RuleMark(x: .value("Now", now))
                        .foregroundStyle(.secondary.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .accessibilityHidden(true)

                    if let observedTemp {
                        PointMark(
                            x: .value("Time", now),
                            y: .value("Observed", observedTemp)
                        )
                        .foregroundStyle(Color.orange)
                        .symbolSize(70)
                        .accessibilityLabel("Current temperature \(observedTemp, format: .number)")
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3))
            }
            .chartXAxis {
                AxisMarks(values: midnights) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: metrics.temperatureChartHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Temperature forecast")
            .accessibilityValue(accessibilityValue)
        }
    }

    private var accessibilityValue: String {
        guard let first = points.first(where: { $0.temperature != nil })?.temperature,
              let last = points.last(where: { $0.temperature != nil })?.temperature
        else { return "No temperature data" }
        return "From \(first.formatted(.number.precision(.fractionLength(0)))) to \(last.formatted(.number.precision(.fractionLength(0)))) \(unitSymbol)"
    }
}
