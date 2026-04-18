import Foundation

final class CreateRoomUseCase {
    private let roomService = RoomService()
    private let templateService = TemplateService()

    func getTemplates() async throws -> [Template] {
        try await templateService.getTemplates()
    }

    func execute(
        templateId: String,
        mode: RoomMode,
        totalSlots: Int,
        hostNickname: String,
        keyword: String?,
        deadlineAt: Date?
    ) async throws -> CreateRoomResponse {
        let userId = UserSession.shared.userId

        var deadlineString: String?
        if let deadline = deadlineAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            deadlineString = formatter.string(from: deadline)
        }

        let payload = CreateRoomPayload(
            templateId: templateId,
            mode: mode.rawValue,
            totalSlots: totalSlots,
            hostNickname: hostNickname,
            userId: userId,
            keyword: keyword?.isEmpty == true ? nil : keyword,
            deadlineAt: deadlineString
        )

        let response = try await roomService.createRoom(payload)
        UserSession.shared.setNickname(hostNickname, for: response.roomCode)
        return response
    }
}
