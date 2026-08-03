import SwiftUI

struct HourlyStripView: View {
    let items: [WeatherStore.HourlyItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hourly")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        HourlyItemView(item: item)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .help("Scroll horizontally to see more hours")
        }
    }
}

private struct HourlyItemView: View {
    let item: WeatherStore.HourlyItem

    var body: some View {
        VStack(spacing: 4) {
            Text(item.dayTitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(item.hourText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Image(systemName: item.symbol)
                .font(.system(size: 18))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .frame(height: 20)

            Text(item.tempText)
                .font(.callout)
                .fontWeight(.medium)

            if item.precipChance > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                    Text("\(item.precipChance)%")
                }
                .font(.caption2)
                .foregroundStyle(.blue)
            } else {
                Text(" ")
                    .font(.caption2)
            }
        }
        .frame(width: 46)
    }
}
