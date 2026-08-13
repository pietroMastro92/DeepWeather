import SwiftUI

struct CurrentConditionsView: View {
    let locationName: String
    let locationDetail: String
    let tempText: String
    let conditionText: String
    let iconName: String
    let iconKind: WeatherAnimationKind
    let locations: [SavedLocation]
    let selectedLocationID: String?
    let onSelectLocation: (String?) -> Void

    @Environment(\.menuPanelMetrics) private var metrics

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: metrics.headerSpacing) {
                LocationSwitcherMenu(
                    locationName: locationName,
                    locations: locations,
                    selectedLocationID: selectedLocationID,
                    onSelect: onSelectLocation
                )
                Text(locationDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if metrics.conditionSharesTempLine {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(tempText)
                            .font(.system(size: metrics.temperatureFontSize, weight: .light, design: .rounded))
                        Text(conditionText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .contentTransition(.numericText())
                    .animation(.default, value: tempText)
                } else {
                    Text(tempText)
                        .font(.system(size: metrics.temperatureFontSize, weight: .light, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.default, value: tempText)

                    Text(conditionText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            AnimatedWeatherIconView(
                symbol: iconName,
                kind: iconKind,
                accessibilityLabel: conditionText,
                size: metrics.heroIconSize
            )
            .padding(.top, 2)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct LocationSwitcherMenu: View {
    let locationName: String
    let locations: [SavedLocation]
    let selectedLocationID: String?
    let onSelect: (String?) -> Void

    var body: some View {
        Menu {
            Button {
                onSelect(nil)
            } label: {
                Label("Automatic (IP)", systemImage: selectedLocationID == nil ? "checkmark" : "location")
            }

            if !locations.isEmpty {
                Divider()
                ForEach(locations) { location in
                    Button {
                        onSelect(location.id)
                    } label: {
                        Label(location.name, systemImage: selectedLocationID == location.id ? "checkmark" : "mappin")
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(locationName)
                    .font(.headline)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .help("Switch location")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
