import SwiftUI

struct SoloraAssistantBubble: View {
    @ObservedObject var store: SoloraAssistantStore
    @ObservedObject var realtimeSession: SoloraRealtimeSession

    var body: some View {
        Button(action: store.presentPanel) {
            ZStack(alignment: .bottomTrailing) {
                SoloraOrbView(
                    size: 62,
                    color: SoloraTheme.lavender,
                    isAlive: true,
                    showsHalo: true
                )
                .accessibilityHidden(true)

                Image(systemName: realtimeSession.state == .connected ? "waveform" : "sparkles")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(SoloraTheme.cream)
                    .frame(width: 22, height: 22)
                    .background(SoloraTheme.ink, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.32), lineWidth: 1))
            }
            .frame(width: 72, height: 72)
        }
        .buttonStyle(SoloraPressButtonStyle(pressedScale: 0.96))
        .accessibilityLabel(realtimeSession.state == .connected ? "Open Solora voice companion, connected" : "Open Solora voice companion")
        .accessibilityHint("Opens voice, local memory, reflection, and navigation tools")
    }
}

struct SoloraAssistantPanel: View {
    @ObservedObject var store: SoloraAssistantStore
    @ObservedObject var realtimeSession: SoloraRealtimeSession
    let confirmMemoryChange: (SoloraAssistantPendingMemoryChange) -> Bool

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    availability
                    localActions
                    search
                    searchResults
                    confirmation
                    creationConfirmation
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(SoloraTheme.cream.ignoresSafeArea())
            .foregroundStyle(SoloraTheme.ink)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { store.isPanelPresented = false }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(spacing: 16) {
            SoloraOrbView(size: 72, color: SoloraTheme.lavender, isAlive: true, showsHalo: true)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Solora")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text(store.statusMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.60))
            }
        }
    }

    private var availability: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                realtimeSession.state.title,
                systemImage: realtimeSession.state == .connected ? "waveform" : "waveform.badge.mic"
            )
            .font(.footnote.weight(.semibold))

            if realtimeSession.state.isActive {
                HStack(spacing: 10) {
                    Button {
                        realtimeSession.toggleMute()
                    } label: {
                        Label(realtimeSession.isMuted ? "Unmute" : "Mute", systemImage: realtimeSession.isMuted ? "mic.slash.fill" : "mic.fill")
                            .frame(maxWidth: .infinity, minHeight: 46)
                    }
                    .buttonStyle(.bordered)
                    .disabled(realtimeSession.state != .connected)
                    .accessibilityLabel(realtimeSession.isMuted ? "Unmute microphone" : "Mute microphone")

                    Button(role: .destructive) {
                        realtimeSession.end()
                    } label: {
                        Label("End", systemImage: "phone.down.fill")
                            .frame(maxWidth: .infinity, minHeight: 46)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("End Solora voice session")
                }
            } else {
                Button {
                    realtimeSession.start()
                } label: {
                    Label(
                        isFailure ? "Retry voice" : "Talk with Solora",
                        systemImage: "mic.fill"
                    )
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(SoloraTheme.ink)
                .accessibilityHint("Requests microphone access and starts a secure live voice session")
            }
        }
        .foregroundStyle(SoloraTheme.ink.opacity(0.72))
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SoloraTheme.gold.opacity(0.13), in: RoundedRectangle(cornerRadius: 14))
    }

    private var isFailure: Bool {
        if case .failed = realtimeSession.state { return true }
        return false
    }

    private var localActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Go with Solora")
                .font(.headline.weight(.bold))
            HStack(spacing: 8) {
                action("Reflect", symbol: "text.bubble.fill") {
                    store.beginReflection(context: "A career moment from today")
                    store.navigate(to: .now)
                }
                action("Browse lore", symbol: "circle.grid.3x3.fill") {
                    store.navigate(to: .lore)
                }
                action("Create", symbol: "wand.and.rays") {
                    store.navigate(to: .share)
                }
            }
        }
    }

    private var search: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Find a career memory")
                .font(.headline.weight(.bold))
            HStack(spacing: 10) {
                TextField("Project, skill, outcome…", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .onSubmit { store.searchMemories(searchText) }
                Button {
                    store.searchMemories(searchText)
                } label: {
                    Image(systemName: "magnifyingglass")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Search local memories")
            }
            .padding(.leading, 14)
            .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 14))
            .soloraHairline(radius: 14)
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if !store.searchResults.isEmpty {
            VStack(spacing: 10) {
                ForEach(store.searchResults) { memory in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(memory.title).font(.subheadline.weight(.bold))
                        Text(memory.summary)
                            .font(.caption)
                            .foregroundStyle(SoloraTheme.ink.opacity(0.60))
                            .lineLimit(3)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    @ViewBuilder
    private var confirmation: some View {
        if let pending = store.pendingMemoryChange {
            VStack(alignment: .leading, spacing: 12) {
                Text("Review before saving")
                    .font(.headline.weight(.bold))
                Text(pending.draft.title)
                    .font(.subheadline.weight(.bold))
                Text(pending.draft.summary)
                    .font(.subheadline)
                    .foregroundStyle(SoloraTheme.ink.opacity(0.64))
                HStack(spacing: 10) {
                    Button("Cancel", role: .cancel) { store.cancelPendingMemoryChange() }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .buttonStyle(.bordered)
                    Button(pending.actionTitle) {
                        store.confirmPendingMemoryChange(using: confirmMemoryChange)
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .buttonStyle(.borderedProminent)
                    .tint(SoloraTheme.ink)
                }
            }
            .padding(16)
            .background(SoloraTheme.lavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .soloraHairline(SoloraTheme.lavender.opacity(0.34), radius: 16)
        }
    }

    @ViewBuilder
    private var creationConfirmation: some View {
        if let pending = store.pendingCreationFlow {
            VStack(alignment: .leading, spacing: 12) {
                Text("Open creation flow?")
                    .font(.headline.weight(.bold))
                Text("Solora wants to open the \(pending.kind.title) flow\(pending.target.map { " for \($0)" } ?? ""). Nothing will be created or shared until you continue there.")
                    .font(.subheadline)
                    .foregroundStyle(SoloraTheme.ink.opacity(0.64))
                HStack(spacing: 10) {
                    Button("Cancel", role: .cancel) { store.cancelPendingCreationFlow() }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .buttonStyle(.bordered)
                    Button("Open Share") { store.confirmPendingCreationFlow() }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .buttonStyle(.borderedProminent)
                        .tint(SoloraTheme.ink)
                }
            }
            .padding(16)
            .background(SoloraTheme.lavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .soloraHairline(SoloraTheme.lavender.opacity(0.34), radius: 16)
        }
    }

    private func action(_ title: String, symbol: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                Text(title).font(.caption.weight(.bold))
            }
            .foregroundStyle(SoloraTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 14))
            .soloraHairline(radius: 14)
        }
        .buttonStyle(SoloraPressButtonStyle())
    }
}

struct SoloraReflectionAssistantIdentity: View {
    @ObservedObject var store: SoloraAssistantStore

    var body: some View {
        HStack(spacing: 12) {
            SoloraOrbView(size: 48, color: SoloraTheme.lavender, isAlive: true)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Reflect with Solora")
                    .font(.subheadline.weight(.bold))
                Text(store.activeReflection?.prompt ?? "What changed because you were there?")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.58))
            }
            Spacer(minLength: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Solora reflection assistant. \(store.activeReflection?.prompt ?? "What changed because you were there?")")
    }
}
