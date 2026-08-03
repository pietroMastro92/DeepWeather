import SwiftUI

struct AnimatedWeatherIconView: View {
    let symbol: String
    let kind: WeatherAnimationKind
    let accessibilityLabel: String

    var body: some View {
        Group {
            switch kind {
            case .sun, .moon:
                baseIcon
                    .symbolEffect(.pulse, options: .repeating)
            case .rain, .snow:
                baseIcon
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            case .storm:
                baseIcon
                    .symbolEffect(.variableColor, options: .repeating)
            case .cloud, .fog:
                baseIcon
            }
        }
        .id("\(symbol)-\(kind)")
        .accessibilityLabel(accessibilityLabel)
    }

    private var baseIcon: some View {
        Image(systemName: symbol)
            .font(.system(size: 60, weight: .light))
            .symbolRenderingMode(.multicolor)
    }
}
