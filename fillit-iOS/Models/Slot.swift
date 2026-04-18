import Foundation

enum SlotStatus: String, Codable {
    case empty, assigned, filled
}

struct Slot: Codable, Identifiable {
    var id: Int { index }
    let index: Int
    let assignedTo: String?
    let nickname: String?
    let status: SlotStatus
    let filled: Bool
    let uploadedAt: Date?
    let thumbnailUrl: String?
    let location: String?
    let uploadRank: Int?
}
