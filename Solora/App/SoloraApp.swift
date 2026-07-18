import SwiftUI
import FirebaseCore

@main
struct SoloraApp: App {
    init() {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(container: .demo)
        }
    }
}
