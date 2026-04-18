import Foundation

struct RankResult: Codable, Identifiable {
    var id: Int { slotIndex }
    let slotIndex: Int
    let rank: Int
    let score: Int
}
