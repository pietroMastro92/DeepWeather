import SwiftUI

struct HourlyStripView: View {
    let items: [WeatherStore.HourlyItem]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hourly")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items) { item in
                    HourlyItemView(item: item)
                }
            }
        }
    }
}

private struct HourlyItemView: View {
    let item: WeatherStore.HourlyItem

    var body: some View {
        VStack(spacing: 4) {
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
    }
}
