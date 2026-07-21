import AVFoundation
import Photos
import PhotosUI
import Speech
import SwiftUI
import UIKit

struct MemoryCreationPayload {
    let existingID: String?
    let context: String?
    let reflection: String
    let title: String
    let summary: String
    let memoryType: MemoryCategory
    let playbackStyle: MemoryPlaybackStyle
    let media: [Data]
    let motionMedia: [Data?]
    let retainedMotionPaths: [String?]
}

struct MemoryCreationSheet: View {
    enum Step: Int { case media, annotate, forming, review }

    let context: String?
    let existing: SoloraMoment?
    let onSave: @MainActor (MemoryCreationPayload, @escaping @MainActor (Double) -> Void) async -> SoloraMoment?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: Step = .media
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var media: [Data] = []
    @State private var images: [UIImage] = []
    @State private var motionMedia: [Data?] = []
    @State private var retainedMotionPaths: [String?] = []
    @State private var playbackStyle: MemoryPlaybackStyle = .photoSequence
    @State private var reflection = ""
    @State private var title = ""
    @State private var summary = ""
    @State private var memoryType: MemoryCategory = .event
    @State private var usesText = false
    @State private var isSaving = false
    @State private var progress = 0.0
    @State private var errorMessage: String?
    @StateObject private var transcriber = OnDeviceMemoryTranscriber()
    private let speaker = AVSpeechSynthesizer()

    init(
        context: String? = nil,
        existing: SoloraMoment? = nil,
        onSave: @escaping @MainActor (MemoryCreationPayload, @escaping @MainActor (Double) -> Void) async -> SoloraMoment?
    ) {
        self.context = context
        self.existing = existing
        self.onSave = onSave
        _reflection = State(initialValue: existing?.reflection ?? "")
        _title = State(initialValue: existing?.title ?? "")
        _summary = State(initialValue: existing?.summary ?? "")
        _memoryType = State(initialValue: existing?.memoryType ?? .event)
        _playbackStyle = State(initialValue: existing?.playbackStyle ?? .photoSequence)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoloraTheme.ink.ignoresSafeArea()
                switch step {
                case .media: mediaStep
                case .annotate: annotationStep
                case .forming: formingStep
                case .review: reviewStep
                }
            }
            .foregroundStyle(SoloraTheme.cream)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(step == .media ? "Cancel" : "Back") { goBack() }
                        .disabled(isSaving || transcriber.isRecording)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text(stepTitle).font(.caption.weight(.bold)).foregroundStyle(SoloraTheme.cream.opacity(0.64))
                }
            }
        }
        .onChange(of: pickerItems) { _, items in load(items) }
        .onChange(of: transcriber.transcript) { _, value in
            guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            reflection = value
        }
        .task { await loadExistingMedia() }
        .onDisappear { transcriber.stop() }
    }

    private var stepTitle: String {
        switch step { case .media: "1 of 4"; case .annotate: "2 of 4"; case .forming: "3 of 4"; case .review: "4 of 4" }
    }

    private var mediaStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 24)
                Text(existing == nil ? "Choose the memory" : "Refresh the memory")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("Start with one to five photos or Live Photos. Their order becomes the memory.")
                    .font(.body.weight(.medium)).foregroundStyle(SoloraTheme.cream.opacity(0.66))

                MemoryDraftOrb(images: images, size: 220, audioLevel: 0, isAlive: !reduceMotion)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)

                PhotosPicker(selection: $pickerItems, maxSelectionCount: 5, matching: .images) {
                    Label(media.isEmpty ? "Choose photos or Live Photos" : "Add or replace media", systemImage: "photo.stack.fill")
                        .font(.headline.weight(.bold)).frame(maxWidth: .infinity).frame(height: 56)
                        .background(SoloraTheme.cream, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(SoloraTheme.ink)
                }

                if !images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image).resizable().scaledToFill().frame(width: 82, height: 82).clipShape(RoundedRectangle(cornerRadius: 14))
                                    Text("\(index + 1)").font(.caption2.bold()).padding(6).background(.black.opacity(0.56), in: Circle()).padding(5)
                                }
                            }
                        }
                    }
                    Text("The playback follows this order. Reorder controls will be available in review.")
                        .font(.caption.weight(.medium)).foregroundStyle(SoloraTheme.cream.opacity(0.56))
                }

                Picker("Memory movement", selection: $playbackStyle) {
                    ForEach(MemoryPlaybackStyle.allCases) { style in Text(style.title).tag(style) }
                }
                .pickerStyle(.segmented)
                .tint(SoloraTheme.gold)

                if let errorMessage { Text(errorMessage).font(.caption.weight(.semibold)).foregroundStyle(SoloraTheme.coral) }
                Button("Continue to your reflection") { withAnimation(SoloraMotion.reveal) { step = .annotate }; speakPrompt() }
                    .font(.headline.weight(.bold)).frame(maxWidth: .infinity).frame(height: 56)
                    .background(media.isEmpty ? SoloraTheme.cream.opacity(0.18) : SoloraTheme.coral, in: RoundedRectangle(cornerRadius: 16))
                    .disabled(media.isEmpty)
            }
            .padding(20)
        }
    }

    private var annotationStep: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 18)
            Text(context.map { "What did you do at \($0)?" } ?? "Tell Solora what happened")
                .font(.system(size: 28, weight: .bold, design: .rounded)).multilineTextAlignment(.center).padding(.horizontal, 24)
            Text(usesText ? "Write it in your own words." : "Tap the memory when you are ready. Solora is listening locally.")
                .font(.subheadline.weight(.medium)).foregroundStyle(SoloraTheme.cream.opacity(0.64)).multilineTextAlignment(.center)

            ZStack {
                if transcriber.isRecording {
                    ForEach(0..<3, id: \.self) { ring in
                        Circle().stroke(SoloraTheme.gold.opacity(0.28 - Double(ring) * 0.06), lineWidth: 2)
                            .frame(width: 268 + CGFloat(ring) * 30 * (1 + transcriber.audioLevel), height: 268 + CGFloat(ring) * 30 * (1 + transcriber.audioLevel))
                    }
                }
                MemoryDraftOrb(images: images, size: 230, audioLevel: transcriber.audioLevel, isAlive: !reduceMotion)
                if !usesText {
                    Button(action: toggleRecording) { Color.clear.frame(width: 230, height: 230) }
                        .accessibilityLabel(transcriber.isRecording ? "Finish voice reflection" : "Start voice reflection")
                }
            }

            if transcriber.isRecording {
                TranscriptHalo(words: transcriber.transcript.split(separator: " ").map(String.init).suffix(8).map { $0 })
                Text(transcriber.elapsedLabel).font(.title3.monospacedDigit().weight(.bold)).foregroundStyle(SoloraTheme.gold)
            }

            if usesText {
                TextField("What happened?", text: $reflection, axis: .vertical)
                    .lineLimit(5...9).padding(16).background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            } else if !transcriber.transcript.isEmpty {
                Text(transcriber.transcript).font(.body.weight(.medium)).foregroundStyle(SoloraTheme.cream.opacity(0.86)).lineLimit(4).multilineTextAlignment(.center).padding(.horizontal, 24)
            }

            if let message = transcriber.errorMessage { Text(message).font(.caption.weight(.semibold)).foregroundStyle(SoloraTheme.coral).multilineTextAlignment(.center).padding(.horizontal, 24) }
            Spacer()
            HStack(spacing: 12) {
                Button(usesText ? "Use voice" : "Type instead") { usesText.toggle(); transcriber.stop() }
                    .font(.subheadline.weight(.bold)).frame(maxWidth: .infinity).frame(height: 50).background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                Button(transcriber.isRecording ? "Finish" : "Create memory") {
                    if transcriber.isRecording { stopAndForm() } else if !reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { formDraft() } else { toggleRecording() }
                }
                .font(.headline.weight(.bold)).frame(maxWidth: .infinity).frame(height: 50).background(SoloraTheme.coral, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(20)
        }
    }

    private var formingStep: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                TranscriptHalo(words: reflection.split(separator: " ").map(String.init).suffix(10).map { $0 })
                    .scaleEffect(1.35).opacity(0.55)
                MemoryDraftOrb(images: images, size: 250, audioLevel: 0.42, isAlive: !reduceMotion)
            }
            Text("Creating your memory") .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("Your photos and words are becoming something you can revisit.")
                .font(.subheadline.weight(.medium)).foregroundStyle(SoloraTheme.cream.opacity(0.64)).multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer()
        }
        .task { await makeDraftAndReview() }
    }

    private var reviewStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack { Text("Review your memory").font(.system(size: 32, weight: .bold, design: .rounded)); Spacer() }
                MemoryDraftOrb(images: images, size: 196, audioLevel: 0, isAlive: !reduceMotion).frame(maxWidth: .infinity)
                Text("Playback order").font(.caption.weight(.bold)).foregroundStyle(SoloraTheme.cream.opacity(0.58))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(images.indices, id: \.self) { index in
                            VStack(spacing: 6) {
                                Image(uiImage: images[index]).resizable().scaledToFill().frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 12))
                                HStack(spacing: 2) {
                                    Button { moveMedia(from: index, by: -1) } label: { Image(systemName: "chevron.left") }.disabled(index == 0)
                                    Button { removeMedia(at: index) } label: { Image(systemName: "trash") }
                                    Button { moveMedia(from: index, by: 1) } label: { Image(systemName: "chevron.right") }.disabled(index == images.count - 1)
                                }
                                .font(.caption.bold()).buttonStyle(.borderless)
                            }
                        }
                    }
                }
                TextField("Title", text: $title).font(.title3.bold()).padding(14).background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                TextField("Short summary", text: $summary, axis: .vertical).lineLimit(2...4).padding(14).background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                TextField("What happened", text: $reflection, axis: .vertical).lineLimit(4...8).padding(14).background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                Text("Colour group").font(.caption.weight(.bold)).foregroundStyle(SoloraTheme.cream.opacity(0.58))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132))], spacing: 8) {
                    ForEach(MemoryCategory.allCases) { type in
                        Button(type.title) { memoryType = type }
                            .font(.caption.weight(.bold)).padding(.horizontal, 12).frame(height: 40).frame(maxWidth: .infinity)
                            .background(memoryType == type ? SoloraTheme.gold.opacity(0.78) : .white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                if isSaving { ProgressView(value: progress).tint(SoloraTheme.gold) }
                if let errorMessage { Text(errorMessage).font(.caption.weight(.semibold)).foregroundStyle(SoloraTheme.coral) }
                Button(existing == nil ? "Save memory" : "Save changes") { save() }
                    .font(.headline.weight(.bold)).frame(maxWidth: .infinity).frame(height: 56).background(SoloraTheme.coral, in: RoundedRectangle(cornerRadius: 16)).disabled(isSaving || title.isEmpty || summary.isEmpty || reflection.isEmpty)
            }
            .padding(20)
        }
    }

    private func load(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task { @MainActor in
            var nextData: [Data] = []
            var nextImages: [UIImage] = []
            var nextMotion: [Data?] = []
            for item in items.prefix(5) {
                guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data), let jpeg = preparedJPEG(from: image) else { continue }
                nextData.append(jpeg)
                nextImages.append(image)
                do {
                    nextMotion.append(try await LivePhotoMotionExporter.motionData(for: item.itemIdentifier))
                } catch {
                    nextMotion.append(nil)
                    errorMessage = "One Live Photo couldn't be prepared as motion. You can still save its poster, or choose it again."
                }
            }
            media = nextData; images = nextImages; motionMedia = nextMotion; retainedMotionPaths = Array(repeating: nil, count: nextData.count)
            if media.isEmpty { errorMessage = "Choose images that Solora can prepare as a memory." }
        }
    }

    private func loadExistingMedia() async {
        guard media.isEmpty, let existing else { return }
        var nextData: [Data] = []
        var nextImages: [UIImage] = []
        var nextMotionPaths: [String?] = []
        for asset in existing.visualAssets.prefix(5) {
            guard let data = try? await SoloraMomentMediaDataCache.shared.data(for: asset.posterPath),
                  let image = UIImage(data: data) else { continue }
            nextData.append(data)
            nextImages.append(image)
            nextMotionPaths.append(asset.motionPath)
        }
        media = nextData
        images = nextImages
        motionMedia = Array(repeating: nil, count: nextData.count)
        retainedMotionPaths = nextMotionPaths
    }

    private func preparedJPEG(from image: UIImage) -> Data? {
        let longest = max(image.size.width, image.size.height)
        let scale = longest > 2_048 ? 2_048 / longest : 1
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let data = rendered.jpegData(compressionQuality: 0.82), data.count <= FirebaseMomentMediaRepository.maximumUploadBytes else { return nil }
        return data
    }

    private func moveMedia(from index: Int, by delta: Int) {
        let destination = index + delta
        guard images.indices.contains(destination), media.indices.contains(index), media.indices.contains(destination) else { return }
        images.swapAt(index, destination)
        media.swapAt(index, destination)
        motionMedia.swapAt(index, destination)
        retainedMotionPaths.swapAt(index, destination)
    }

    private func removeMedia(at index: Int) {
        guard images.indices.contains(index), media.indices.contains(index), images.count > 1 else { return }
        images.remove(at: index)
        media.remove(at: index)
        motionMedia.remove(at: index)
        retainedMotionPaths.remove(at: index)
    }

    private func speakPrompt() {
        guard !UIAccessibility.isVoiceOverRunning else { return }
        let utterance = AVSpeechUtterance(string: context.map { "Tell me a little about what you did at \($0)." } ?? "Tell me a little about what happened.")
        utterance.rate = 0.48; utterance.voice = .init(language: Locale.current.identifier); speaker.speak(utterance)
    }

    private func toggleRecording() { Task { if transcriber.isRecording { stopAndForm() } else { await transcriber.start() } } }
    private func stopAndForm() { transcriber.stop(); reflection = transcriber.transcript; guard !reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }; formDraft() }
    private func formDraft() { withAnimation(reduceMotion ? nil : SoloraMotion.reveal) { step = .forming } }
    private func makeDraftAndReview() async {
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 1.5))
        title = MemoryDraftMaker.title(for: reflection, context: context)
        summary = MemoryDraftMaker.summary(for: reflection)
        memoryType = MemoryCategory.suggest(for: reflection)
        withAnimation(reduceMotion ? nil : SoloraMotion.reveal) { step = .review }
    }
    private func save() {
        isSaving = true; errorMessage = nil
        let payload = MemoryCreationPayload(existingID: existing?.id, context: context, reflection: reflection, title: title, summary: summary, memoryType: memoryType, playbackStyle: playbackStyle, media: media, motionMedia: motionMedia, retainedMotionPaths: retainedMotionPaths)
        Task { @MainActor in
            let saved = await onSave(payload) { progress = $0 }
            isSaving = false
            if saved != nil { dismiss() } else { errorMessage = "Solora couldn't save this memory. Please try again." }
        }
    }
    private func goBack() { if step == .media { dismiss() } else { withAnimation(SoloraMotion.reveal) { step = Step(rawValue: step.rawValue - 1) ?? .media } } }
}

private enum MemoryDraftMaker {
    static func title(for reflection: String, context: String?) -> String {
        let first = reflection.split(whereSeparator: { ".!?\n".contains($0) }).first.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return String((first.isEmpty ? context ?? "Voice reflection" : first).prefix(120))
    }
    static func summary(for reflection: String) -> String { String(reflection.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2_000)) }
}

@MainActor private final class OnDeviceMemoryTranscriber: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var audioLevel: CGFloat = 0
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published private var elapsed = 0
    private let recognizer = SFSpeechRecognizer()
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var timer: Timer?
    private var hasInputTap = false
    private let audioLevelPipe = AudioLevelPipe()
    private var audioLevelObservation: NSObjectProtocol?

    override init() {
        super.init()
        audioLevelObservation = NotificationCenter.default.addObserver(
            forName: AudioLevelPipe.didUpdate,
            object: audioLevelPipe,
            queue: .main
        ) { [weak self] notification in
            guard let level = notification.userInfo?[AudioLevelPipe.levelKey] as? CGFloat else { return }
            Task { @MainActor [weak self] in
                self?.audioLevel = level
            }
        }
    }

    var elapsedLabel: String { String(format: "%d:%02d", elapsed / 60, elapsed % 60) }

    func start() async {
        guard !isRecording else { return }
        guard await speechAllowed(), await microphoneAllowed(), recognizer?.isAvailable == true else { errorMessage = "Allow on-device Speech Recognition and Microphone access to speak your memory."; return }
        do {
            stop()
            let audio = AVAudioSession.sharedInstance(); try audio.setCategory(.record, mode: .measurement, options: [.duckOthers]); try audio.setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest(); request.shouldReportPartialResults = true; request.requiresOnDeviceRecognition = true
            self.request = request; transcript = ""; elapsed = 0; errorMessage = nil
            let input = engine.inputNode
            let format = input.inputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                throw VoiceCaptureError.noMicrophoneInput
            }
            if hasInputTap {
                input.removeTap(onBus: 0)
                hasInputTap = false
            }
            let audioLevelPipe = audioLevelPipe
            input.installTap(onBus: 0, bufferSize: 1_024, format: format) { buffer, _ in
                request.append(buffer)
                audioLevelPipe.consume(buffer)
            }
            hasInputTap = true
            task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    if let result { self?.transcript = result.bestTranscription.formattedString }
                    if error != nil {
                        self?.errorMessage = self?.transcript.isEmpty == true ? "Solora couldn't hear a clear reflection. You can type it instead." : nil
                        self?.stop()
                    }
                }
            }
            engine.prepare(); try engine.start(); isRecording = true
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in guard let self else { return }; self.elapsed += 1; if self.elapsed >= 120 { self.stop() } }
            }
        } catch {
            errorMessage = error is VoiceCaptureError ? "No microphone input is available right now. Disconnect another audio source and try again." : "Solora couldn't start local voice capture. You can type your reflection instead."
            stop()
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        if hasInputTap {
            engine.inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }
        if engine.isRunning { engine.stop() }
        request?.endAudio(); task?.cancel(); request = nil; task = nil
        isRecording = false; audioLevel = 0; try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func speechAllowed() async -> Bool { switch SFSpeechRecognizer.authorizationStatus() { case .authorized: true; case .notDetermined: await withCheckedContinuation { continuation in SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) } }; default: false } }
    private func microphoneAllowed() async -> Bool { switch AVAudioSession.sharedInstance().recordPermission { case .granted: true; case .undetermined: await withCheckedContinuation { continuation in AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) } }; default: false } }
}

private enum VoiceCaptureError: Error { case noMicrophoneInput }

/// Keeps the Audio Engine's real-time callback free of SwiftUI and actor-isolated state.
private final class AudioLevelPipe: @unchecked Sendable {
    static let didUpdate = Notification.Name("SoloraAudioLevelDidUpdate")
    static let levelKey = "level"
    private var smoothedLevel: CGFloat = 0

    func consume(_ buffer: AVAudioPCMBuffer) {
        guard let values = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return }
        let sum = (0..<count).reduce(CGFloat.zero) { $0 + CGFloat(values[$1] * values[$1]) }
        let raw = min(1, max(0, sqrt(sum / CGFloat(count)) * 8))
        smoothedLevel = smoothedLevel == 0 ? raw : smoothedLevel * 0.76 + raw * 0.24
        let level = smoothedLevel
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            NotificationCenter.default.post(
                name: Self.didUpdate,
                object: self,
                userInfo: [Self.levelKey: level]
            )
        }
    }
}

private enum LivePhotoMotionExporter {
    static func motionData(for localIdentifier: String?) async throws -> Data? {
        guard let localIdentifier,
              let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject,
              let resource = PHAssetResource.assetResources(for: asset).first(where: { $0.type == .pairedVideo }) else {
            return nil
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        defer { try? FileManager.default.removeItem(at: url) }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: nil) { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
        let data = try Data(contentsOf: url)
        guard data.count <= FirebaseMomentMediaRepository.maximumMotionUploadBytes else {
            throw MomentMediaError.invalidMotionSize
        }
        return data
    }
}

private struct MemoryDraftOrb: View {
    let images: [UIImage]; let size: CGFloat; let audioLevel: CGFloat; let isAlive: Bool
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.15)) { timeline in
            let index = images.isEmpty ? 0 : Int(timeline.date.timeIntervalSinceReferenceDate / 3.4) % images.count
            ZStack {
                Circle().fill(RadialGradient(colors: [.white.opacity(0.95), SoloraTheme.cream.opacity(0.72), SoloraTheme.gold.opacity(0.28), SoloraTheme.plum.opacity(0.25)], center: .topLeading, startRadius: 1, endRadius: size * 0.75))
                if images.indices.contains(index) { Image(uiImage: images[index]).resizable().scaledToFill().frame(width: size * 0.92, height: size * 0.92).clipShape(Circle()).transition(.opacity) }
                Circle().fill(LinearGradient(colors: [.white.opacity(0.42), .clear, SoloraTheme.gold.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)).blendMode(.screen)
                Ellipse().fill(.white.opacity(0.72)).frame(width: size * 0.42, height: size * 0.16).blur(radius: 6).rotationEffect(.degrees(-32)).offset(x: -size * 0.18, y: -size * 0.24)
                Circle().strokeBorder(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.15), SoloraTheme.gold.opacity(0.68), .white.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: max(2, size * 0.018))
            }
            .frame(width: size, height: size).scaleEffect(1 + audioLevel * 0.06).shadow(color: SoloraTheme.gold.opacity(0.28 + audioLevel * 0.34), radius: size * (0.12 + audioLevel * 0.14)).animation(.easeInOut(duration: 0.2), value: audioLevel)
        }
        .accessibilityLabel("Memory orb preview")
    }
}

private struct TranscriptHalo: View {
    let words: [String]
    var body: some View { HStack(spacing: 5) { ForEach(Array(words.enumerated()), id: \.offset) { index, word in Text(word).font(.caption2.weight(.bold)).foregroundStyle(SoloraTheme.gold.opacity(0.72)).rotationEffect(.degrees(Double(index - words.count / 2) * 5)) } }.lineLimit(1).accessibilityLabel(words.joined(separator: " ")) }
}
