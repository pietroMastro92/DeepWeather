import SwiftUI

struct DetailGridView: View {
    let items: [WeatherStore.DetailItem]
    @Environment(\.menuPanelMetrics) private var metrics

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 8, alignment: .leading),
            count: metrics.detailColumns
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: metrics.detailSpacing) {
            ForEach(items) { item in
                HStack(alignment: .top, spacing: 5) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 14, alignment: .center)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(item.value)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
