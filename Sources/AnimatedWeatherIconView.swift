import SwiftUI

struct AnimatedWeatherIconView: View {
    let symbol: String
    let kind: WeatherAnimationKind
    let accessibilityLabel: String
    var size: CGFloat = 60

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size, weight: .light))
            .symbolRenderingMode(.multicolor)
            .modifier(WeatherSymbolEffect(kind: kind))
            .id("\(symbol)-\(kind)")
            .accessibilityLabel(accessibilityLabel)
    }
}

private struct WeatherSymbolEffect: ViewModifier {
    let kind: WeatherAnimationKind

    func body(content: Content) -> some View {
        switch kind {
        case .sun, .moon:
            content.symbolEffect(.pulse, options: .repeating)
        case .rain, .snow:
            content.symbolEffect(.variableColor.iterative, options: .repeating)
        case .storm:
            content.symbolEffect(.variableColor, options: .repeating)
        case .cloud, .fog:
            content
        }
    }
}
