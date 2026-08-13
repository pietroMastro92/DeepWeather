import SwiftUI

struct HourlyStripView: View {
    let items: [WeatherStore.HourlyItem]
    @Environment(\.menuPanelMetrics) private var metrics

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hourly")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: metrics.hourlySpacing) {
                ForEach(items) { item in
                    HourlyItemView(item: item, iconSize: metrics.hourlyIconSize)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct HourlyItemView: View {
    let item: WeatherStore.HourlyItem
    let iconSize: CGFloat

    var body: some View {
        VStack(spacing: 2) {
            Text(item.hourText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Image(systemName: item.symbol)
                .font(.system(size: iconSize))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .frame(height: iconSize + 1)

            Text(item.tempText)
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()

            Text(item.precipChance > 0 ? "\(item.precipChance)%" : " ")
                .font(.caption2)
                .foregroundStyle(item.precipChance > 0 ? .blue : .clear)
        }
    }
}
