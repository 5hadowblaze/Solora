import SwiftUI

struct CreateView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CreatePhase = .ready
    @State private var selectedPreview: PreviewKind = .presentation

    private let roleBrief = "Associate Product Manager — help shape early-career tools that make job searching feel more human. You’ll turn user insight into clear product decisions, partner with design and engineering, and communicate what you learn."

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    jobBrief

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
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
            .background(SoloraTheme.cream.ignoresSafeArea())
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Make your next move\nfeel like you.")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(SoloraTheme.ink)
            Text("Solora turns the moments you’ve kept into a clear, personal application.")
                .font(.subheadline)
                .foregroundStyle(SoloraTheme.ink.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
    }

    private var jobBrief: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Role brief", systemImage: "doc.text")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SoloraTheme.coral)

            Text("Early-career Product")
                .font(.title3.weight(.bold))
                .foregroundStyle(SoloraTheme.ink)
            Text(roleBrief)
                .font(.subheadline)
                .foregroundStyle(SoloraTheme.ink.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .leading) {
            Rectangle().fill(SoloraTheme.gold).frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Role brief. Early-career Product. \(roleBrief)")
    }

    private var evidencePrompt: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your archive already has the proof.")
                .font(.title3.weight(.bold))
                .foregroundStyle(SoloraTheme.ink)
            Text("We’ll surface the experiences that show product judgment, curiosity, and collaboration.")
                .font(.subheadline)
                .foregroundStyle(SoloraTheme.ink.opacity(0.68))

            Button(action: findEvidence) {
                Label("Find my strongest evidence", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(SoloraTheme.coral)
            .accessibilityHint("Searches your saved moments for the strongest match to this role")
        }
    }

    private var findingEvidence: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                ProgressView().tint(SoloraTheme.coral)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Finding the threads that matter")
                        .font(.headline)
                    Text("Reading your saved moments…")
                        .font(.subheadline)
                        .foregroundStyle(SoloraTheme.ink.opacity(0.64))
                }
            }
            .foregroundStyle(SoloraTheme.ink)
            Rectangle()
                .fill(SoloraTheme.gold.opacity(0.35))
                .frame(height: 3)
                .clipShape(Capsule())
        }
        .padding(20)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Finding your strongest evidence")
    }

    private var evidenceResults: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Your strongest evidence", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(SoloraTheme.coral)
            Text("Three moments tell a convincing product story.")
                .font(.subheadline)
                .foregroundStyle(SoloraTheme.ink.opacity(0.68))

            VStack(spacing: 0) {
                EvidenceRow(rank: "01", title: "Turned club feedback into a better sign-up flow", reason: "Shows user insight → practical iteration", skills: "User research · Prioritisation")
                Divider().overlay(SoloraTheme.ink.opacity(0.10))
                EvidenceRow(rank: "02", title: "Led a cross-society launch in one week", reason: "Shows alignment under real constraints", skills: "Collaboration · Delivery")
                Divider().overlay(SoloraTheme.ink.opacity(0.10))
                EvidenceRow(rank: "03", title: "Made the case for a simpler event format", reason: "Shows clear thinking and influence", skills: "Product judgment · Communication")
            }
            .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private var deliverables: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ready to use")
                .font(.title3.weight(.bold))
                .foregroundStyle(SoloraTheme.ink)
            DeliverableRow(icon: "doc.richtext", title: "Tailored CV", detail: "Evidence woven into 3 role-ready bullets")
            DeliverableRow(icon: "quote.bubble", title: "Interview talking points", detail: "A confident story for each strongest moment")
            Button { selectPreview(.presentation) } label: {
                DeliverableRow(icon: "rectangle.on.rectangle.angled", title: "Presentation", detail: "Demo preview · 5 slides that connect your story", trailing: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open presentation demo preview")
        }
    }

    private var sharePreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedPreview.title)
                        .font(.headline)
                    Text(selectedPreview.subtitle)
                        .font(.caption)
                        .foregroundStyle(SoloraTheme.ink.opacity(0.62))
                }
                Spacer()
                Text("DEMO PREVIEW")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(SoloraTheme.coral)
            }

            previewCanvas

            HStack(spacing: 10) {
                PreviewButton(kind: .linkedin, selected: selectedPreview == .linkedin, action: selectPreview)
                PreviewButton(kind: .instagram, selected: selectedPreview == .instagram, action: selectPreview)
            }
        }
        .padding(20)
        .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 22))
        .foregroundStyle(SoloraTheme.cream)
        .accessibilityElement(children: .contain)
    }

    private var previewCanvas: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(selectedPreview == .instagram ? SoloraTheme.coral : SoloraTheme.gold)
                .frame(height: 154)
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedPreview == .presentation ? "From moments\nto momentum." : "I’m building\nwith intention.")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(SoloraTheme.ink)
                Text(selectedPreview == .presentation ? "Associate Product Manager" : "My early-career product story")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.72))
            }
            .padding(18)
        }
        .accessibilityLabel("\(selectedPreview.title) preview")
    }

    private func findEvidence() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { phase = .finding }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.32)) { phase = .complete }
        }
    }

    private func selectPreview(_ kind: PreviewKind) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { selectedPreview = kind }
    }
}

private struct EvidenceRow: View {
    let rank: String
    let title: String
    let reason: String
    let skills: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(rank).font(.caption.weight(.bold)).foregroundStyle(SoloraTheme.coral).frame(width: 24, alignment: .leading)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(SoloraTheme.ink)
                Text(reason).font(.caption).foregroundStyle(SoloraTheme.ink.opacity(0.64))
                Text(skills).font(.caption2.weight(.semibold)).foregroundStyle(SoloraTheme.coral)
            }
        }
        .padding(16)
    }
}

private struct DeliverableRow: View {
    let icon: String
    let title: String
    let detail: String
    var trailing = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(SoloraTheme.coral).frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(SoloraTheme.ink)
                Text(detail).font(.caption).foregroundStyle(SoloraTheme.ink.opacity(0.64))
            }
            Spacer()
            if trailing { Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(SoloraTheme.ink.opacity(0.45)) }
        }
        .padding(16)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 16))
    }
}

private enum CreatePhase { case ready, finding, complete }

private enum PreviewKind: Equatable {
    case presentation, linkedin, instagram
    var title: String { self == .presentation ? "Presentation" : self == .linkedin ? "LinkedIn post" : "Instagram Story" }
    var subtitle: String { self == .presentation ? "Your product story, made visual" : self == .linkedin ? "A considered career update" : "A shareable moment, sized for Stories" }
}

private struct PreviewButton: View {
    let kind: PreviewKind
    let selected: Bool
    let action: (PreviewKind) -> Void

    var body: some View {
        Button { action(kind) } label: {
            Label(kind == .linkedin ? "LinkedIn" : "Instagram Story", systemImage: kind == .linkedin ? "link" : "camera")
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(selected ? SoloraTheme.cream : SoloraTheme.cream.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(selected ? SoloraTheme.ink : SoloraTheme.cream)
        }
        .accessibilityHint("Changes the local demo preview only; nothing will be published")
    }
}
