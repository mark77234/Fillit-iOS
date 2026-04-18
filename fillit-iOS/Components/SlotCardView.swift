import SwiftUI
import Kingfisher

struct SlotCardView: View {
    let slot: Slot
    let baseURL: String
    let isMySlot: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )

                switch slot.status {
                case .empty:
                    EmptySlotContent()

                case .assigned:
                    AssignedSlotContent(slot: slot, isMySlot: isMySlot)

                case .filled:
                    FilledSlotContent(slot: slot, baseURL: baseURL)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: Color {
        switch slot.status {
        case .empty: return Color(uiColor: .secondarySystemBackground)
        case .assigned: return Color.fillitDark
        case .filled: return .black
        }
    }

    private var borderColor: Color {
        if isMySlot && slot.status == .empty { return Color.fillitPrimary }
        if slot.status == .empty { return Color.gray.opacity(0.4) }
        return .clear
    }

    private var borderWidth: CGFloat {
        isMySlot && slot.status == .empty ? 2 : 1
    }
}

private struct EmptySlotContent: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("비어있음")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct AssignedSlotContent: View {
    let slot: Slot
    let isMySlot: Bool
    @State private var animating = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "camera.fill")
                .font(.title2)
                .foregroundStyle(isMySlot ? Color.fillitAccent3 : .white)
                .scaleEffect(animating ? 1.1 : 0.95)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: animating)

            Text(slot.nickname ?? "")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)

            if isMySlot {
                Text("탭하여 업로드")
                    .font(.caption2)
                    .foregroundStyle(Color.fillitAccent3)
            }
        }
        .onAppear { animating = true }
    }
}

private struct FilledSlotContent: View {
    let slot: Slot
    let baseURL: String

    var thumbnailURL: URL? {
        guard let path = slot.thumbnailUrl else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: baseURL + path)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            KFImage(thumbnailURL)
                .placeholder {
                    Color.gray.opacity(0.3)
                        .overlay(ProgressView().tint(.white))
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                if let nickname = slot.nickname {
                    Text(nickname)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                if let loc = slot.location {
                    Label(loc, systemImage: "location.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
