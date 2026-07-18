import SwiftUI

struct TodayView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let moments: [SoloraMoment]
    let onSave: (String) -> Void

    @State private var showsCapture = false
    @State private var showsFormation = false
    @State private var savedReflection = false
    @State private var captureTask: Task<Void, Never>?
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                SoloraTheme.paper.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        dayHeader
                            .soloraEntrance()

                        eventCard
                            .soloraEntrance(index: 1, distance: 14)

                        recentMemories
                            .soloraEntrance(index: 2, distance: 14)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showsCapture) {
                CaptureMomentSheet { reflection in
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
                    Label("Added to your lore", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SoloraTheme.cream)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 12)
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

    private var dayHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(Date.now.formatted(.dateTime.day().month(.wide)))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.56))
            }

            Spacer()

            ZStack {
                Circle().fill(SoloraTheme.ink)
                Circle()
                    .trim(from: 0.08, to: 0.78)
                    .stroke(SoloraTheme.gold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .padding(9)
                Circle().fill(SoloraTheme.coral).frame(width: 8, height: 8)
            }
            .frame(width: 45, height: 45)
            .accessibilityHidden(true)
        }
        .foregroundStyle(SoloraTheme.ink)
    }

    private var eventCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SoloraTheme.coral)

            Circle()
                .fill(SoloraTheme.gold)
                .frame(width: 190, height: 190)
                .offset(x: 220, y: -136)

            Circle()
                .stroke(SoloraTheme.cream.opacity(0.42), lineWidth: 32)
                .frame(width: 220, height: 220)
                .offset(x: 176, y: -120)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text("04:02")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .tracking(-2.2)
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 17, weight: .bold))
                        .padding(11)
                        .background(SoloraTheme.ink.opacity(0.12), in: Circle())
                }

                Spacer()

                Text("Product strategy workshop")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .lineLimit(2)
                    .frame(maxWidth: 260, alignment: .leading)

                Text("ended 2 min ago")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.62))
                    .padding(.top, 4)

                Button {
                    savedReflection = false
                    showsCapture = true
                } label: {
                    HStack {
                        Text("Keep this")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(SoloraTheme.cream)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(SoloraPressButtonStyle())
                .padding(.top, 20)
                .accessibilityHint("Opens a quick reflection for the finished event")
            }
            .padding(20)
        }
        .foregroundStyle(SoloraTheme.ink)
        .frame(height: 336)
        .clipped()
        .soloraHairline(SoloraTheme.ink.opacity(0.12), radius: 18)
    }

    private var recentMemories: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Still glowing")
                    .font(.title3.weight(.bold))
                Spacer()
                Text("\(moments.count)")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(SoloraTheme.coral)
                    .contentTransition(.numericText())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(Array(moments.prefix(5).enumerated()), id: \.element.id) { index, moment in
                        RecentMemory(moment: moment, color: SoloraTheme.orbColors[index % SoloraTheme.orbColors.count])
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
            .contentMargins(.horizontal, 0, for: .scrollContent)
        }
        .foregroundStyle(SoloraTheme.ink)
    }

    private func completeCapture(_ reflection: String) {
        captureTask?.cancel()
        toastTask?.cancel()
        savedReflection = false
        onSave(reflection)
        showsCapture = false

        withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.responsive) {
            showsFormation = true
        }

        captureTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 500 : 1_650))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.responsive) {
                showsFormation = false
                savedReflection = true
            }

            toastTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.1))
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.quick) {
                    savedReflection = false
                }
            }
        }
    }
}

private struct RecentMemory: View {
    let moment: SoloraMoment
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            SoloraOrbView(size: 68, color: color)
                .accessibilityHidden(true)

            Text(shortTitle)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 82)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(moment.title). \(moment.summary)")
    }

    private var shortTitle: String {
        moment.title
            .replacingOccurrences(of: "Found ", with: "")
            .replacingOccurrences(of: "Made ", with: "")
            .replacingOccurrences(of: "Built ", with: "")
    }
}

private struct CaptureMomentSheet: View {
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reflection = ""

    private let prompts = [
        "I clarified the decision.",
        "I met someone worth following up with.",
        "I saw the problem differently."
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                SoloraTheme.cream.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        SoloraOrbView(size: 54, color: SoloraTheme.coral, isAlive: true)
                            .accessibilityHidden(true)
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(SoloraTheme.ink)
                                .frame(width: 44, height: 44)
                                .background(SoloraTheme.ink.opacity(0.07), in: Circle())
                        }
                        .accessibilityLabel("Close")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("What changed?")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text("One thought is enough.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(SoloraTheme.ink.opacity(0.58))
                    }

                    VStack(spacing: 8) {
                        ForEach(prompts, id: \.self) { prompt in
                            Button {
                                withAnimation(reduceMotion ? nil : SoloraMotion.responsive) {
                                    reflection = prompt
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(reflection == prompt ? SoloraTheme.coral : SoloraTheme.ink.opacity(0.12))
                                        .frame(width: 10, height: 10)
                                    Text(prompt)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                }
                                .foregroundStyle(SoloraTheme.ink)
                                .padding(.horizontal, 15)
                                .frame(height: 50)
                                .background(.white.opacity(reflection == prompt ? 0.72 : 0.38), in: RoundedRectangle(cornerRadius: 12))
                                .soloraHairline(reflection == prompt ? SoloraTheme.coral.opacity(0.5) : SoloraTheme.ink.opacity(0.08), radius: 12)
                            }
                            .buttonStyle(SoloraPressButtonStyle(pressedScale: 0.985))
                        }
                    }

                    TextField("Or write your own…", text: $reflection, axis: .vertical)
                        .font(.body.weight(.medium))
                        .lineLimit(3...5)
                        .padding(15)
                        .background(.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 12))
                        .soloraHairline(radius: 12)

                    Spacer(minLength: 0)

                    Button {
                        onSave(reflection)
                    } label: {
                        HStack {
                            Text("Keep it")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(SoloraTheme.cream)
                        .padding(.horizontal, 18)
                        .frame(height: 54)
                        .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 13))
                    }
                    .buttonStyle(SoloraPressButtonStyle())
                }
                .padding(20)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

private struct SoloraFormationOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var trigger = 0

    var body: some View {
        ZStack {
            SoloraTheme.ink.ignoresSafeArea()

            if reduceMotion {
                formation(phase: .settled)
            } else {
                formation(phase: .seed)
                    .phaseAnimator(FormationPhase.allCases, trigger: trigger) { content, phase in
                        formation(phase: phase)
                    } animation: { phase in
                        phase.animation
                    }
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Added to your lore")
        .onAppear { trigger += 1 }
    }

    private func formation(phase: FormationPhase) -> some View {
        VStack(spacing: 26) {
            ZStack {
                ForEach(0..<7, id: \.self) { index in
                    Circle()
                        .fill(SoloraTheme.orbColors[index % SoloraTheme.orbColors.count])
                        .frame(width: 18, height: 18)
                        .offset(y: -116 * phase.particleRadius)
                        .rotationEffect(.degrees(Double(index) * (360 / 7)))
                        .opacity(phase.particleOpacity)
                }

                SoloraOrbView(
                    size: 144,
                    color: SoloraTheme.gold,
                    isAlive: true,
                    showsHalo: phase != .seed
                )
                .scaleEffect(phase.orbScale)
                .rotationEffect(.degrees(phase.rotation))
            }
            .frame(width: 280, height: 280)

            Text(phase == .settled ? "Kept." : "Becoming lore…")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(SoloraTheme.cream)
                .contentTransition(.interpolate)
        }
    }
}

private enum FormationPhase: CaseIterable {
    case seed, gather, glow, settled

    var orbScale: CGFloat {
        switch self {
        case .seed: 0.90
        case .gather: 1.08
        case .glow: 0.98
        case .settled: 1
        }
    }

    var particleRadius: CGFloat {
        switch self {
        case .seed: 1
        case .gather: 0.42
        case .glow: 0.08
        case .settled: 0
        }
    }

    var particleOpacity: Double {
        switch self {
        case .seed: 0
        case .gather: 0.95
        case .glow: 0.55
        case .settled: 0
        }
    }

    var rotation: Double {
        switch self {
        case .seed: -7
        case .gather: 4
        case .glow: -1
        case .settled: 0
        }
    }

    var animation: Animation {
        switch self {
        case .seed: .linear(duration: 0.01)
        case .gather: .spring(duration: 0.36, bounce: 0.12)
        case .glow: .timingCurve(0.23, 1, 0.32, 1, duration: 0.28)
        case .settled: .spring(duration: 0.3, bounce: 0.05)
        }
    }
}

struct MomentRow: View {
    let moment: SoloraMoment
    var color: Color = SoloraTheme.gold

    var body: some View {
        HStack(spacing: 13) {
            SoloraOrbView(size: 44, color: color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(moment.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SoloraTheme.ink)
                    .lineLimit(1)
                Text(moment.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.caption)
                    .foregroundStyle(SoloraTheme.ink.opacity(0.50))
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(SoloraTheme.ink.opacity(0.32))
        }
        .padding(.horizontal, 14)
        .frame(height: 66)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
        .soloraHairline(radius: 12)
        .accessibilityElement(children: .combine)
    }
}
