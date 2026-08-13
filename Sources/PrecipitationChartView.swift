import SwiftUI
import Charts

struct PrecipitationChartView: View {
    let points: [WeatherStore.ChartPoint]
    let midnights: [Date]
    @Environment(\.menuPanelMetrics) private var metrics

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Precipitation")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(points) { point in
                BarMark(
                    x: .value("Time", point.date),
                    y: .value("Chance", point.precipChance)
                )
                .foregroundStyle(Color.blue.opacity(0.6))
                .cornerRadius(2)
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: midnights) { _ in
                    AxisGridLine()
                }
            }
            .frame(height: metrics.precipitationChartHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Precipitation chance")
            .accessibilityValue(accessibilityValue)
        }
    }

    private var accessibilityValue: String {
        let peak = points.map(\.precipChance).max() ?? 0
        return peak > 0 ? "Peak \(peak) percent" : "No rain expected"
    }
}
