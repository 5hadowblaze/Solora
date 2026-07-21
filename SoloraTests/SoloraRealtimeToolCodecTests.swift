import Foundation
import Testing
@testable import Solora

@MainActor
struct SoloraRealtimeToolCodecTests {
    @Test func decodesOfficialFunctionArgumentsDoneEvent() {
        let event: [String: Any] = [
            "type": "response.function_call_arguments.done",
            "call_id": "call_123",
            "name": "navigate_app",
            "arguments": #"{"surface":"share","userRequested":true}"#,
        ]

        let functionCall = SoloraRealtimeToolCodec.functionCall(from: event)
        #expect(functionCall == .init(
            callID: "call_123",
            name: "navigate_app",
            arguments: #"{"surface":"share","userRequested":true}"#
        ))
        #expect(SoloraRealtimeToolCodec.decodeToolCall(
            name: functionCall?.name ?? "",
            arguments: functionCall?.arguments ?? ""
        ) == .navigate(surface: .share, userRequested: true))
    }

    @Test func creationToolRequiresAnAppConfirmation() {
        let registry = LocalSoloraAssistantToolRegistry()
        let result = registry.execute(.requestCreationFlowConfirmation(kind: .post, target: "Portfolio review"))

        guard case .creationFlowConfirmationRequired(let pending) = result else {
            Issue.record("Expected a creation confirmation")
            return
        }
        #expect(pending.kind == .post)
        #expect(pending.target == "Portfolio review")
    }

    @Test func decodesMemoryOpenTool() {
        #expect(SoloraRealtimeToolCodec.decodeToolCall(
            name: "open_memory_detail",
            arguments: #"{"memoryID":"clarity"}"#
        ) == .openMemoryDetail(memoryID: "clarity"))
    }

    @Test func memoryWriteToolOnlyReturnsPendingConfirmation() {
        let registry = LocalSoloraAssistantToolRegistry()
        let prepared = registry.execute(.prepareMemoryDraft(
            title: "Shipped launch",
            summary: "Coordinated the launch and measured adoption.",
            occurredAt: .now,
            category: "Delivery"
        ))
        guard case .draftPrepared(let draft) = prepared else {
            Issue.record("Expected a prepared draft")
            return
        }

        let result = registry.execute(.requestMemoryChangeConfirmation(draftID: draft.id, change: .create))
        guard case .confirmationRequired(let pending) = result else {
            Issue.record("Expected a memory confirmation")
            return
        }
        #expect(pending.draft.id == draft.id)
    }
}
