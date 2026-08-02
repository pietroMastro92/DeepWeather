import SwiftUI

struct SettingsView: View {
    @Bindable var store: WeatherStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)

            LocationSearchView(store: store)

            Divider()

            LabeledContent("Units") {
                Picker("", selection: $store.useMetric) {
                    Text("Metric (°C, km/h)").tag(true)
                    Text("Imperial (°F, mph)").tag(false)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 216)
            }

            LabeledContent("Refresh") {
                Picker("", selection: $store.refreshIntervalMinutes) {
                    Text("10 min").tag(10)
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                    Text("60 min").tag(60)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 216)
            }

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
