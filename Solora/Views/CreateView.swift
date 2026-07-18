import SwiftUI

struct CreateView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CreatePhase = .ready
    @State private var roleBrief = CreateView.demoRoleBrief
    @State private var selectedMemoryIDs: Set<Int> = [1, 2, 3]
    @State private var selectedPreview: PreviewKind = .presentation
    @State private var evidenceTask: Task<Void, Never>?

    private static let demoRoleBrief = "Associate Product Manager — help shape early-career tools that make job searching feel more human. You’ll turn user insight into clear product decisions, partner with design and engineering, and communicate what you learn."

    private let memories = [
        EvidenceMemory(id: 1, rank: "01", title: "Turned club feedback into a better sign-up flow", reason: "Shows user insight → practical iteration", skills: "User research · Prioritisation", cvBullet: "Synthesised member feedback and simplified the club sign-up flow, making the first step clearer for new students.", starPoint: "Situation: sign-ups stalled. Task: find the friction. Action: listened to members and simplified the flow. Result: a clearer path people could act on."),
        EvidenceMemory(id: 2, rank: "02", title: "Led a cross-society launch in one week", reason: "Shows alignment under real constraints", skills: "Collaboration · Delivery", cvBullet: "Coordinated a cross-society launch in one week, aligning partners around a focused plan and clear ownership.", starPoint: "Situation: partners needed to launch fast. Task: create alignment. Action: set a simple plan and owners. Result: the launch landed on time."),
        EvidenceMemory(id: 3, rank: "03", title: "Made the case for a simpler event format", reason: "Shows clear thinking and influence", skills: "Product judgment · Communication", cvBullet: "Used attendee needs to recommend a simpler event format, helping the team make a clearer, more practical decision.", starPoint: "Situation: the format was overcomplicated. Task: make a recommendation. Action: framed the audience need and trade-off. Result: the team chose a simpler experience.")
    ]

    private var chosenMemories: [EvidenceMemory] {
        memories.filter { selectedMemoryIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    jobBrief
                    phaseContent
                        .id(phase)
                        .transition(reduceMotion ? .opacity : .soloraReveal)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
            .background(SoloraTheme.cream.ignoresSafeArea())
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onDisappear {
            evidenceTask?.cancel()
            if case .finding = phase { phase = .ready }
        }
        .sensoryFeedback(.selection, trigger: selectedMemoryIDs)
        .sensoryFeedback(.success, trigger: phase) { _, newPhase in newPhase == .complete }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch phase {
        case .ready:
            evidencePrompt
        case .finding:
            findingEvidence
        case .complete:
            evidenceResults
            deliverables
            sharePreview
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Make your next move\nfeel like you.").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundStyle(SoloraTheme.ink)
            Text("Paste a role, choose your proof, then open a ready-to-use story.").font(.subheadline).foregroundStyle(SoloraTheme.ink.opacity(0.68))
        }.padding(.top, 12)
    }

    private var jobBrief: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Role brief", systemImage: "doc.text").font(.caption.weight(.semibold)).foregroundStyle(SoloraTheme.coral)
                Spacer()
                Button("Paste demo brief") { roleBrief = Self.demoRoleBrief }
                    .font(.caption.weight(.semibold)).buttonStyle(.borderless).foregroundStyle(SoloraTheme.coral)
                Button("Reset") { resetDemo() }
                    .font(.caption.weight(.semibold)).buttonStyle(.borderless).foregroundStyle(SoloraTheme.ink.opacity(0.7))
            }
            TextEditor(text: $roleBrief)
                .font(.subheadline).foregroundStyle(SoloraTheme.ink)
                .frame(minHeight: 112).scrollContentBackground(.hidden)
                .padding(10).background(SoloraTheme.cream.opacity(0.65), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Editable role brief")
            Text("Demo-ready: edit this, or restore the Product brief any time.").font(.caption).foregroundStyle(SoloraTheme.ink.opacity(0.62))
        }
        .padding(20).background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .leading) { Rectangle().fill(SoloraTheme.gold).frame(width: 4).clipShape(RoundedRectangle(cornerRadius: 2)) }
    }

    private var evidencePrompt: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your archive already has the proof.").font(.title3.weight(.bold)).foregroundStyle(SoloraTheme.ink)
            Text("Find the moments that show product judgment, curiosity, and collaboration.").font(.subheadline).foregroundStyle(SoloraTheme.ink.opacity(0.68))
            Button(action: findEvidence) { Label("Find my strongest evidence", systemImage: "sparkles").font(.headline).frame(maxWidth: .infinity).frame(minHeight: 52) }
                .buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: 14)).tint(SoloraTheme.coral)
                .accessibilityHint("Surfaces three ranked saved moments for this role")
        }
    }

    private var findingEvidence: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                SoloraOrbView(size: 48, color: SoloraTheme.coral, isAlive: true, showsHalo: true)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Finding the threads that matter").font(.headline)
                    Text("Matching your brief to saved moments…").font(.subheadline).foregroundStyle(SoloraTheme.ink.opacity(0.64))
                }
            }.foregroundStyle(SoloraTheme.ink)
            SoloraProgressLine()
        }.padding(20).background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 20))
    }

    private var evidenceResults: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Choose the proof to use", systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(SoloraTheme.coral)
            Text("Select memories to immediately tailor every preview below.").font(.subheadline).foregroundStyle(SoloraTheme.ink.opacity(0.68))
            VStack(spacing: 0) {
                ForEach(memories) { memory in
                    EvidenceRow(memory: memory, isSelected: selectedMemoryIDs.contains(memory.id)) { toggle(memory.id) }
                        .soloraEntrance(index: memory.id - 1, distance: 8)
                    if memory.id != memories.last?.id { Divider().overlay(SoloraTheme.ink.opacity(0.10)) }
                }
            }.background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 20))
            Text("\(chosenMemories.count) of 3 memories selected").font(.caption.weight(.semibold)).foregroundStyle(SoloraTheme.ink.opacity(0.62))
        }
    }

    private var deliverables: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Open your tailored materials").font(.title3.weight(.bold)).foregroundStyle(SoloraTheme.ink)
            Button { selectPreview(.cv) } label: { DeliverableRow(icon: "doc.richtext", title: "Tailored CV", detail: "\(chosenMemories.count) evidence-led role-ready bullets", trailing: true) }.buttonStyle(SoloraPressButtonStyle(pressedScale: 0.985))
            Button { selectPreview(.interview) } label: { DeliverableRow(icon: "quote.bubble", title: "Interview talking points", detail: "Concise STAR stories from your selected memories", trailing: true) }.buttonStyle(SoloraPressButtonStyle(pressedScale: 0.985))
            Button { selectPreview(.presentation) } label: { DeliverableRow(icon: "rectangle.on.rectangle.angled", title: "Presentation", detail: "Demo preview · 5 slides that connect your story", trailing: true) }.buttonStyle(SoloraPressButtonStyle(pressedScale: 0.985))
        }
    }

    private var sharePreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { VStack(alignment: .leading, spacing: 3) { Text(selectedPreview.title).font(.headline); Text(selectedPreview.subtitle).font(.caption).foregroundStyle(SoloraTheme.cream.opacity(0.7)) }; Spacer(); Text("DEMO PREVIEW").font(.caption2.weight(.bold)).foregroundStyle(SoloraTheme.gold) }
            ZStack {
                previewCanvas
                    .id(selectedPreview)
                    .transition(reduceMotion ? .opacity : .soloraReveal)
            }
            HStack(spacing: 10) {
                PreviewButton(kind: .linkedin, selected: selectedPreview == .linkedin, action: selectPreview)
                PreviewButton(kind: .instagram, selected: selectedPreview == .instagram, action: selectPreview)
            }
        }.padding(20).background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 22)).foregroundStyle(SoloraTheme.cream)
    }

    @ViewBuilder private var previewCanvas: some View {
        switch selectedPreview {
        case .cv:
            VStack(alignment: .leading, spacing: 10) { Text("Associate Product Manager").font(.headline).foregroundStyle(SoloraTheme.ink); ForEach(chosenMemories) { Text("• \($0.cvBullet)").font(.caption).fixedSize(horizontal: false, vertical: true) } }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading).background(.white, in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(SoloraTheme.ink)
        case .interview:
            VStack(alignment: .leading, spacing: 10) { ForEach(chosenMemories) { Text($0.starPoint).font(.caption).fixedSize(horizontal: false, vertical: true); if $0.id != chosenMemories.last?.id { Divider() } } }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading).background(SoloraTheme.cream, in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(SoloraTheme.ink)
        case .presentation, .linkedin, .instagram:
            ZStack(alignment: .bottomLeading) { RoundedRectangle(cornerRadius: 16).fill(selectedPreview == .instagram ? SoloraTheme.coral : SoloraTheme.gold).frame(height: 154); VStack(alignment: .leading, spacing: 8) { Text(selectedPreview == .presentation ? "From moments\nto momentum." : "I’m building\nwith intention.").font(.system(size: 23, weight: .bold, design: .rounded)); Text("Built from \(chosenMemories.count) selected moments").font(.caption.weight(.semibold)).opacity(0.72) }.padding(18) }.foregroundStyle(SoloraTheme.ink)
        }
    }

    private func findEvidence() {
        evidenceTask?.cancel()
        withAnimation(reduceMotion ? nil : SoloraMotion.responsive) { phase = .finding }
        evidenceTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            await MainActor.run { withAnimation(reduceMotion ? nil : SoloraMotion.reveal) { phase = .complete } }
        }
    }
    private func toggle(_ id: Int) {
        withAnimation(reduceMotion ? nil : SoloraMotion.responsive) {
            if selectedMemoryIDs.contains(id) { selectedMemoryIDs.remove(id) } else { selectedMemoryIDs.insert(id) }
        }
    }
    private func resetDemo() { evidenceTask?.cancel(); roleBrief = Self.demoRoleBrief; selectedMemoryIDs = [1, 2, 3]; selectedPreview = .presentation; phase = .ready }
    private func selectPreview(_ kind: PreviewKind) { withAnimation(reduceMotion ? nil : SoloraMotion.responsive) { selectedPreview = kind } }
}

private struct EvidenceMemory: Identifiable { let id: Int; let rank, title, reason, skills, cvBullet, starPoint: String }
private struct EvidenceRow: View {
    let memory: EvidenceMemory; let isSelected: Bool; let action: () -> Void
    var body: some View { Button(action: action) { HStack(alignment: .top, spacing: 14) { Image(systemName: isSelected ? "checkmark.square.fill" : "square").font(.title3).foregroundStyle(SoloraTheme.coral).contentTransition(.symbolEffect(.replace)).symbolEffect(.bounce, value: isSelected); Text(memory.rank).font(.caption.weight(.bold)).foregroundStyle(SoloraTheme.coral).frame(width: 24, alignment: .leading); VStack(alignment: .leading, spacing: 6) { Text(memory.title).font(.subheadline.weight(.semibold)); Text(memory.reason).font(.caption).opacity(0.68); Text(memory.skills).font(.caption2.weight(.semibold)).foregroundStyle(SoloraTheme.coral) }; Spacer(minLength: 0) }.foregroundStyle(SoloraTheme.ink).padding(16) }.buttonStyle(SoloraPressButtonStyle(pressedScale: 0.99)).accessibilityLabel("\(isSelected ? "Selected" : "Not selected"). \(memory.rank). \(memory.title). \(memory.reason). Skills: \(memory.skills)") }
}
private struct DeliverableRow: View { let icon, title, detail: String; var trailing = false; var body: some View { HStack(spacing: 14) { Image(systemName: icon).font(.title3).foregroundStyle(SoloraTheme.coral).frame(width: 30); VStack(alignment: .leading, spacing: 3) { Text(title).font(.subheadline.weight(.semibold)); Text(detail).font(.caption).opacity(0.64) }; Spacer(); if trailing { Image(systemName: "chevron.right").font(.caption.weight(.bold)).opacity(0.45) } }.foregroundStyle(SoloraTheme.ink).padding(16).background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 16)) } }
private enum CreatePhase: Hashable { case ready, finding, complete }
private enum PreviewKind: Equatable {
    case cv, interview, presentation, linkedin, instagram

    var title: String {
        switch self {
        case .cv: return "Tailored CV"
        case .interview: return "Interview talking points"
        case .presentation: return "Presentation"
        case .linkedin: return "LinkedIn post"
        case .instagram: return "Instagram Story"
        }
    }

    var subtitle: String {
        switch self {
        case .cv: return "Role-ready proof, written from your choices"
        case .interview: return "Concise STAR prompts to make your story easy to tell"
        case .presentation: return "Your product story, made visual"
        case .linkedin: return "A considered career update"
        case .instagram: return "A shareable moment, sized for Stories"
        }
    }
}

private struct PreviewButton: View {
    let kind: PreviewKind
    let selected: Bool
    let action: (PreviewKind) -> Void

    var body: some View {
        Button { action(kind) } label: {
            Label(
                kind == .linkedin ? "LinkedIn" : "Instagram Story",
                systemImage: kind == .linkedin ? "link" : "camera"
            )
            .font(.caption.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                selected ? SoloraTheme.cream : SoloraTheme.cream.opacity(0.15),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .foregroundStyle(selected ? SoloraTheme.ink : SoloraTheme.cream)
        }
        .buttonStyle(SoloraPressButtonStyle(pressedScale: 0.985))
        .accessibilityHint("Changes the local demo preview only; nothing will be published")
    }
}

private struct SoloraProgressLine: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0.08

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(SoloraTheme.gold.opacity(0.2))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [SoloraTheme.coral, SoloraTheme.gold, .white, SoloraTheme.gold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(12, proxy.size.width * progress))
            }
        }
        .frame(height: 4)
        .onAppear {
            guard !reduceMotion else {
                progress = 0.78
                return
            }
            withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.66)) {
                progress = 0.94
            }
        }
        .accessibilityHidden(true)
    }
}
