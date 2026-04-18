import Foundation
import Observation

@Observable
final class HomeViewModel {
    var roomCode = ""
    var isLoading = false
    var showError = false
    var errorMessage = ""

    func joinRoom(router: AppRouter) {
        let code = roomCode.trimmingCharacters(in: .whitespaces).uppercased()
        guard code.count == 6 else {
            setError("방 코드는 6자리입니다.")
            return
        }
        if UserSession.shared.getNickname(for: code) != nil {
            router.navigate(to: .room(code: code))
        } else {
            router.navigate(to: .joinRoom(code: code))
        }
    }

    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
