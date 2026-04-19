import SwiftUI

@main
struct FillitApp: App {
    @State private var deepLinkManager = DeepLinkManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(deepLinkManager)
                .onOpenURL { url in
                    deepLinkManager.handle(url: url)
                }
        }
    }
}
