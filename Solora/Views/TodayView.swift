import SwiftUI

struct TodayView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let moments: [SoloraMoment]
    let onSave: (String) -> Void
    @State private var showsPostEventPrompt = false
    @State private var showsFormation = false
    @State private var savedReflection = false
    @State private var captureTask: Task<Void, Never>?
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                SoloraTheme.paper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Good afternoon, Amir")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            Text("One moment is ready to become part of your lore.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("3:00 PM")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(SoloraTheme.coral)
                                    Text("Product strategy workshop")
                                        .font(.title3.weight(.bold))
                                    Text("Ended 2 minutes ago · Calendar")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "calendar.badge.checkmark")
                                    .font(.title2)
                                    .foregroundStyle(SoloraTheme.coral)
                            }

                            Button {
                                savedReflection = false
                                showsPostEventPrompt = true
                            } label: {
                                Label("Turn this into a Solora", systemImage: "sparkles")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .foregroundStyle(.white)
                                    .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(SoloraPressButtonStyle())
                            .accessibilityHint("Opens a sample post-event reflection")
                        }
                        .padding(18)
                        .background(.white, in: RoundedRectangle(cornerRadius: SoloraTheme.cardRadius))
                        .overlay {
                            RoundedRectangle(cornerRadius: SoloraTheme.cardRadius)
                                .stroke(SoloraTheme.ink.opacity(0.08))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Latest Soloras")
                                    .font(.title2.weight(.bold))
                                Spacer()
                                Text("\(moments.count) memories")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .contentTransition(.numericText())
                            }

                            ForEach(Array(moments.prefix(3).enumerated()), id: \.element.id) { index, moment in
                                MomentRow(moment: moment, color: orbColors[index % orbColors.count])
                                    .transition(.soloraReveal)
                                    .soloraEntrance(index: index + 1)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showsPostEventPrompt) {
                PostEventReflectionView { reflection in
                    completeCapture(reflection)
                }
            }
            .overlay {
                if showsFormation {
                    SoloraFormationOverlay()
                        .transition(reduceMotion ? .opacity : .soloraReveal)
                }
            }
            .overlay(alignment: .bottom) {
                if savedReflection {
                    Label("Reflection saved to your archive", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 12))
                        .padding()
                        .accessibilityAddTraits(.isStaticText)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.responsive, value: savedReflection)
            .sensoryFeedback(.success, trigger: savedReflection) { _, isSaved in isSaved }
        }
        .onDisappear {
            captureTask?.cancel()
            toastTask?.cancel()
        }
    }

    private var orbColors: [Color] {
        [SoloraTheme.gold, SoloraTheme.lavender, SoloraTheme.coral]
    }

    private func completeCapture(_ reflection: String) {
        captureTask?.cancel()
        toastTask?.cancel()
        savedReflection = false
        onSave(reflection)
        showsPostEventPrompt = false

        withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.responsive) {
            showsFormation = true
        }

        captureTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 520 : 1_600))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.responsive) {
                showsFormation = false
                savedReflection = true
            }

            toastTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.4))
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.quick) {
                    savedReflection = false
                }
            }
        }
    }
}

private struct SoloraFormationOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationTrigger = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.14)
                .ignoresSafeArea()

            Group {
                if reduceMotion {
                    formationCard(phase: .settled)
                } else {
                    formationCard(phase: .seed)
                        .phaseAnimator(FormationPhase.allCases, trigger: animationTrigger) { content, phase in
                            formationCard(phase: phase)
                        } animation: { phase in
                            phase.animation
                        }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Forming a new Solora")
        .accessibilityHint("Your reflection is being added to the archive")
        .onAppear { animationTrigger += 1 }
    }

    private func formationCard(phase: FormationPhase) -> some View {
        VStack(spacing: 18) {
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(index.isMultiple(of: 2) ? SoloraTheme.gold : SoloraTheme.coral)
                        .frame(width: 5, height: 16)
                        .offset(y: -72 * phase.particleRadius)
                        .rotationEffect(.degrees(Double(index) * 45))
                        .opacity(phase.particleOpacity)
                }

                SoloraOrbView(size: 104, color: SoloraTheme.gold, isAlive: true, showsHalo: true)
                    .scaleEffect(phase.orbScale)
                    .rotationEffect(.degrees(phase.rotation))
            }
            .frame(width: 168, height: 152)

            VStack(spacing: 5) {
                Text(phase == .settled ? "A new Solora is yours" : "Forming your Solora")
                    .font(.headline)
                    .contentTransition(.interpolate)
                Text("Reflection → memory → usable proof")
                    .font(.caption)
                    .foregroundStyle(SoloraTheme.ink.opacity(0.62))
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 1)
        }
        .shadow(color: SoloraTheme.ink.opacity(0.18), radius: 30, y: 16)
        .scaleEffect(phase.cardScale)
    }
}

private enum FormationPhase: CaseIterable {
    case seed, gather, glow, settled

    var orbScale: CGFloat {
        switch self {
        case .seed: 0.86
        case .gather: 1.08
        case .glow: 0.98
        case .settled: 1
        }
    }

    var cardScale: CGFloat {
        switch self {
        case .seed: 0.97
        case .gather, .glow, .settled: 1
        }
    }

    var particleRadius: CGFloat {
        switch self {
        case .seed: 0.45
        case .gather: 0.78
        case .glow, .settled: 1
        }
    }

    var particleOpacity: Double {
        switch self {
        case .seed: 0
        case .gather: 0.9
        case .glow: 0.65
        case .settled: 0
        }
    }

    var rotation: Double {
        switch self {
        case .seed: -5
        case .gather: 4
        case .glow: -1
        case .settled: 0
        }
    }

    var animation: Animation {
        switch self {
        case .seed: .linear(duration: 0.01)
        case .gather: .spring(duration: 0.3, bounce: 0.2)
        case .glow: .timingCurve(0.23, 1, 0.32, 1, duration: 0.25)
        case .settled: .spring(duration: 0.28, bounce: 0.08)
        }
    }
}

private struct PostEventReflectionView: View {
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var reflection = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Product strategy workshop", systemImage: "calendar.badge.checkmark")
                        .font(.headline)
                    Text("Today, 3:00–4:00 PM")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Your event just ended")
                }

                Section("Take a minute") {
                    Text("What went better than you expected?")
                    Text("What is one useful follow-up to make?")
                    TextField("Add a quick reflection (optional)", text: $reflection, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Quick reflection")
                }
            }
            .navigationTitle("Capture the moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save reflection") { onSave(reflection) }
                        .accessibilityHint("Saves this sample reflection to your archive")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityElement(children: .contain)
    }
}

struct MomentRow: View {
    let moment: SoloraMoment
    var color: Color = SoloraTheme.gold

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            SoloraOrbView(size: 46, color: color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(moment.title)
                    .font(.headline)
                    .foregroundStyle(SoloraTheme.ink)
                Text(moment.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14).stroke(SoloraTheme.ink.opacity(0.07))
        }
        .accessibilityElement(children: .combine)
    }
}
