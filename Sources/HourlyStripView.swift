import SwiftUI

struct HourlyStripView: View {
    let items: [WeatherStore.HourlyItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hourly")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(items) { item in
                            HourlyItemView(item: item)
                                .id(item.id)
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .onAppear {
                    centerScroll(in: proxy)
                }
                .help("Scroll horizontally to see more hours")
            }
        }
    }

    /// Start in the middle cycle so the strip can be scrolled in both
    /// directions, wrapping around the hourly data like a loop.
    private func centerScroll(in proxy: ScrollViewProxy) {
        guard !items.isEmpty else { return }
        let middleIndex = items.count / 2
        proxy.scrollTo(items[middleIndex].id, anchor: .leading)
    }
}

private struct HourlyItemView: View {
    let item: WeatherStore.HourlyItem

    var body: some View {
        VStack(spacing: 5) {
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
        .frame(width: 44)
    }
}
