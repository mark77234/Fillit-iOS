import SwiftUI

struct CountdownView: View {
    let deadline: Date
    @State private var remaining: String = ""
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption)
            Text(remaining)
                .font(.caption.monospacedDigit())
        }
        .foregroundStyle(isUrgent ? Color.fillitAccent1 : .secondary)
        .onAppear { updateRemaining() }
        .onReceive(timer) { _ in updateRemaining() }
    }

    private var isUrgent: Bool {
        deadline.timeIntervalSinceNow < 300
    }

    private func updateRemaining() {
        remaining = deadline.timeUntilString
    }
}
