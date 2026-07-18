import SwiftUI
import UIKit

struct RootTabView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let container: AppContainer
    let vibe: String
    let visualReference: String
    let authenticatedUser: AuthenticatedUser
    let signOut: () -> Void
    @StateObject private var momentStore: MomentStore
    @State private var selection: RootTab

    init(
        container: AppContainer,
        vibe: String = "Warm & reflective",
        visualReference: String = "Inside Out orbs",
        authenticatedUser: AuthenticatedUser = .demo,
        signOut: @escaping () -> Void = {}
    ) {
        self.container = container
        self.vibe = vibe
        self.visualReference = visualReference
        self.authenticatedUser = authenticatedUser
        self.signOut = signOut
        _momentStore = StateObject(wrappedValue: MomentStore(
            userID: authenticatedUser.id,
            demoMoments: container.moments
        ))
        _selection = State(initialValue: RootTab.launchSelection)
    }

    var body: some View {
        TabView(selection: $selection) {
            TodayView(moments: momentStore.moments, onSave: saveReflection)
                .tabItem { Label("Now", systemImage: "circle.fill") }
                .tag(RootTab.now)

            WorldView(
                manifest: container.worldManifest,
                moments: momentStore.moments,
                vibe: vibe,
                visualReference: visualReference
            )
            .tabItem { Label("Lore", systemImage: "circle.grid.3x3.fill") }
            .tag(RootTab.lore)

            CreateView(moments: momentStore.moments)
                .tabItem { Label("Share", systemImage: "wand.and.rays") }
                .tag(RootTab.share)

            YouView(
                vibe: vibe,
                visualReference: visualReference,
                authenticatedUser: authenticatedUser,
                signOut: signOut
            )
                .tabItem { Label("You", systemImage: "person.fill") }
                .tag(RootTab.you)
        }
        .tint(SoloraTheme.coral)
        .task(id: authenticatedUser.id) {
            momentStore.start()
        }
        .alert("Couldn't sync your lore", isPresented: Binding(
            get: { momentStore.errorMessage != nil },
            set: { if !$0 { momentStore.clearError() } }
        )) {
            Button("OK", role: .cancel) { momentStore.clearError() }
        } message: {
            Text(momentStore.errorMessage ?? "Please try again.")
        }
    }

    private func saveReflection(_ reflection: String) -> Bool {
        let moment = DemoFixtures.postEventReflection(
            id: UUID().uuidString,
            date: .now,
            reflection: reflection
        )
        var didSave = false
        withAnimation(reduceMotion ? nil : SoloraMotion.spatial) {
            didSave = momentStore.save(moment)
        }
        guard didSave else { return false }
        UIAccessibility.post(notification: .announcement, argument: "Reflection saved to your archive")
        return true
    }
}

private enum RootTab: String {
    case now, lore, share, you

    static var launchSelection: Self {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-demoTab"),
              arguments.indices.contains(flagIndex + 1) else {
            return .lore
        }

        let requestedTab = arguments[flagIndex + 1]
        if let tab = Self(rawValue: requestedTab) { return tab }

        switch requestedTab {
        case "today": return .now
        case "archive", "world": return .lore
        case "create": return .share
        default: return .lore
        }
    }
}
