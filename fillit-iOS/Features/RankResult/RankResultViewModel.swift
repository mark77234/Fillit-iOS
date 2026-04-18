import Foundation
import Observation

@Observable
final class RankResultViewModel {
    var room: Room?
    var isLoading = false
    var showError = false
    var errorMessage = ""

    private let roomCode: String
    private let getStatusUseCase = GetRoomStatusUseCase()

    init(roomCode: String) {
        self.roomCode = roomCode
    }

    var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "http://localhost:3000"
    }

    var rankedImageURL: URL? {
        guard let path = room?.rankedResultUrl else { return nil }
        return URL(string: baseURL + path)
    }

    var defaultImageURL: URL? {
        guard let path = room?.resultUrl else { return nil }
        return URL(string: baseURL + path)
    }

    func loadRoom() async {
        isLoading = true
        do {
            room = try await getStatusUseCase.execute(code: roomCode)
        } catch {
            setError(error.localizedDescription)
        }
        isLoading = false
    }

    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
