import SwiftUI

struct WaitingDotsView: View {
    @State private var animate = false
    private let count = 3

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(Color.fillitPrimary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animate ? 1.3 : 0.7)
                    .opacity(animate ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.2),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}
