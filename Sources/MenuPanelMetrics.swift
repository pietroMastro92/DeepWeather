import AppKit
import CoreGraphics
import SwiftUI

/// Designed densities so every weather section stays fully visible
/// and the popover keeps air above the Dock on 13-inch displays.
struct MenuPanelMetrics: Equatable {
    var width: CGFloat
    var padding: CGFloat
    var sectionSpacing: CGFloat
    var headerSpacing: CGFloat
    var temperatureFontSize: CGFloat
    var heroIconSize: CGFloat
    var temperatureChartHeight: CGFloat
    var precipitationChartHeight: CGFloat
    var detailColumns: Int
    var detailSpacing: CGFloat
    var hourlySpacing: CGFloat
    var hourlyIconSize: CGFloat
    var forecastSpacing: CGFloat
    var conditionSharesTempLine: Bool
    var settingsFormMaxHeight: CGFloat

    /// 13-inch MacBooks — short enough to clear the Dock by ~80 pt.
    static let compact = MenuPanelMetrics(
        width: 320,
        padding: 12,
        sectionSpacing: 8,
        headerSpacing: 2,
        temperatureFontSize: 34,
        heroIconSize: 44,
        temperatureChartHeight: 68,
        precipitationChartHeight: 28,
        detailColumns: 3,
        detailSpacing: 6,
        hourlySpacing: 2,
        hourlyIconSize: 14,
        forecastSpacing: 4,
        conditionSharesTempLine: true,
        settingsFormMaxHeight: 360
    )

    /// 14–15-inch laptops.
    static let regular = MenuPanelMetrics(
        width: 320,
        padding: 14,
        sectionSpacing: 10,
        headerSpacing: 4,
        temperatureFontSize: 42,
        heroIconSize: 54,
        temperatureChartHeight: 96,
        precipitationChartHeight: 38,
        detailColumns: 3,
        detailSpacing: 8,
        hourlySpacing: 4,
        hourlyIconSize: 16,
        forecastSpacing: 6,
        conditionSharesTempLine: false,
        settingsFormMaxHeight: 420
    )

    /// 16-inch and larger displays.
    static let roomy = MenuPanelMetrics(
        width: 360,
        padding: 16,
        sectionSpacing: 12,
        headerSpacing: 6,
        temperatureFontSize: 48,
        heroIconSize: 60,
        temperatureChartHeight: 112,
        precipitationChartHeight: 44,
        detailColumns: 3,
        detailSpacing: 10,
        hourlySpacing: 6,
        hourlyIconSize: 18,
        forecastSpacing: 8,
        conditionSharesTempLine: false,
        settingsFormMaxHeight: 480
    )

    /// Space kept between the popover bottom and the Dock / screen edge.
    static let edgeClearance: CGFloat = 80

    static func current(screen: NSScreen? = .main) -> MenuPanelMetrics {
        let visible = screen?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1280, height: 800)
        let available = visible.height - edgeClearance
        var metrics: MenuPanelMetrics
        if available >= 960 {
            metrics = .roomy
        } else if available >= 800 {
            metrics = .regular
        } else {
            metrics = .compact
        }
        if visible.width >= 1440 {
            metrics.width = max(metrics.width, 360)
        }
        metrics.settingsFormMaxHeight = max(240, available - 260)
        return metrics
    }
}

extension EnvironmentValues {
    @Entry var menuPanelMetrics: MenuPanelMetrics = .regular
}
