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

            if !store.alerts.isEmpty && !showSettings {
                WeatherAlertCardView(alerts: store.alerts)
            }

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
                showSettings: showSettings
            )

            Divider()
            MenuFooterView(
                lastUpdated: store.lastUpdated,
                showSettings: $showSettings,
                onRefresh: { await store.refresh() },
                onCloseSettings: {
                    Task {
                        await store.refresh()
                    }
                }
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
}

private struct MenuMiddleContent: View {
    @Bindable var store: WeatherStore
    let updateChecker: UpdateChecker
    let showSettings: Bool
    @Environment(\.menuPanelMetrics) private var metrics

    var body: some View {
        if showSettings {
            ScrollView {
                SettingsView(
                    store: store,
                    updateChecker: updateChecker
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
    let onCloseSettings: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            if showSettings {
                Text("Settings")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            } else {
                updatedLabel
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !showSettings {
                Button {
                    Task { await onRefresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh now")
                .keyboardShortcut("r")
            }

            Button(action: toggleSettings) {
                Image(systemName: showSettings ? "checkmark.circle.fill" : "gearshape")
                    .font(showSettings ? .system(size: 15, weight: .semibold) : .system(size: 13))
                    .foregroundStyle(showSettings ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)
            .help(showSettings ? "Save & Close Settings" : "Settings")
            .keyboardShortcut(showSettings ? .cancelAction : .defaultAction)
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
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if showSettings {
                showSettings = false
                onCloseSettings()
            } else {
                showSettings = true
            }
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
