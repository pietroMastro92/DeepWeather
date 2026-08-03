import SwiftUI

struct SplashView: View {
    @State private var animated = false

    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()

            VStack(spacing: 16) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .scaleEffect(animated ? 1 : 0.7)
                    .opacity(animated ? 1 : 0)

                Text("DeepWeather")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .opacity(animated ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animated = true
            }
        }
    }
}
