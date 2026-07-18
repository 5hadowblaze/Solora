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
    @StateObject private var assistantStore: SoloraAssistantStore
    @State private var selection: SoloraAppSurface

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
        _assistantStore = StateObject(wrappedValue: SoloraAssistantStore())
        _selection = State(initialValue: SoloraAppSurface.launchSelection)
    }

    var body: some View {
        TabView(selection: $selection) {
            TodayView(
                moments: momentStore.moments,
                assistantStore: assistantStore,
                onSave: saveReflection
            )
                .tabItem { Label("Now", systemImage: "circle.fill") }
                .tag(SoloraAppSurface.now)

            WorldView(
                manifest: container.worldManifest,
                moments: momentStore.moments,
                vibe: vibe,
                visualReference: visualReference
            )
            .tabItem { Label("Lore", systemImage: "circle.grid.3x3.fill") }
            .tag(SoloraAppSurface.lore)

            CreateView(moments: momentStore.moments, assistantStore: assistantStore)
                .tabItem { Label("Share", systemImage: "wand.and.rays") }
                .tag(SoloraAppSurface.share)

            YouView(
                vibe: vibe,
                visualReference: visualReference,
                authenticatedUser: authenticatedUser,
                signOut: signOut
            )
                .tabItem { Label("You", systemImage: "person.fill") }
                .tag(SoloraAppSurface.you)
        }
        .tint(SoloraTheme.coral)
        .overlay(alignment: .top) {
            if assistantStore.canShowRootBubble {
                SoloraAssistantIsland(store: assistantStore, realtimeSession: assistantStore.realtimeSession)
                    .padding(.top, 2)
                    .transition(reduceMotion ? .opacity : .soloraReveal)
            }
        }
        .animation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.responsive, value: assistantStore.canShowRootBubble)
        .task(id: authenticatedUser.id) {
            momentStore.start()
        }
        .onDisappear {
            assistantStore.realtimeSession.end()
        }
        .onChange(of: momentStore.moments, initial: true) { _, moments in
            assistantStore.replaceMemories(moments)
        }
        .onChange(of: selection, initial: true) { _, surface in
            assistantStore.setActiveSurface(surface)
        }
        .onChange(of: assistantStore.requestedSurface) { _, requestedSurface in
            guard let requestedSurface else { return }
            selection = requestedSurface
            assistantStore.consumeNavigationRequest()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            assistantStore.setKeyboardVisible(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            assistantStore.setKeyboardVisible(false)
        }
        .sheet(isPresented: Binding(
            get: { assistantStore.isPanelPresented },
            set: { assistantStore.isPanelPresented = $0 }
        )) {
            SoloraAssistantPanel(
                store: assistantStore,
                realtimeSession: assistantStore.realtimeSession,
                confirmMemoryChange: confirmAssistantMemoryChange
            )
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

    private func confirmAssistantMemoryChange(_ pending: SoloraAssistantPendingMemoryChange) -> Bool {
        let existing: SoloraMoment?
        let identifier: String
        switch pending.change {
        case .create:
            existing = nil
            identifier = UUID().uuidString
        case .update(let memoryID):
            existing = momentStore.moments.first { $0.id == memoryID }
            guard existing != nil else { return false }
            identifier = memoryID
        }

        let moment = SoloraMoment(
            id: identifier,
            title: pending.draft.title,
            summary: pending.draft.summary,
            date: pending.draft.occurredAt,
            world: existing?.world ?? .memoryShelves,
            category: pending.draft.category ?? existing?.category,
            stickerPath: existing?.stickerPath,
            photoPaths: existing?.photoPaths ?? []
        )

        var didSave = false
        withAnimation(reduceMotion ? nil : SoloraMotion.spatial) {
            didSave = momentStore.save(moment)
        }
        if didSave {
            UIAccessibility.post(notification: .announcement, argument: "Confirmed memory saved to your lore")
        }
        return didSave
    }

    @MainActor
    private func saveReflection(
        _ reflection: String,
        photoData: Data?,
        onProgress: @escaping @MainActor (Double) -> Void
    ) async -> Bool {
        let identifier = UUID().uuidString
        var photoPaths: [String] = []
        var stickerPath: String?

        if let photoData {
            do {
                let path = try await FirebaseMomentMediaRepository.uploadPhoto(
                    photoData,
                    userID: authenticatedUser.id,
                    momentID: identifier,
                    onProgress: onProgress
                )
                photoPaths = [path]

                if let stickerData = SoloraStickerComposer.stickerPNG(from: photoData) {
                    stickerPath = try? await FirebaseMomentMediaRepository.uploadSticker(
                        stickerData,
                        userID: authenticatedUser.id,
                        momentID: identifier
                    )
                }
            } catch {
                momentStore.errorMessage = (error as? LocalizedError)?.errorDescription
                    ?? "The photo could not be uploaded. Please try again."
                return false
            }
        }

        let fixture = DemoFixtures.postEventReflection(
            id: identifier,
            date: .now,
            reflection: reflection
        )
        let moment = SoloraMoment(
            id: fixture.id,
            title: fixture.title,
            summary: fixture.summary,
            date: fixture.date,
            world: fixture.world,
            category: fixture.category,
            stickerPath: stickerPath ?? fixture.stickerPath,
            photoPaths: photoPaths
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

private extension SoloraAppSurface {
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
