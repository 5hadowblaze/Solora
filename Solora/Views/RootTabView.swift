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
    @State private var focusedMemoryID: String?
    @State private var editingMemory: SoloraMoment?
    @State private var assistantMemoryChange: SoloraAssistantPendingMemoryChange?

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
                onSave: saveReflection,
                onOpenMemory: openMemory
            )
                .tabItem { Label("Now", systemImage: "circle.fill") }
                .tag(SoloraAppSurface.now)

            WorldView(
                moments: momentStore.moments,
                vibe: vibe,
                visualReference: visualReference,
                focusMemoryID: focusedMemoryID,
                onDelete: deleteMemory,
                onEdit: { editingMemory = $0 }
            )
            .tabItem { Label("Lore", systemImage: "circle.grid.3x3.fill") }
            .tag(SoloraAppSurface.lore)

            MasterCVView(moments: momentStore.moments, userID: authenticatedUser.id)
                .tabItem { Label("Share", systemImage: "doc.text.fill") }
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
            let mediaPaths = moments.flatMap { moment in
                moment.photoPaths + (moment.stickerPath.map { [$0] } ?? [])
            }
            Task(priority: .utility) {
                await SoloraMomentMediaDataCache.shared.preload(paths: mediaPaths)
            }
        }
        .onChange(of: selection, initial: true) { _, surface in
            assistantStore.setActiveSurface(surface)
        }
        .onChange(of: assistantStore.requestedSurface) { _, requestedSurface in
            guard let requestedSurface else { return }
            selection = requestedSurface
            assistantStore.consumeNavigationRequest()
        }
        .onChange(of: assistantStore.requestedMemoryID) { _, requestedMemoryID in
            guard let requestedMemoryID else { return }
            selection = .lore
            focusedMemoryID = requestedMemoryID
            assistantStore.consumeMemoryOpenRequest()
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
        .sheet(item: $editingMemory) { memory in
            MemoryCreationSheet(existing: memory, onSave: saveReflection)
        }
        .sheet(item: $assistantMemoryChange) { pending in
            let existing: SoloraMoment?
            switch pending.change {
            case .create: existing = nil
            case .update(let memoryID): existing = momentStore.moments.first { $0.id == memoryID }
            }
            MemoryCreationSheet(
                context: pending.draft.summary,
                existing: existing,
                onSave: saveReflection
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
        switch pending.change {
        case .create:
            break
        case .update(let memoryID):
            guard momentStore.moments.contains(where: { $0.id == memoryID }) else { return false }
        }
        assistantMemoryChange = pending
        assistantStore.isPanelPresented = false
        return true
    }

    @MainActor
    private func saveReflection(
        _ payload: MemoryCreationPayload,
        onProgress: @escaping @MainActor (Double) -> Void
    ) async -> SoloraMoment? {
        let identifier = payload.existingID ?? UUID().uuidString
        var photoPaths: [String] = []
        var visualAssets: [MomentVisualAsset] = []
        let existing = payload.existingID.flatMap { id in momentStore.moments.first { $0.id == id } }

        do {
            for (index, photoData) in payload.media.enumerated() {
                let path = try await FirebaseMomentMediaRepository.uploadPhoto(
                    photoData,
                    userID: authenticatedUser.id,
                    momentID: identifier,
                    onProgress: { fraction in
                        onProgress((Double(index) + fraction) / Double(max(1, payload.media.count)))
                    }
                )
                photoPaths.append(path)
                let motionPath: String?
                if let motionData = payload.motionMedia.indices.contains(index) ? payload.motionMedia[index] : nil {
                    motionPath = try await FirebaseMomentMediaRepository.uploadLivePhotoMotion(
                        motionData,
                        userID: authenticatedUser.id,
                        momentID: identifier,
                        onProgress: { fraction in
                            onProgress((Double(index) + 0.5 + fraction * 0.5) / Double(max(1, payload.media.count)))
                        }
                    )
                } else {
                    motionPath = payload.retainedMotionPaths.indices.contains(index) ? payload.retainedMotionPaths[index] : nil
                }
                visualAssets.append(MomentVisualAsset(
                    posterPath: path,
                    motionPath: motionPath,
                    kind: motionPath == nil ? .photo : .livePhoto
                ))
            }
        } catch {
            momentStore.errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "The memory media could not be uploaded. Please try again."
            return nil
        }

        guard !photoPaths.isEmpty else {
            momentStore.errorMessage = "Choose at least one photo or Live Photo before saving this memory."
            return nil
        }

        let moment = SoloraMoment(
            id: identifier,
            title: payload.title,
            summary: payload.summary,
            reflection: payload.reflection,
            date: existing?.date ?? .now,
            world: existing?.world ?? .memoryShelves,
            category: payload.memoryType.title,
            memoryType: payload.memoryType,
            playbackStyle: payload.playbackStyle,
            visualAssets: visualAssets,
            stickerPath: existing?.stickerPath,
            photoPaths: photoPaths
        )
        var didSave = false
        withAnimation(reduceMotion ? nil : SoloraMotion.spatial) {
            didSave = existing == nil ? momentStore.save(moment) : momentStore.update(moment)
        }
        guard didSave else { return nil }
        UIAccessibility.post(notification: .announcement, argument: existing == nil ? "Memory saved to your lore" : "Memory updated")
        return moment
    }

    @MainActor
    private func openMemory(_ memoryID: String) {
        selection = .lore
        focusedMemoryID = memoryID
    }

    @MainActor
    private func deleteMemory(_ moment: SoloraMoment) -> Bool {
        let didDelete = momentStore.delete(moment)
        guard didDelete else { return false }
        if focusedMemoryID == moment.id { focusedMemoryID = nil }
        Task {
            await SoloraMomentMediaDataCache.shared.remove(
                paths: moment.photoPaths + (moment.stickerPath.map { [$0] } ?? [])
            )
        }
        UIAccessibility.post(notification: .announcement, argument: "Memory deleted from your lore")
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
