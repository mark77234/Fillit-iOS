import Foundation

final class JoinRoomUseCase {
    private let roomService = RoomService()

    func execute(code: String, nickname: String) async throws -> JoinRoomResponse {
        let userId = UserSession.shared.userId
        let response = try await roomService.joinRoom(code: code, nickname: nickname, userId: userId)
        UserSession.shared.setNickname(nickname, for: code)
        return response
    }

    func getStoredNickname(for code: String) -> String? {
        UserSession.shared.getNickname(for: code)
    }
}
