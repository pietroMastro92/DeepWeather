import SwiftUI

struct AnimatedWeatherIconView: View {
    let symbol: String
    let kind: WeatherAnimationKind
    let accessibilityLabel: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = false

    var body: some View {
        Group {
            if reduceMotion {
                staticIcon
            } else {
                animatedIcon
            }
        }
        .id("\(symbol)-\(kind)")
        .accessibilityLabel(accessibilityLabel)
    }

    private var staticIcon: some View {
        Image(systemName: symbol)
            .font(.system(size: 60, weight: .light))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var animatedIcon: some View {
        switch kind {
        case .sun:
            staticIcon
                .rotationEffect(.degrees(phase ? 360 : 0))
                .onAppear(perform: startLoop)
        case .moon:
            staticIcon
                .scaleEffect(phase ? 1.06 : 1.0)
                .onAppear(perform: startLoop)
        case .cloud:
            staticIcon
                .offset(x: phase ? 3 : -3)
                .onAppear(perform: startLoop)
        case .fog:
            staticIcon
                .offset(x: phase ? 2 : -2)
                .onAppear(perform: startLoop)
        case .rain:
            staticIcon
                .symbolEffect(.variableColor.iterative, options: .repeating)
        case .snow:
            staticIcon
                .symbolEffect(.variableColor.iterative, options: .repeating)
        case .storm:
            staticIcon
                .symbolEffect(.variableColor, options: .repeating)
        }
    }

    private func startLoop() {
        phase = false
        let animation: Animation
        switch kind {
        case .sun:
            animation = .linear(duration: 20).repeatForever(autoreverses: false)
        case .moon:
            animation = .easeInOut(duration: 4).repeatForever(autoreverses: true)
        case .cloud:
            animation = .easeInOut(duration: 5).repeatForever(autoreverses: true)
        case .fog:
            animation = .easeInOut(duration: 7).repeatForever(autoreverses: true)
        case .rain, .snow, .storm:
            return
        }
        withAnimation(animation) {
            phase = true
        }
    }
}
