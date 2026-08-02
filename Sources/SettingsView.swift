import SwiftUI

struct SettingsView: View {
    @Bindable var store: WeatherStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)

            LocationSearchView(store: store)

            Divider()

            SegmentedSettingSection(
                title: "Units",
                selection: $store.useMetric,
                options: [
                    ("Metric (°C, km/h)", true),
                    ("Imperial (°F, mph)", false)
                ]
            )

            SegmentedSettingSection(
                title: "Refresh",
                selection: $store.refreshIntervalMinutes,
                options: [
                    ("10 min", 10),
                    ("15 min", 15),
                    ("30 min", 30),
                    ("60 min", 60)
                ]
            )

            HStack {
                Spacer()
                applyButton
            }
        }
    }

    private var applyButton: some View {
        Group {
            if #available(macOS 26, *) {
                Button("Apply", action: apply)
                    .buttonStyle(.glassProminent)
            } else {
                Button("Apply", action: apply)
                    .buttonStyle(.borderedProminent)
            }
        }
        .controlSize(.small)
        .keyboardShortcut(.defaultAction)
    }

    private func apply() {
        store.applySettings()
    }
}

private struct SegmentedSettingSection<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [(label: String, value: Value)]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.callout)

            Picker("", selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
    }
}
