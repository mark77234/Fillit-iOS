import Foundation
import Observation

@Observable
final class UserSession {
    static let shared = UserSession()

    private(set) var userId: String
    var hasOnboarded: Bool {
        didSet { UserDefaults.standard.set(hasOnboarded, forKey: Keys.onboarded) }
    }

    private enum Keys {
        static let userId = "fillit_user_id"
        static let onboarded = "fillit_onboarded"
        static func nickname(_ code: String) -> String { "fillit_nickname_\(code)" }
    }

    private init() {
        if let stored = UserDefaults.standard.string(forKey: Keys.userId) {
            userId = stored
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: Keys.userId)
            userId = newId
        }
        hasOnboarded = UserDefaults.standard.bool(forKey: Keys.onboarded)
    }

    func getNickname(for roomCode: String) -> String? {
        UserDefaults.standard.string(forKey: Keys.nickname(roomCode))
    }

    func setNickname(_ nickname: String, for roomCode: String) {
        UserDefaults.standard.set(nickname, forKey: Keys.nickname(roomCode))
    }
}
