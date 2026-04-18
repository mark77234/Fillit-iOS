import Foundation

struct SlotUpdateEvent: Decodable {
    let slotIndex: Int
    let assignedTo: String?
    let nickname: String?
    let status: SlotStatus
    let filled: Bool
    let uploadedAt: String?
    let thumbnailUrl: String?
    let location: String?
    let uploadRank: Int?
}

struct RoomCompleteEvent: Decodable {
    let resultUrl: String
    let resultStoryUrl: String
    let resultWideUrl: String
    let resultReelUrl: String
    let votingStartedAt: String
    let votingDeadlineAt: String
    let expiresAt: String
}

struct VotingStartEvent: Decodable {
    let deadline: String
}

struct VoteUpdateEvent: Decodable {
    let totalVotes: Int
    let completedCount: Int
}

struct VotingCompleteEvent: Decodable {
    let voteRanking: [RankResult]
    let uploadRanking: [RankResult]
}
