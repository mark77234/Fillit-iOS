import Foundation

struct Vote: Codable {
    let voterId: String
    let targetSlotIndex: Int
    let votedAt: Date
}
