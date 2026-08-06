import SwiftUI
import AppKit

struct MenuView: View {
    @Bindable var store: WeatherStore
    let updateChecker: UpdateChecker
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CurrentConditionsView(
                locationName: store.locationName,
                locationDetail: store.locationDetail,
                tempText: store.currentTempText,
                conditionText: store.currentConditionText,
                iconName: store.menuBarIcon,
                iconKind: store.menuBarAnimationKind,
                locations: store.savedLocations,
                selectedLocationID: store.selectedLocationID,
                onSelectLocation: { id in
                    store.selectSavedLocation(id)
                }
            )

            if let message = store.errorMessage {
                ErrorBannerView(message: message)
            }

            if updateChecker.updateAvailable, let version = updateChecker.latestVersion {
                UpdateBannerView(
                    version: version,
                    isDownloading: updateChecker.isDownloading,
                    progress: updateChecker.downloadProgress,
                    onUpdate: { Task { await updateChecker.downloadAndInstall() } }
                )
            }

            if showSettings {
                Divider()
                SettingsView(
                    store: store,
                    updateChecker: updateChecker,
                    onDone: closeSettings
                )
            } else if store.weather != nil {
                WeatherDataSectionView(store: store)
            } else if store.isLoading {
                loadingSection
            }

            Divider()
            MenuFooterView(store: store, showSettings: $showSettings)
        }
        .padding(14)
        .frame(width: 320)
    }

    private var loadingSection: some View {
        HStack(spacing: 8) {
            Spacer()
            ProgressView().controlSize(.small)
            Text("Loading…")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 20)
    }

    private func closeSettings() {
        withAnimation(.easeInOut(duration: 0.15)) {
            showSettings = false
        }
    }
}

private struct WeatherDataSectionView: View {
    let store: WeatherStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            DetailGridView(items: store.detailItems)
            Divider()
            TemperatureChartView(
                points: store.chartPoints,
                midnights: store.chartMidnights,
                now: Date(),
                unitSymbol: store.temperatureUnitSymbol,
                observedTemp: store.currentTempValue
            )
            PrecipitationChartView(
                points: store.chartPoints,
                midnights: store.chartMidnights
            )
            Divider()
            MoonPhaseView(items: store.moonItems)
            Divider()
            HourlyStripView(items: store.upcomingHours)
            Divider()
            ForecastListView(items: store.dayItems)
        }
    }
}

private struct MenuFooterView: View {
    @Bindable var store: WeatherStore
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 2) {
            updatedLabel
            Spacer()
            refreshButton
            settingsButton
            quitButton
        }
    }

    private var updatedLabel: some View {
        Group {
            if let updated = store.lastUpdated {
                Text("Updated \(updated, format: .dateTime.hour().minute())")
            } else {
                Text("Not updated yet")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var refreshButton: some View {
        Button {
            Task { await store.refresh() }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .buttonStyle(.borderless)
        .help("Refresh now")
        .keyboardShortcut("r")
    }

    private var settingsButton: some View {
        Button(action: toggleSettings) {
            Image(systemName: "gearshape")
                .foregroundStyle(showSettings ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.borderless)
        .help(showSettings ? "Back to weather" : "Settings")
    }

    private var quitButton: some View {
        Button(action: quit) {
            Image(systemName: "power")
        }
        .buttonStyle(.borderless)
        .help("Quit DeepWeather")
    }

    private func toggleSettings() {
        withAnimation(.easeInOut(duration: 0.15)) {
            showSettings.toggle()
        }
    }

    private func quit() {
        NSApp.terminate(nil)
    }
}

struct ErrorBannerView: View {
    let message: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle")
            Text(message)
                .font(.caption)
            Spacer()
        }
        .foregroundStyle(.orange)
    }
}
