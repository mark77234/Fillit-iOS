import SwiftUI
import Kingfisher

struct UploadRankingView: View {
    let voteRanking: [RankResult]
    let slots: [Slot]
    let baseURL: String

    private var sortedRanking: [RankResult] {
        voteRanking.sorted { $0.rank < $1.rank }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("투표 결과")
                .font(.headline)

            ForEach(sortedRanking) { rankItem in
                if let slot = slots.first(where: { $0.index == rankItem.slotIndex }) {
                    RankRowView(rank: rankItem, slot: slot, baseURL: baseURL)
                }
            }
        }
        .padding()
        .fillitCard()
    }
}

private struct RankRowView: View {
    let rank: RankResult
    let slot: Slot
    let baseURL: String

    var thumbnailURL: URL? {
        guard let path = slot.thumbnailUrl else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: baseURL + path)
    }

    var body: some View {
        HStack(spacing: 12) {
            RankBadgeView(rank: rank.rank)

            KFImage(thumbnailURL)
                .placeholder { Color.gray.opacity(0.3) }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.nickname ?? "")
                    .font(.subheadline.weight(.semibold))
                if let loc = slot.location {
                    Label(loc, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(rank.score)표")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.fillitPrimary)
        }
    }
}
