import Foundation

enum RoomMode: String, Codable {
    case solo, multi
}

struct Room: Codable, Identifiable {
    var id: String { roomCode }
    let roomCode: String
    let hostUserId: String
    let templateId: String
    let template: Template
    let mode: RoomMode
    let totalSlots: Int
    let participantLimit: Int
    var participants: [Participant]
    let keyword: String?
    let deadlineAt: Date?
    var uploadLocked: Bool
    var slots: [Slot]
    var completed: Bool
    let completedAt: Date?
    let createdAt: Date
    let expiresAt: Date
    let resultUrl: String?
    let resultStoryUrl: String?
    let resultWideUrl: String?
    let rankedResultUrl: String?
    let resultReelUrl: String?
    let votingStartedAt: Date?
    let votingDeadlineAt: Date?
    var votingCompleted: Bool
    var voteCompletedCount: Int
    var votes: [Vote]
    var voteRanking: [RankResult]
    var uploadRanking: [RankResult]

    var isHost: Bool {
        hostUserId == UserSession.shared.userId
    }

    var mySlots: [Slot] {
        slots.filter { $0.assignedTo == UserSession.shared.userId }
    }

    var progress: (filled: Int, total: Int) {
        let filled = slots.filter { $0.filled }.count
        return (filled, totalSlots)
    }

    func isParticipant(userId: String) -> Bool {
        participants.contains { $0.userId == userId }
    }

    var hasMyVote: Bool {
        votes.contains { $0.voterId == UserSession.shared.userId }
    }

    func resultFullURL(base: String, path: String?) -> URL? {
        guard let path else { return nil }
        return URL(string: base + path)
    }
}
