import SwiftUI
import Observation

enum AppRoute: Hashable {
    case createRoom
    case joinRoom(code: String)
    case room(code: String)
    case vote(code: String)
    case rankResult(code: String)
    case result(code: String)
    case expired
}

@Observable
final class AppRouter {
    var path = NavigationPath()

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    func replace(with route: AppRoute) {
        popToRoot()
        navigate(to: route)
    }
}
