import SwiftUI
import Kingfisher

struct VoteCardView: View {
    let slot: Slot
    let baseURL: String
    let isSelected: Bool
    let hasVoted: Bool
    let onVote: () -> Void

    var thumbnailURL: URL? {
        guard let path = slot.thumbnailUrl else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: baseURL + path)
    }

    var body: some View {
        Button(action: {
            if !hasVoted { onVote() }
        }) {
            ZStack(alignment: .bottom) {
                KFImage(thumbnailURL)
                    .placeholder { Color.gray.opacity(0.3) }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minHeight: 160)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.nickname ?? "")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                        if let loc = slot.location {
                            Label(loc, systemImage: "location.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.fillitAccent3)
                            .font(.title3)
                    }
                }
                .padding(8)
            }
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.fillitAccent3 : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .disabled(hasVoted)
        .opacity(hasVoted && !isSelected ? 0.7 : 1.0)
    }
}
