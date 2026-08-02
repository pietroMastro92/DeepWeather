import SwiftUI

struct CurrentConditionsView: View {
    let locationName: String
    let locationDetail: String
    let tempText: String
    let conditionText: String
    let iconName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(locationName)
                    .font(.headline)
                    .lineLimit(1)
                Text(locationDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(tempText)
                    .font(.system(size: 46, weight: .light, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.default, value: tempText)

                Text(conditionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            heroIcon
        }
        .frame(minHeight: 96)
    }

    private var heroIcon: some View {
        Group {
            if #available(macOS 26, *) {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .frame(width: 64, height: 64)
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))
            } else {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .frame(width: 64, height: 64)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
        }
        .padding(.top, 2)
    }
}
