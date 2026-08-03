import SwiftUI
import Charts

struct PrecipitationChartView: View {
    let points: [WeatherStore.ChartPoint]
    let midnights: [Date]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
            .frame(height: 45)
        }
    }
}
