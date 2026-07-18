import Foundation
import SwiftUI

@MainActor
final class SoloraAssistantStore: ObservableObject {
    @Published var isPanelPresented = false
    @Published private(set) var activeSurface: SoloraAppSurface = .lore
    @Published private(set) var childPresentation: SoloraAssistantChildPresentation?
    @Published private(set) var isKeyboardVisible = false
    @Published private(set) var searchResults: [SoloraAssistantMemorySummary] = []
    @Published private(set) var activeReflection: SoloraAssistantReflectionSession?
    @Published private(set) var preparedDraft: SoloraAssistantMemoryDraft?
    @Published private(set) var pendingMemoryChange: SoloraAssistantPendingMemoryChange?
    @Published private(set) var requestedSurface: SoloraAppSurface?
    @Published private(set) var statusMessage = "Local tools are ready. Voice connection is coming next."

    let toolRegistry: any SoloraAssistantToolRegistry

    init(toolRegistry: any SoloraAssistantToolRegistry = LocalSoloraAssistantToolRegistry()) {
        self.toolRegistry = toolRegistry
    }

    var canShowRootBubble: Bool {
        !isPanelPresented && childPresentation == nil && !isKeyboardVisible
    }

    func replaceMemories(_ moments: [SoloraMoment]) {
        toolRegistry.replaceMemorySummaries(moments.map(SoloraAssistantMemorySummary.init))
    }

    func setActiveSurface(_ surface: SoloraAppSurface) {
        activeSurface = surface
    }

    func setKeyboardVisible(_ isVisible: Bool) {
        isKeyboardVisible = isVisible
    }

    func beginChildPresentation(_ presentation: SoloraAssistantChildPresentation) {
        isPanelPresented = false
        childPresentation = presentation
    }

    func endChildPresentation(_ presentation: SoloraAssistantChildPresentation) {
        guard childPresentation == presentation else { return }
        childPresentation = nil
    }

    func presentPanel() {
        guard childPresentation == nil, !isKeyboardVisible else { return }
        isPanelPresented = true
    }

    func searchMemories(_ query: String) {
        apply(toolRegistry.execute(.searchMemorySummaries(query: query, limit: 8)))
    }

    func beginReflection(context: String) {
        apply(toolRegistry.execute(.beginReflection(context: context)))
    }

    func continueReflection(note: String) {
        guard let sessionID = activeReflection?.id else {
            beginReflection(context: "A career moment from today")
            guard let newSessionID = activeReflection?.id else { return }
            apply(toolRegistry.execute(.continueReflection(sessionID: newSessionID, note: note)))
            return
        }
        apply(toolRegistry.execute(.continueReflection(sessionID: sessionID, note: note)))
    }

    func navigate(to surface: SoloraAppSurface) {
        apply(toolRegistry.execute(.navigate(surface: surface, userRequested: true)))
    }

    func handleFutureToolCall(_ call: SoloraAssistantToolCall) {
        apply(toolRegistry.execute(call))
    }

    func consumeNavigationRequest() {
        requestedSurface = nil
    }

    func cancelPendingMemoryChange() {
        pendingMemoryChange = nil
        statusMessage = "The draft was not saved."
    }

    func confirmPendingMemoryChange(
        using handler: (SoloraAssistantPendingMemoryChange) -> Bool
    ) {
        guard let pendingMemoryChange else { return }
        if handler(pendingMemoryChange) {
            self.pendingMemoryChange = nil
            statusMessage = "Saved to your lore after your confirmation."
        } else {
            statusMessage = "That memory could not be saved. Review it and try again."
        }
    }

    private func apply(_ result: SoloraAssistantToolResult) {
        switch result {
        case .memorySummaries(let summaries):
            searchResults = summaries
            statusMessage = summaries.isEmpty ? "No local memories matched that search." : "Found \(summaries.count) local \(summaries.count == 1 ? "memory" : "memories")."
        case .memorySummary(let summary):
            searchResults = [summary]
            statusMessage = "Opened a local memory summary."
        case .draftPrepared(let draft):
            preparedDraft = draft
            statusMessage = "Draft prepared locally. It has not been saved."
        case .confirmationRequired(let pending):
            pendingMemoryChange = pending
            statusMessage = "Review and confirm this change before Solora writes anything."
        case .reflection(let reflection):
            activeReflection = reflection
            statusMessage = reflection.prompt
        case .navigationRequested(let surface):
            requestedSurface = surface
            isPanelPresented = false
        case .unavailable(let message):
            statusMessage = message
        }
    }
}
