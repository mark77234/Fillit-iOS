import Foundation

// MARK: - Request Payloads

struct CreateRoomPayload: Encodable {
    let templateId: String
    let mode: String
    let totalSlots: Int
    let hostNickname: String
    let userId: String
    let keyword: String?
    let deadlineAt: String?
}

struct JoinRoomPayload: Encodable {
    let nickname: String
    let userId: String
}

struct VotePayload: Encodable {
    let voterId: String
    let targetSlotIndex: Int?
}

struct EndVotePayload: Encodable {
    let userId: String
}

// MARK: - Response Models

struct CreateRoomResponse: Decodable {
    let roomCode: String
    let slotIndex: Int
    let assignedSlots: [Int]
    let userId: String
}

struct JoinRoomResponse: Decodable {
    let slotIndex: Int
    let assignedSlots: [Int]
    let userId: String
}

struct UploadResponse: Decodable {
    let success: Bool
    let completed: Bool
}

struct VoteResponse: Decodable {
    let ok: Bool
    let totalVotes: Int
    let completedCount: Int
    let skipped: Bool?
}

struct RankingResponse: Decodable {
    let voteRanking: [RankResult]
    let uploadRanking: [RankResult]
    let slowestSlotIndex: Int?
    let farthestLocationSlotIndex: Int?
}

struct TemplatesResponse: Decodable {
    let templates: [Template]
}

struct ReverseGeocodeResponse: Decodable {
    let location: String?
}

enum ResultVariant: String {
    case `default` = ""
    case story = "/story"
    case wide = "/wide"
    case ranked = "/ranked"
    case reel = "/reel"
}
