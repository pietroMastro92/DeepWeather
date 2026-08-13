import SwiftUI

struct SettingsView: View {
    @Bindable var store: WeatherStore
    let updateChecker: UpdateChecker
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Done", action: onDone)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .keyboardShortcut(.cancelAction)
            }

            Form {
                Section("Locations") {
                    LocationSearchView(store: store)
                }

                Section {
                    Picker("Units", selection: $store.useMetric) {
                        Text("Metric (°C, km/h)").tag(true)
                        Text("Imperial (°F, mph)").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .accessibilityLabel("Units")
                } header: {
                    Text("Display")
                } footer: {
                    Text("Units change how the Glance shows numbers. Measurements hide cells in the detail grid.")
                }

                Section("Conditions") {
                    ForEach(MeasurementID.conditions) { id in
                        measurementToggle(id)
                    }
                }

                Section("Sun & Moon Times") {
                    ForEach(MeasurementID.sunAndMoonTimes) { id in
                        measurementToggle(id)
                    }
                }

                Section("Refresh") {
                    Picker("Refresh", selection: $store.refreshIntervalMinutes) {
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                        Text("60 min").tag(60)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .accessibilityLabel("Refresh")
                }

                Section {
                    Toggle("Launch at login", isOn: launchAtLoginBinding)
                    Text("Open DeepWeather automatically when you log in to this Mac.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let error = store.launchAtLoginError {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Startup")
                }

                Section("About") {
                    VersionInfoView(
                        currentVersion: UpdateChecker.currentVersion,
                        latestVersion: updateChecker.latestVersion,
                        updateAvailable: updateChecker.updateAvailable,
                        isChecking: updateChecker.isChecking,
                        onCheck: { Task { await updateChecker.checkForUpdates() } }
                    )
                    if let error = updateChecker.errorMessage {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
    }

    private func measurementToggle(_ id: MeasurementID) -> some View {
        Toggle(id.title, isOn: Binding(
            get: { store.isMeasurementVisible(id) },
            set: { store.setMeasurementVisible(id, $0) }
        ))
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { store.launchAtLogin },
            set: { store.setLaunchAtLogin($0) }
        )
    }
}
