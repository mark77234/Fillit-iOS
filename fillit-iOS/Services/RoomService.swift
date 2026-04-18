import Foundation
import UIKit

final class RoomService {
    private let api = APIClient.shared

    func createRoom(_ payload: CreateRoomPayload) async throws -> CreateRoomResponse {
        try await api.post("api/room/create", body: payload)
    }

    func joinRoom(code: String, nickname: String, userId: String) async throws -> JoinRoomResponse {
        let payload = JoinRoomPayload(nickname: nickname, userId: userId)
        return try await api.post("api/room/\(code)/join", body: payload)
    }

    func getRoomStatus(code: String) async throws -> Room {
        try await api.get("api/room/\(code)/status")
    }

    func uploadImage(
        code: String,
        slotIndex: Int,
        userId: String,
        image: UIImage,
        location: String?
    ) async throws -> UploadResponse {
        guard let jpeg = image.jpegData(compressionQuality: 0.85) else {
            throw APIError.serverError("이미지 변환에 실패했습니다.")
        }
        var fields: [String: String] = [
            "slotIndex": "\(slotIndex)",
            "userId": userId
        ]
        if let loc = location { fields["location"] = loc }
        return try await api.upload("api/room/\(code)/upload", imageData: jpeg, fields: fields)
    }

    func submitVote(code: String, voterId: String, targetSlotIndex: Int?) async throws -> VoteResponse {
        let payload = VotePayload(voterId: voterId, targetSlotIndex: targetSlotIndex)
        return try await api.post("api/room/\(code)/vote", body: payload)
    }

    func endVote(code: String, userId: String) async throws -> RankingResponse {
        let payload = EndVotePayload(userId: userId)
        return try await api.post("api/room/\(code)/vote/end", body: payload)
    }

    func getRanking(code: String) async throws -> RankingResponse {
        try await api.get("api/room/\(code)/ranking")
    }

    func downloadResult(code: String, variant: ResultVariant, reelSpeed: Double? = nil) async throws -> Data {
        var query: [String: String] = [:]
        if let speed = reelSpeed { query["speed"] = "\(speed)" }
        return try await api.downloadData("api/room/\(code)/result\(variant.rawValue)", query: query)
    }
}
