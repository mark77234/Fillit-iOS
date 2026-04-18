import SwiftUI

struct RankBadgeView: View {
    let rank: Int

    var body: some View {
        Text(badgeText)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(badgeColor)
            .clipShape(Circle())
    }

    private var badgeText: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }

    private var badgeColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return Color.fillitPrimary.opacity(0.7)
        }
    }
}
