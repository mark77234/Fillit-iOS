import Foundation

final class VoteUseCase {
    private let roomService = RoomService()

    func submitVote(code: String, targetSlotIndex: Int?) async throws -> VoteResponse {
        let userId = UserSession.shared.userId
        return try await roomService.submitVote(code: code, voterId: userId, targetSlotIndex: targetSlotIndex)
    }

    func endVote(code: String) async throws -> RankingResponse {
        let userId = UserSession.shared.userId
        return try await roomService.endVote(code: code, userId: userId)
    }
}
