import SwiftUI

@main
struct DeepWeatherApp: App {
    @State private var store = WeatherStore()

    var body: some Scene {
        MenuBarExtra {
            MenuView(store: store)
                .task { store.startAutoRefresh() }
        } label: {
            Label(store.menuBarTemp, systemImage: store.menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }
}
