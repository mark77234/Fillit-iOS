import SwiftUI

struct ContentView: View {
    @State private var router = AppRouter()
    @State private var showOnboarding = !UserSession.shared.hasOnboarded

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .createRoom:
                        CreateRoomView()
                    case .joinRoom(let code):
                        JoinRoomView(roomCode: code)
                    case .room(let code):
                        RoomView(roomCode: code)
                    case .vote(let code):
                        VoteView(roomCode: code)
                    case .rankResult(let code):
                        RankResultView(roomCode: code)
                    case .result(let code):
                        ResultView(roomCode: code)
                    case .expired:
                        ExpiredView()
                    }
                }
        }
        .environment(router)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                showOnboarding = false
            }
        }
    }
}
