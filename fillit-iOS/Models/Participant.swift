import Foundation

struct Participant: Codable, Identifiable {
    var id: String { userId }
    let userId: String
    let nickname: String
    let joinedAt: Date
}
