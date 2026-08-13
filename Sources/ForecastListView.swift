import SwiftUI

struct ForecastListView: View {
    let items: [WeatherStore.DayItem]
    @Environment(\.menuPanelMetrics) private var metrics

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.forecastSpacing) {
            ForEach(items) { day in
                ForecastRowView(day: day)
            }
        }
    }
}

private struct ForecastRowView: View {
    let day: WeatherStore.DayItem

    var body: some View {
        HStack(spacing: 8) {
            Text(day.title)
                .font(.caption)
                .frame(width: 48, alignment: .leading)

            Image(systemName: day.symbol)
                .font(.system(size: 13))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            if day.precipChance > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                    Text("\(day.precipChance)%")
                }
                .font(.caption2)
                .foregroundStyle(.blue)
                .frame(width: 48, alignment: .leading)
            } else {
                Text(" ")
                    .font(.caption2)
                    .frame(width: 48, alignment: .leading)
            }

            Spacer()

            Text(day.minText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Text(day.maxText)
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }
}
