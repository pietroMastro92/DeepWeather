import SwiftUI

struct SettingsView: View {
    @Bindable var store: WeatherStore
    let updateChecker: UpdateChecker

    var body: some View {
        Form {
            Section("Locations") {
                LocationSearchView(store: store)
            }

            Section {
                Picker("Provider", selection: $store.weatherProvider) {
                    ForEach(WeatherProvider.allCases) { prov in
                        Text(prov.displayName).tag(prov)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Weather Provider")

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.weatherProvider.displayName)
                        .font(.caption.weight(.medium))
                    Text(store.weatherProvider.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Weather Data Source")
            } footer: {
                Text("Auto mode uses direct official meteorological models with anomaly protection and failover.")
            }

            Section {
                Picker("Units", selection: $store.useMetric) {
                    Text("Metric (°C, km/h)").tag(true)
                    Text("Imperial (°F, mph)").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityLabel("Units")

                Divider()

                ForEach(MeasurementID.conditions) { id in
                    measurementToggle(id)
                }
            } header: {
                Text("Display & Conditions")
            } footer: {
                Text("Customize units and visible measurement cells in the detail grid.")
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Refresh Frequency")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

                Toggle("Launch at login", isOn: launchAtLoginBinding)
                if let error = store.launchAtLoginError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                Divider()

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
            } header: {
                Text("System & Startup")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
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
