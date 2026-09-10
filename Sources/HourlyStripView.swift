import SwiftUI

struct HourlyStripView: View {
    let items: [WeatherStore.HourlyItem]
    var selectedDayTitle: String?
    @Environment(\.menuPanelMetrics) private var metrics

    private var displayItems: [WeatherStore.HourlyItem] {
        if items.count > 8 {
            return items.filter { item in
                let hour = Int(item.hourText.prefix(2)) ?? 0
                return hour % 3 == 0
            }
        }
        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedDayTitle.map { "Hourly · \($0)" } ?? "Hourly")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: metrics.hourlySpacing) {
                ForEach(displayItems) { item in
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
                .lineLimit(1)

            Image(systemName: item.symbol)
                .font(.system(size: iconSize))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .frame(height: iconSize + 1)

            Text(item.tempText)
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
                .lineLimit(1)

            Text(item.precipChance > 0 ? "\(item.precipChance)%" : " ")
                .font(.caption2)
                .foregroundStyle(item.precipChance > 0 ? .blue : .clear)
                .lineLimit(1)
        }
    }
}
