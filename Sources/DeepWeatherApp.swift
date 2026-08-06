import SwiftUI
import AppKit

@main
struct DeepWeatherApp: App {
    @State private var store = WeatherStore()

    var body: some Scene {
        MenuBarExtra {
            MenuView(store: store)
                .task { store.startAutoRefresh() }
                .onAppear(perform: disablePanelDragging)
        } label: {
            Label(store.menuBarTemp, systemImage: store.menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }

    /// MenuBarExtra panels can be dragged by their background, which steals
    /// mouse drags from scrollable content (e.g. charts).
    private func disablePanelDragging() {
        if let panel = NSApp.windows.first(where: { $0 is NSPanel }) {
            panel.isMovableByWindowBackground = false
        }
    }
}
