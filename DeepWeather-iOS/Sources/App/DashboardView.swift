import SwiftUI

struct DashboardView: View {
    @Bindable var store: WeatherStore
    var locationManager: LocationManager

    @State private var showSettings = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isWide: Bool { horizontalSizeClass == .regular }

    var body: some View {
        NavigationStack {
            content
                .background(Color(.systemGroupedBackground))
                .navigationTitle(store.locationName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel(String(localized: "Settings"))
                    }
                }
                .refreshable { await refresh() }
                .sheet(isPresented: $showSettings) {
                    IOSSettingsView(store: store, locationManager: locationManager)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.weather != nil {
            ScrollView {
                Group {
                    if isWide {
                        wideLayout
                    } else {
                        narrowLayout
                    }
                }
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        } else if let message = store.errorMessage {
            ContentUnavailableView {
                Label(String(localized: "Couldn't load weather"), systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button(String(localized: "Retry")) {
                    Task { await refresh() }
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ProgressView(String(localized: "Loading weather…"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Single column (iPhone / compact)

    private var narrowLayout: some View {
        VStack(alignment: .leading, spacing: 16) {
            currentConditionsCard
            if store.weather != nil, let message = store.errorMessage {
                ErrorBannerView(message: message)
            }
            SectionCard {
                DetailGridView(items: store.detailItems)
            }
            SectionCard {
                TemperatureChartView(
                    points: store.chartPoints,
                    midnights: store.chartMidnights,
                    now: Date(),
                    unitSymbol: store.temperatureUnitSymbol,
                    observedTemp: store.currentTempValue
                )
            }
            SectionCard {
                PrecipitationChartView(points: store.chartPoints, midnights: store.chartMidnights)
            }
            SectionCard {
                MoonPhaseView(items: store.moonItems)
            }
            SectionCard {
                HourlyStripView(items: store.upcomingHours)
            }
            SectionCard {
                ForecastListView(items: store.dayItems)
            }
        }
    }

    // MARK: - Two columns (iPad / regular)

    private var wideLayout: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                currentConditionsCard
                if store.weather != nil, let message = store.errorMessage {
                    ErrorBannerView(message: message)
                }
                SectionCard {
                    DetailGridView(items: store.detailItems)
                }
                SectionCard {
                    MoonPhaseView(items: store.moonItems)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 16) {
                SectionCard {
                    TemperatureChartView(
                        points: store.chartPoints,
                        midnights: store.chartMidnights,
                        now: Date(),
                        unitSymbol: store.temperatureUnitSymbol,
                        observedTemp: store.currentTempValue
                    )
                }
                SectionCard {
                    PrecipitationChartView(points: store.chartPoints, midnights: store.chartMidnights)
                }
                SectionCard {
                    HourlyStripView(items: store.upcomingHours)
                }
                SectionCard {
                    ForecastListView(items: store.dayItems)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var currentConditionsCard: some View {
        SectionCard {
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
        }
    }

    private func refresh() async {
        if store.selectedLocationID == nil {
            if let coordinate = await locationManager.requestLocation() {
                store.setAutomaticCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
        }
        await store.refresh()
        await NotificationManager.reschedule(
            weather: store.weather,
            useMetric: store.useMetric,
            dailyEnabled: store.dailySummaryEnabled,
            dailyHour: store.dailySummaryHour,
            rainAlertEnabled: store.rainAlertEnabled
        )
    }
}

private struct SectionCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
