import SwiftUI

/// Severe weather & Civil Protection alert card for the macOS menu panel
struct WeatherAlertCardView: View {
    let alerts: [WeatherAlert]
    @State private var isExpanded = false

    private var primaryAlert: WeatherAlert? {
        alerts.first
    }

    private var highestSeverityColor: Color {
        if alerts.contains(where: { $0.severity == .warning }) {
            return Color(red: 1.0, green: 0.45, blue: 0.15)
        }
        return Color(red: 1.0, green: 0.80, blue: 0.20)
    }

    var body: some View {
        if let primary = primaryAlert {
            VStack(alignment: .leading, spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(highestSeverityColor)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(primary.headline)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.primary)

                            Text(primary.title)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(isExpanded ? nil : 1)
                        }

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(alerts) { alert in
                            VStack(alignment: .leading, spacing: 4) {
                                if alerts.count > 1 {
                                    HStack(spacing: 4) {
                                        Image(systemName: alert.category.iconName)
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(alert.severity.color)
                                        Text(alert.title)
                                            .font(.caption2.weight(.semibold))
                                    }
                                }

                                Text(alert.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                HStack {
                                    Label(alert.timeWindow, systemImage: "clock")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Text(alert.source)
                                        .font(.system(size: 9))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.top, 2)
                            }
                            if alert.id != alerts.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(highestSeverityColor.opacity(0.12))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(highestSeverityColor.opacity(0.4), lineWidth: 1)
            }
        }
    }
}
