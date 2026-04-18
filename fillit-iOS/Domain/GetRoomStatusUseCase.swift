import Foundation

final class GetRoomStatusUseCase {
    private let roomService = RoomService()

    func execute(code: String) async throws -> Room {
        try await roomService.getRoomStatus(code: code)
    }
}
