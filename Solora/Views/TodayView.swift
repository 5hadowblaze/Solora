import AVFoundation
import PhotosUI
import SwiftUI
import UIKit
import Speech
@preconcurrency import FirebaseFunctions

struct TodayView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let moments: [SoloraMoment]
    let assistantStore: SoloraAssistantStore
    let onSave: @MainActor (String, Data?, String?, @escaping @MainActor (Double) -> Void) async -> SoloraMoment?
    let onOpenMemory: @MainActor (String) -> Void

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
            .sheet(isPresented: $showsCapture, onDismiss: {
                assistantStore.endChildPresentation(.reflection)
            }) {
                CaptureMomentSheet(assistantStore: assistantStore) { reflection, photoData, voiceAnnotation, onProgress in
                    await completeCapture(reflection, photoData: photoData, voiceAnnotation: voiceAnnotation, onProgress: onProgress)
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
                    assistantStore.beginReflection(context: "Product strategy workshop")
                    assistantStore.beginChildPresentation(.reflection)
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

    @MainActor
    private func completeCapture(
        _ reflection: String,
        photoData: Data?,
        voiceAnnotation: String? = nil,
        onProgress: @escaping @MainActor (Double) -> Void
    ) async -> Bool {
        captureTask?.cancel()
        toastTask?.cancel()
        savedReflection = false

        withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.responsive) {
            showsFormation = true
        }

        guard let savedMoment = await onSave(reflection, photoData, voiceAnnotation, onProgress) else {
            withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.responsive) {
                showsFormation = false
            }
            return false
        }
        showsCapture = false

        captureTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 500 : 1_650))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.responsive) {
                showsFormation = false
                savedReflection = true
            }

            if voiceAnnotation != nil {
                onOpenMemory(savedMoment.id)
            }

            toastTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.1))
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.quick) {
                    savedReflection = false
                }
            }
        }
        return true
    }
}

private struct RecentMemory: View {
    let moment: SoloraMoment
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            SoloraOrbView(
                size: 68,
                color: color,
                mediaPath: moment.bubblePhotoPath,
                stickerPath: moment.bubbleStickerPath
            )
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
    @ObservedObject var assistantStore: SoloraAssistantStore
    let onSave: @MainActor (String, Data?, String?, @escaping @MainActor (Double) -> Void) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reflection = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoThumbnail: Image?
    @State private var isSaving = false
    @State private var uploadProgress = 0.0
    @State private var errorMessage: String?
    @StateObject private var voiceAnnotation = VoiceAnnotationRecorder()

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
                        SoloraReflectionAssistantIdentity(store: assistantStore)
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

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: voiceAnnotation.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundStyle(voiceAnnotation.isRecording ? SoloraTheme.coral : SoloraTheme.lavender)
                                .symbolEffect(.pulse, isActive: voiceAnnotation.isRecording)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(voiceAnnotation.isRecording ? "Listening to your note" : "Annotate by voice")
                                    .font(.subheadline.weight(.bold))
                                Text("Speak naturally — Solora will shape it only when you finish.")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(SoloraTheme.ink.opacity(0.56))
                            }
                            Spacer(minLength: 8)
                            Button(voiceAnnotation.isRecording ? "Done" : "Record") {
                                voiceAnnotation.toggle()
                            }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(voiceAnnotation.isRecording ? SoloraTheme.cream : SoloraTheme.ink)
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(voiceAnnotation.isRecording ? SoloraTheme.coral : SoloraTheme.ink.opacity(0.08), in: Capsule())
                            .disabled(isSaving)
                        }

                        if !voiceAnnotation.transcript.isEmpty {
                            Text(voiceAnnotation.transcript)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(SoloraTheme.ink.opacity(0.72))
                                .lineLimit(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let message = voiceAnnotation.errorMessage {
                            Text(message)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SoloraTheme.coral)
                        }
                    }
                    .padding(14)
                    .background(SoloraTheme.lavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    .soloraHairline(SoloraTheme.lavender.opacity(0.30), radius: 14)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack(spacing: 12) {
                            if let photoThumbnail {
                                photoThumbnail
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                Image(systemName: "photo.badge.plus")
                                    .font(.headline.weight(.semibold))
                                    .frame(width: 44, height: 44)
                                    .background(SoloraTheme.ink.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                            }
                            Text(photoData == nil ? "Add photo" : "Photo added")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        .foregroundStyle(SoloraTheme.ink)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)

                    if isSaving, photoData != nil {
                        ProgressView(value: uploadProgress) {
                            Text("Uploading photo…").font(.caption.weight(.semibold))
                        }
                        .tint(SoloraTheme.coral)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SoloraTheme.coral)
                    }

                    Spacer(minLength: 0)

                    Button {
                        let cleanedAnnotation = voiceAnnotation.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                        let note = cleanedAnnotation.isEmpty ? reflection : cleanedAnnotation
                        voiceAnnotation.stop()
                        assistantStore.continueReflection(note: note)
                        errorMessage = nil
                        isSaving = true
                        Task { @MainActor in
                            let didSave = await onSave(note, photoData, cleanedAnnotation.isEmpty ? nil : cleanedAnnotation) { progress in
                                uploadProgress = progress
                            }
                            isSaving = false
                            if !didSave { errorMessage = "This moment could not be saved. Please try again." }
                        }
                    } label: {
                        HStack {
                            Text(voiceAnnotation.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Keep it" : "Turn voice note into lore")
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
                    .disabled(isSaving || (reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && voiceAnnotation.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                }
                .padding(20)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onChange(of: selectedPhoto) { _, item in
            guard let item else {
                photoData = nil
                photoThumbnail = nil
                return
            }
            Task { @MainActor in
                do {
                    guard let rawData = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: rawData),
                          let preparedData = preparedJPEG(from: image) else {
                        throw MomentMediaError.invalidSize
                    }
                    photoData = preparedData
                    photoThumbnail = Image(uiImage: image)
                    errorMessage = nil
                } catch {
                    selectedPhoto = nil
                    photoData = nil
                    photoThumbnail = nil
                    errorMessage = "That photo could not be prepared. Choose another image."
                }
            }
        }
    }

    private func preparedJPEG(from image: UIImage) -> Data? {
        let longestSide = max(image.size.width, image.size.height)
        let scale = longestSide > 2_048 ? 2_048 / longestSide : 1
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard let data = rendered.jpegData(compressionQuality: 0.82),
              data.count <= FirebaseMomentMediaRepository.maximumUploadBytes else { return nil }
        return data
    }
}

@MainActor
private final class VoiceAnnotationRecorder: NSObject, ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isRecording = false
    @Published private(set) var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let recognizer = SFSpeechRecognizer()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isStarting = false

    func toggle() {
        isRecording ? stop() : start()
    }

    func start() {
        guard !isRecording, !isStarting else { return }
        isStarting = true
        Task { @MainActor in
            defer { isStarting = false }
            guard await Self.hasSpeechPermission() else {
                errorMessage = "Allow Speech Recognition to annotate a memory by voice."
                return
            }
            guard await Self.hasMicrophonePermission() else {
                errorMessage = "Allow Microphone access to annotate a memory by voice."
                return
            }
            guard recognizer?.isAvailable == true else {
                errorMessage = "Voice annotation is unavailable right now. Try again in a moment."
                return
            }

            do {
                try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: [.duckOthers])
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                let request = SFSpeechAudioBufferRecognitionRequest()
                request.shouldReportPartialResults = true
                recognitionRequest = request
                recognitionTask?.cancel()
                errorMessage = nil
                transcript = ""

                let input = audioEngine.inputNode
                input.removeTap(onBus: 0)
                let format = input.outputFormat(forBus: 0)
                guard format.sampleRate > 0, format.channelCount > 0 else {
                    throw VoiceAnnotationRecorderError.inputUnavailable
                }
                input.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak self] buffer, _ in
                    self?.recognitionRequest?.append(buffer)
                }

                recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        if let result {
                            transcript = result.bestTranscription.formattedString
                            if result.isFinal { stop() }
                        }
                        if error != nil, !transcript.isEmpty { stop() }
                    }
                }
                audioEngine.prepare()
                try audioEngine.start()
                isRecording = true
            } catch {
                stop()
                errorMessage = "Solora could not start voice annotation. Please try again."
            }
        }
    }

    func stop() {
        guard isRecording || audioEngine.isRunning else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private static func hasSpeechPermission() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return true
        case .denied, .restricted: return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        @unknown default: return false
        }
    }

    private static func hasMicrophonePermission() async -> Bool {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted: return true
        case .denied: return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default: return false
        }
    }
}

private enum VoiceAnnotationRecorderError: Error {
    case inputUnavailable
}

struct VoiceMemoryDraft: Decodable, Equatable {
    let title: String
    let summary: String
    let category: String
}

struct VoiceMemoryAnnotationService {
    func makeDraft(from transcript: String) async throws -> VoiceMemoryDraft {
        let result = try await Functions.functions()
            .httpsCallable("annotateVoiceMemory")
            .call(["transcript": transcript])
        guard let payload = result.data as? [String: Any],
              let title = payload["title"] as? String,
              let summary = payload["summary"] as? String,
              let category = payload["category"] as? String else {
            throw VoiceMemoryAnnotationError.invalidResponse
        }
        return VoiceMemoryDraft(title: title, summary: summary, category: category)
    }
}

enum VoiceMemoryAnnotationError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "Solora could not shape that voice note into a memory. Please try again."
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
            SoloraOrbView(
                size: 44,
                color: color,
                mediaPath: moment.bubblePhotoPath,
                stickerPath: moment.bubbleStickerPath
            )
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
