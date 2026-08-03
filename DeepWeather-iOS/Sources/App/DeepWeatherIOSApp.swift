import SwiftUI

@main
struct DeepWeatherIOSApp: App {
    @State private var store = WeatherStore()
    @State private var locationManager = LocationManager()
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView()
                } else {
                    DashboardView(store: store, locationManager: locationManager)
                }
            }
            .task { await boot() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await refreshWeather() }
            }
        }
    }

    @MainActor
    private func boot() async {
        if store.selectedLocationID == nil {
            if let coordinate = await locationManager.requestLocation() {
                store.setAutomaticCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
        }
        let refreshTask = Task { await refreshWeather() }
        try? await Task.sleep(for: .milliseconds(1600))
        withAnimation(.easeInOut(duration: 0.4)) { showSplash = false }
        await refreshTask.value
        store.startAutoRefresh(immediately: false)
    }

    @MainActor
    private func refreshWeather() async {
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
