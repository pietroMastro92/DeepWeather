import SwiftUI
import AppKit

struct MenuView: View {
    @Bindable var store: WeatherStore
    let updateChecker: UpdateChecker
    var metricsOverride: MenuPanelMetrics?
    @State private var showSettings: Bool
    @State private var metrics = MenuPanelMetrics.current()

    init(
        store: WeatherStore,
        updateChecker: UpdateChecker,
        metricsOverride: MenuPanelMetrics? = nil,
        showSettings: Bool = false
    ) {
        self.store = store
        self.updateChecker = updateChecker
        self.metricsOverride = metricsOverride
        _showSettings = State(initialValue: showSettings)
    }

    private var panelMetrics: MenuPanelMetrics {
        metricsOverride ?? metrics
    }

    var body: some View {
        VStack(alignment: .leading, spacing: panelMetrics.sectionSpacing) {
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

            MenuMiddleContent(
                store: store,
                updateChecker: updateChecker,
                showSettings: showSettings,
                onCloseSettings: closeSettings
            )

            Divider()
            MenuFooterView(
                lastUpdated: store.lastUpdated,
                showSettings: $showSettings,
                onRefresh: { await store.refresh() },
                onQuit: quit
            )
        }
        .padding(panelMetrics.padding)
        .frame(width: panelMetrics.width)
        .fixedSize(horizontal: true, vertical: true)
        .environment(\.menuPanelMetrics, panelMetrics)
        .onAppear {
            if metricsOverride == nil {
                metrics = MenuPanelMetrics.current()
            }
        }
    }

    private func closeSettings() {
        withAnimation(.easeInOut(duration: 0.15)) {
            showSettings = false
        }
    }

    private func quit() {
        NSApp.terminate(nil)
    }
}

private struct MenuMiddleContent: View {
    @Bindable var store: WeatherStore
    let updateChecker: UpdateChecker
    let showSettings: Bool
    let onCloseSettings: () -> Void
    @Environment(\.menuPanelMetrics) private var metrics

    var body: some View {
        if showSettings {
            ScrollView {
                SettingsView(
                    store: store,
                    updateChecker: updateChecker,
                    onDone: onCloseSettings
                )
            }
            .scrollIndicators(.automatic)
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: metrics.settingsFormMaxHeight)
        } else if store.weather != nil {
            WeatherDataSectionView(
                detailItems: store.detailItems,
                chartPoints: store.chartPoints,
                chartMidnights: store.chartMidnights,
                now: store.referenceNow,
                unitSymbol: store.temperatureUnitSymbol,
                observedTemp: store.currentTempValue,
                moonItems: store.moonItems,
                upcomingHours: store.upcomingHours,
                dayItems: store.dayItems
            )
        } else if store.isLoading {
            LoadingSection()
        }
    }
}

private struct WeatherDataSectionView: View {
    let detailItems: [WeatherStore.DetailItem]
    let chartPoints: [WeatherStore.ChartPoint]
    let chartMidnights: [Date]
    let now: Date
    let unitSymbol: String
    let observedTemp: Double?
    let moonItems: [WeatherStore.MoonItem]
    let upcomingHours: [WeatherStore.HourlyItem]
    let dayItems: [WeatherStore.DayItem]

    @Environment(\.menuPanelMetrics) private var metrics

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
            if !detailItems.isEmpty {
                DetailGridView(items: detailItems)
            }
            TemperatureChartView(
                points: chartPoints,
                midnights: chartMidnights,
                now: now,
                unitSymbol: unitSymbol,
                observedTemp: observedTemp
            )
            PrecipitationChartView(
                points: chartPoints,
                midnights: chartMidnights
            )
            MoonPhaseView(items: moonItems)
            HourlyStripView(items: upcomingHours)
            ForecastListView(items: dayItems)
        }
    }
}

private struct LoadingSection: View {
    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            ProgressView().controlSize(.small)
            Text("Loading…")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 20)
    }
}

private struct MenuFooterView: View {
    let lastUpdated: Date?
    @Binding var showSettings: Bool
    let onRefresh: () async -> Void
    let onQuit: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            updatedLabel
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                Task { await onRefresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh now")
            .keyboardShortcut("r")

            Button(action: toggleSettings) {
                Image(systemName: "gearshape")
                    .foregroundStyle(showSettings ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)
            .help(showSettings ? "Back to weather" : "Settings")

            Button(action: onQuit) {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit DeepWeather")
        }
    }

    private var updatedLabel: Text {
        if let lastUpdated {
            Text("Updated \(lastUpdated, format: .dateTime.hour().minute())")
        } else {
            Text("Not updated yet")
        }
    }

    private func toggleSettings() {
        withAnimation(.easeInOut(duration: 0.15)) {
            showSettings.toggle()
        }
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
