import AVFoundation
import Foundation
@preconcurrency import FirebaseFunctions
@preconcurrency import WebRTC

struct SoloraRealtimeCredential: Equatable, Sendable {
    let value: String
    let expiresAt: Date?
}

protocol SoloraRealtimeCredentialProviding: Sendable {
    func fetchCredential() async throws -> SoloraRealtimeCredential
}

struct FirebaseRealtimeCredentialProvider: SoloraRealtimeCredentialProviding {
    func fetchCredential() async throws -> SoloraRealtimeCredential {
        let result = try await Functions.functions()
            .httpsCallable("createRealtimeClientSecret")
            .call()
        guard let payload = result.data as? [String: Any],
              let value = payload["value"] as? String,
              !value.isEmpty else {
            throw SoloraRealtimeError.invalidCredential
        }
        let expiresAt = (payload["expires_at"] as? TimeInterval).map(Date.init(timeIntervalSince1970:))
        return SoloraRealtimeCredential(value: value, expiresAt: expiresAt)
    }
}

enum SoloraRealtimeConnectionState: Equatable, Sendable {
    case idle
    case requestingMicrophone
    case connecting
    case connected
    case recovering
    case failed(String)

    var title: String {
        switch self {
        case .idle: "Voice is ready"
        case .requestingMicrophone: "Waiting for microphone access…"
        case .connecting: "Connecting to Solora…"
        case .connected: "Listening"
        case .recovering: "Reconnecting…"
        case .failed(let message): message
        }
    }

    var isActive: Bool {
        switch self {
        case .requestingMicrophone, .connecting, .connected, .recovering: true
        case .idle, .failed: false
        }
    }
}

enum SoloraVoiceActivity: Equatable, Sendable {
    case idle
    case listening
    case speaking
}

enum SoloraRealtimeError: LocalizedError {
    case microphoneDenied
    case invalidCredential
    case invalidOffer
    case openAIRejectedConnection
    case dataChannelUnavailable

    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            "Microphone access is off. Enable it in Settings to talk with Solora."
        case .invalidCredential:
            "Solora could not obtain a secure voice credential."
        case .invalidOffer:
            "Solora could not prepare the voice connection."
        case .openAIRejectedConnection:
            "The voice service did not accept the connection. Please try again."
        case .dataChannelUnavailable:
            "Solora connected without its app tools. Please reconnect."
        }
    }
}

@MainActor
final class SoloraRealtimeSession: NSObject, ObservableObject {
    typealias ToolHandler = (SoloraAssistantToolCall) -> SoloraAssistantToolResult

    @Published private(set) var state: SoloraRealtimeConnectionState = .idle
    @Published private(set) var isMuted = false
    @Published private(set) var lastTranscript = ""
    @Published private(set) var voiceActivity: SoloraVoiceActivity = .idle

    var toolHandler: ToolHandler?

    private let credentialProvider: any SoloraRealtimeCredentialProviding
    private let toolDescriptors: [SoloraAssistantToolDescriptor]
    private let peerConnectionFactory = RTCPeerConnectionFactory()
    private var peerConnection: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?
    private var localAudioTrack: RTCAudioTrack?
    private var handledCallIDs: Set<String> = []
    private var connectionTask: Task<Void, Never>?
    private var recoveryAttempt = 0
    private var endedByUser = false

    init(
        toolDescriptors: [SoloraAssistantToolDescriptor],
        credentialProvider: any SoloraRealtimeCredentialProviding = FirebaseRealtimeCredentialProvider()
    ) {
        self.toolDescriptors = toolDescriptors
        self.credentialProvider = credentialProvider
        super.init()
    }

    func start() {
        guard !state.isActive else { return }
        endedByUser = false
        recoveryAttempt = 0
        connect(after: .zero)
    }

    func toggleMute() {
        guard state == .connected else { return }
        isMuted.toggle()
        localAudioTrack?.isEnabled = !isMuted
    }

    func end() {
        endedByUser = true
        connectionTask?.cancel()
        connectionTask = nil
        tearDown()
        voiceActivity = .idle
        state = .idle
    }

    private func connect(after delay: Duration) {
        connectionTask?.cancel()
        connectionTask = Task { @MainActor [weak self] in
            guard let self else { return }
            if delay > .zero {
                state = .recovering
                try? await Task.sleep(for: delay)
            }
            guard !Task.isCancelled, !endedByUser else { return }

            do {
                state = .requestingMicrophone
                guard await Self.requestMicrophonePermission() else {
                    throw SoloraRealtimeError.microphoneDenied
                }
                state = .connecting
                try configureAudioSession()
                let credential = try await credentialProvider.fetchCredential()
                try await establishWebRTC(using: credential.value)
            } catch is CancellationError {
                return
            } catch {
                tearDown()
                voiceActivity = .idle
                state = .failed(Self.userFacingMessage(for: error))
            }
        }
    }

    private func establishWebRTC(using ephemeralCredential: String) async throws {
        let configuration = RTCConfiguration()
        configuration.sdpSemantics = .unifiedPlan
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
        )
        guard let peerConnection = peerConnectionFactory.peerConnection(
            with: configuration,
            constraints: constraints,
            delegate: self
        ) else {
            throw SoloraRealtimeError.invalidOffer
        }
        self.peerConnection = peerConnection

        let audioSource = peerConnectionFactory.audioSource(with: RTCMediaConstraints(
            mandatoryConstraints: [
                "googEchoCancellation": "true",
                "googAutoGainControl": "true",
                "googNoiseSuppression": "true",
            ],
            optionalConstraints: nil
        ))
        let audioTrack = peerConnectionFactory.audioTrack(with: audioSource, trackId: "solora-microphone")
        audioTrack.isEnabled = !isMuted
        localAudioTrack = audioTrack
        peerConnection.add(audioTrack, streamIds: ["solora-audio"])

        let channelConfiguration = RTCDataChannelConfiguration()
        guard let dataChannel = peerConnection.dataChannel(
            forLabel: "oai-events",
            configuration: channelConfiguration
        ) else {
            throw SoloraRealtimeError.dataChannelUnavailable
        }
        dataChannel.delegate = self
        self.dataChannel = dataChannel

        let offer = try await createOffer(on: peerConnection)
        try await setLocalDescription(offer, on: peerConnection)
        guard let localSDP = peerConnection.localDescription?.sdp else {
            throw SoloraRealtimeError.invalidOffer
        }
        let answerSDP = try await exchangeSDP(localSDP, credential: ephemeralCredential)
        try await setRemoteDescription(
            RTCSessionDescription(type: .answer, sdp: answerSDP),
            on: peerConnection
        )
    }

    private func exchangeSDP(_ offer: String, credential: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/realtime/calls")!)
        request.httpMethod = "POST"
        request.httpBody = Data(offer.utf8)
        request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization")
        request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode),
              let answer = String(data: data, encoding: .utf8),
              !answer.isEmpty else {
            throw SoloraRealtimeError.openAIRejectedConnection
        }
        return answer
    }

    private func createOffer(on peerConnection: RTCPeerConnection) async throws -> RTCSessionDescription {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<RTCSessionDescription, Error>) in
            peerConnection.offer(for: RTCMediaConstraints(
                mandatoryConstraints: [
                    "OfferToReceiveAudio": "true",
                    "OfferToReceiveVideo": "false",
                ],
                optionalConstraints: nil
            )) { description, error in
                if let description {
                    continuation.resume(returning: description)
                } else {
                    continuation.resume(throwing: error ?? SoloraRealtimeError.invalidOffer)
                }
            }
        }
    }

    private func setLocalDescription(
        _ description: RTCSessionDescription,
        on peerConnection: RTCPeerConnection
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            peerConnection.setLocalDescription(description) { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    private func setRemoteDescription(
        _ description: RTCSessionDescription,
        on peerConnection: RTCPeerConnection
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            peerConnection.setRemoteDescription(description) { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    private func sendSessionConfiguration() {
        send(event: [
            "type": "session.update",
            "session": [
                "type": "realtime",
                "model": "gpt-realtime-2.1",
                "tools": SoloraRealtimeToolCodec.toolSchemas(from: toolDescriptors),
                "tool_choice": "auto",
            ],
        ])
    }

    private func handleServerEvent(_ data: Data) {
        guard let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = event["type"] as? String else { return }

        if type == "conversation.item.input_audio_transcription.completed",
           let transcript = event["transcript"] as? String {
            lastTranscript = transcript
        }

        switch type {
        case "input_audio_buffer.speech_started", "input_audio_buffer.speech_stopped", "response.done":
            voiceActivity = .listening
        case "response.audio.delta", "response.output_audio.delta", "response.output_audio_transcript.delta":
            voiceActivity = .speaking
        default:
            break
        }

        guard let call = SoloraRealtimeToolCodec.functionCall(from: event),
              handledCallIDs.insert(call.callID).inserted else { return }
        let result: SoloraAssistantToolResult
        if let decoded = SoloraRealtimeToolCodec.decodeToolCall(name: call.name, arguments: call.arguments) {
            result = toolHandler?(decoded) ?? .unavailable("That Solora tool is not available right now.")
        } else {
            result = .unavailable("The requested Solora tool arguments were not valid.")
        }
        send(event: [
            "type": "conversation.item.create",
            "item": [
                "type": "function_call_output",
                "call_id": call.callID,
                "output": SoloraRealtimeToolCodec.outputJSON(for: result),
            ],
        ])
        send(event: ["type": "response.create"])
    }

    private func send(event: [String: Any]) {
        guard let dataChannel, dataChannel.readyState == .open,
              let data = try? JSONSerialization.data(withJSONObject: event) else { return }
        dataChannel.sendData(RTCDataBuffer(data: data, isBinary: false))
    }

    private func recoverIfNeeded() {
        guard !endedByUser, state.isActive, recoveryAttempt < 2 else {
            if !endedByUser { state = .failed("The voice connection ended. Tap retry to reconnect.") }
            return
        }
        recoveryAttempt += 1
        tearDown()
        connect(after: .seconds(recoveryAttempt))
    }

    private func tearDown() {
        dataChannel?.delegate = nil
        dataChannel?.close()
        dataChannel = nil
        peerConnection?.close()
        peerConnection = nil
        localAudioTrack = nil
        handledCallIDs.removeAll()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker, .allowBluetoothHFP]
        )
        try audioSession.setActive(true)
    }

    private static func requestMicrophonePermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: true
        case .denied: false
        case .undetermined:
            await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default: false
        }
    }

    private static func userFacingMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? "Solora voice could not connect. Please try again."
    }
}

extension SoloraRealtimeSession: RTCDataChannelDelegate {
    nonisolated func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch dataChannel.readyState {
            case .open:
                recoveryAttempt = 0
                state = .connected
                voiceActivity = .listening
                sendSessionConfiguration()
            case .closing, .closed:
                recoverIfNeeded()
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func dataChannel(
        _ dataChannel: RTCDataChannel,
        didReceiveMessageWith buffer: RTCDataBuffer
    ) {
        Task { @MainActor [weak self] in self?.handleServerEvent(buffer.data) }
    }
}

extension SoloraRealtimeSession: RTCPeerConnectionDelegate {
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    nonisolated func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        guard newState == .failed || newState == .disconnected || newState == .closed else { return }
        Task { @MainActor [weak self] in
            guard let self, self.peerConnection === peerConnection else { return }
            self.recoverIfNeeded()
        }
    }
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}

struct SoloraRealtimeFunctionCall: Equatable {
    let callID: String
    let name: String
    let arguments: String
}

enum SoloraRealtimeToolCodec {
    static func toolSchemas(from descriptors: [SoloraAssistantToolDescriptor]) -> [[String: Any]] {
        descriptors.map { descriptor in
            let properties = Dictionary(uniqueKeysWithValues: descriptor.fields.map { field in
                var schema: [String: Any] = [
                    "type": field.type == .integer ? "integer" : field.type == .boolean ? "boolean" : "string",
                    "description": field.description,
                ]
                if field.type == .date { schema["format"] = "date-time" }
                if let values = enumValues(for: descriptor.name, field: field.name) { schema["enum"] = values }
                return (field.name, schema)
            })
            return [
                "type": "function",
                "name": descriptor.name,
                "description": descriptor.description,
                "parameters": [
                    "type": "object",
                    "properties": properties,
                    "required": descriptor.fields.filter(\.required).map(\.name),
                    "additionalProperties": false,
                ],
            ]
        }
    }

    static func functionCall(from event: [String: Any]) -> SoloraRealtimeFunctionCall? {
        if event["type"] as? String == "response.function_call_arguments.done",
           let callID = event["call_id"] as? String,
           let name = event["name"] as? String,
           let arguments = event["arguments"] as? String {
            return .init(callID: callID, name: name, arguments: arguments)
        }
        guard event["type"] as? String == "response.output_item.done",
              let item = event["item"] as? [String: Any],
              item["type"] as? String == "function_call",
              let callID = item["call_id"] as? String,
              let name = item["name"] as? String,
              let arguments = item["arguments"] as? String else { return nil }
        return .init(callID: callID, name: name, arguments: arguments)
    }

    static func decodeToolCall(name: String, arguments: String) -> SoloraAssistantToolCall? {
        guard let data = arguments.data(using: .utf8),
              let values = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        switch name {
        case "search_memory_summaries":
            guard let query = values["query"] as? String else { return nil }
            return .searchMemorySummaries(query: query, limit: values["limit"] as? Int ?? 8)
        case "read_memory_summary":
            guard let memoryID = values["memoryID"] as? String else { return nil }
            return .readMemorySummary(memoryID: memoryID)
        case "prepare_memory_draft":
            guard let title = values["title"] as? String,
                  let summary = values["summary"] as? String,
                  let dateString = values["occurredAt"] as? String,
                  let occurredAt = ISO8601DateFormatter().date(from: dateString) else { return nil }
            return .prepareMemoryDraft(
                title: title,
                summary: summary,
                occurredAt: occurredAt,
                category: values["category"] as? String
            )
        case "request_memory_change_confirmation":
            guard let draftID = values["draftID"] as? String,
                  let change = values["change"] as? String else { return nil }
            if change == "create" {
                return .requestMemoryChangeConfirmation(draftID: draftID, change: .create)
            }
            guard change == "update", let memoryID = values["memoryID"] as? String else { return nil }
            return .requestMemoryChangeConfirmation(draftID: draftID, change: .update(memoryID: memoryID))
        case "begin_reflection":
            guard let context = values["context"] as? String else { return nil }
            return .beginReflection(context: context)
        case "continue_reflection":
            guard let sessionID = values["sessionID"] as? String,
                  let note = values["note"] as? String else { return nil }
            return .continueReflection(sessionID: sessionID, note: note)
        case "navigate_app":
            guard let rawSurface = values["surface"] as? String,
                  let surface = SoloraAppSurface(rawValue: rawSurface.lowercased()),
                  let userRequested = values["userRequested"] as? Bool else { return nil }
            return .navigate(surface: surface, userRequested: userRequested)
        case "request_creation_flow_confirmation":
            guard let rawKind = values["kind"] as? String,
                  let kind = SoloraAssistantCreationKind(rawValue: rawKind.lowercased()) else { return nil }
            return .requestCreationFlowConfirmation(kind: kind, target: values["target"] as? String)
        default:
            return nil
        }
    }

    static func outputJSON(for result: SoloraAssistantToolResult) -> String {
        let object: [String: Any]
        switch result {
        case .memorySummaries(let summaries):
            object = ["status": "ok", "memories": summaries.map(memoryObject)]
        case .memorySummary(let summary):
            object = ["status": "ok", "memory": memoryObject(summary)]
        case .draftPrepared(let draft):
            object = ["status": "draft_prepared", "draft_id": draft.id, "title": draft.title]
        case .confirmationRequired(let pending):
            object = ["status": "confirmation_required", "confirmation_id": pending.id, "action": pending.actionTitle]
        case .reflection(let reflection):
            object = ["status": "ok", "session_id": reflection.id, "prompt": reflection.prompt]
        case .navigationRequested(let surface):
            object = ["status": "ok", "surface": surface.rawValue]
        case .creationFlowConfirmationRequired(let pending):
            object = ["status": "confirmation_required", "confirmation_id": pending.id, "kind": pending.kind.rawValue]
        case .unavailable(let message):
            object = ["status": "unavailable", "message": message]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let json = String(data: data, encoding: .utf8) else { return #"{"status":"unavailable"}"# }
        return json
    }

    private static func enumValues(for tool: String, field: String) -> [String]? {
        switch (tool, field) {
        case ("navigate_app", "surface"): SoloraAppSurface.allCases.map(\.rawValue)
        case ("request_memory_change_confirmation", "change"): ["create", "update"]
        case ("request_creation_flow_confirmation", "kind"): SoloraAssistantCreationKind.allCases.map(\.rawValue)
        default: nil
        }
    }

    private static func memoryObject(_ summary: SoloraAssistantMemorySummary) -> [String: Any] {
        [
            "id": summary.id,
            "title": summary.title,
            "summary": summary.summary,
            "occurred_at": ISO8601DateFormatter().string(from: summary.occurredAt),
            "category": summary.category ?? NSNull(),
        ]
    }
}
