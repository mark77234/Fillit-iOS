import Foundation
import Observation

@Observable
final class JoinRoomViewModel {
    var room: Room?
    var nickname = ""
    var isLoading = false
    var isJoining = false
    var showError = false
    var errorMessage = ""

    private let joinUseCase = JoinRoomUseCase()
    private let getStatusUseCase = GetRoomStatusUseCase()

    var canJoin: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func loadRoom(code: String) async {
        isLoading = true
        do {
            room = try await getStatusUseCase.execute(code: code)
            if let stored = joinUseCase.getStoredNickname(for: code) {
                nickname = stored
            }
        } catch {
            setError(error.localizedDescription)
        }
        isLoading = false
    }

    func join(code: String, router: AppRouter) async {
        let name = nickname.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { setError("닉네임을 입력해 주세요."); return }

        isJoining = true
        do {
            _ = try await joinUseCase.execute(code: code, nickname: name)
            await MainActor.run {
                router.navigate(to: .room(code: code))
            }
        } catch {
            setError(error.localizedDescription)
        }
        isJoining = false
    }

    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
