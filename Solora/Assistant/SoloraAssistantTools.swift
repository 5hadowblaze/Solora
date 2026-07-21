import Foundation

enum SoloraAppSurface: String, CaseIterable, Codable, Identifiable, Sendable {
    case now
    case lore
    case share
    case you

    var id: String { rawValue }

    var title: String {
        switch self {
        case .now: "Now"
        case .lore: "Lore"
        case .share: "Share"
        case .you: "You"
        }
    }
}

enum SoloraAssistantChildPresentation: String, Codable, Sendable {
    case reflection
    case memorySelection
    case talkingPoints
}

enum SoloraAssistantCreationKind: String, CaseIterable, Codable, Sendable {
    case story
    case post
    case cv
    case interview

    var title: String {
        switch self {
        case .story: "story"
        case .post: "post"
        case .cv: "CV"
        case .interview: "interview talking points"
        }
    }
}

struct SoloraAssistantPendingCreationFlow: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let kind: SoloraAssistantCreationKind
    let target: String?
}

struct SoloraAssistantMemorySummary: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let summary: String
    let occurredAt: Date
    let category: String?

    init(moment: SoloraMoment) {
        id = moment.id
        title = moment.title
        summary = moment.summary
        occurredAt = moment.date
        category = moment.category
    }
}

struct SoloraAssistantMemoryDraft: Codable, Equatable, Identifiable, Sendable {
    let id: String
    var title: String
    var summary: String
    var occurredAt: Date
    var category: String?

    var validationMessage: String? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.isEmpty || cleanTitle.count > 120 {
            return "Give this memory a title between 1 and 120 characters."
        }
        if cleanSummary.isEmpty || cleanSummary.count > 2_000 {
            return "Keep the memory summary between 1 and 2,000 characters."
        }
        if category?.count ?? 0 > 40 {
            return "Keep the memory category to 40 characters or fewer."
        }
        return nil
    }

    var isValid: Bool { validationMessage == nil }
}

enum SoloraAssistantMemoryChange: Codable, Equatable, Sendable {
    case create
    case update(memoryID: String)
}

struct SoloraAssistantPendingMemoryChange: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let draft: SoloraAssistantMemoryDraft
    let change: SoloraAssistantMemoryChange

    var actionTitle: String {
        switch change {
        case .create: "Create memory"
        case .update: "Update memory"
        }
    }
}

struct SoloraAssistantReflectionSession: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let context: String
    var prompt: String
    var notes: [String]
}

enum SoloraAssistantToolCall: Codable, Equatable, Sendable {
    case searchMemorySummaries(query: String, limit: Int)
    case readMemorySummary(memoryID: String)
    case openMemoryDetail(memoryID: String)
    case prepareMemoryDraft(title: String, summary: String, occurredAt: Date, category: String?)
    case requestMemoryChangeConfirmation(draftID: String, change: SoloraAssistantMemoryChange)
    case beginReflection(context: String)
    case continueReflection(sessionID: String, note: String)
    case navigate(surface: SoloraAppSurface, userRequested: Bool)
    case requestCreationFlowConfirmation(kind: SoloraAssistantCreationKind, target: String?)
}

enum SoloraAssistantToolResult: Equatable, Sendable {
    case memorySummaries([SoloraAssistantMemorySummary])
    case memorySummary(SoloraAssistantMemorySummary)
    case memoryOpened(SoloraAssistantMemorySummary)
    case draftPrepared(SoloraAssistantMemoryDraft)
    case confirmationRequired(SoloraAssistantPendingMemoryChange)
    case reflection(SoloraAssistantReflectionSession)
    case navigationRequested(SoloraAppSurface)
    case creationFlowConfirmationRequired(SoloraAssistantPendingCreationFlow)
    case unavailable(String)
}

struct SoloraAssistantToolField: Codable, Equatable, Sendable {
    enum ValueType: String, Codable, Sendable {
        case string
        case integer
        case boolean
        case date
        case enumeration
    }

    let name: String
    let type: ValueType
    let required: Bool
    let description: String
}

struct SoloraAssistantToolDescriptor: Codable, Equatable, Identifiable, Sendable {
    let name: String
    let description: String
    let fields: [SoloraAssistantToolField]
    let requiresUserConfirmation: Bool

    var id: String { name }
}

@MainActor
protocol SoloraAssistantToolRegistry: AnyObject {
    var descriptors: [SoloraAssistantToolDescriptor] { get }
    func replaceMemorySummaries(_ summaries: [SoloraAssistantMemorySummary])
    func execute(_ call: SoloraAssistantToolCall) -> SoloraAssistantToolResult
}

@MainActor
final class LocalSoloraAssistantToolRegistry: SoloraAssistantToolRegistry {
    let descriptors: [SoloraAssistantToolDescriptor] = [
        .init(
            name: "search_memory_summaries",
            description: "Search the user's local Solora career-memory summaries.",
            fields: [
                .init(name: "query", type: .string, required: true, description: "Career-related search text."),
                .init(name: "limit", type: .integer, required: true, description: "Maximum results, from 1 to 20.")
            ],
            requiresUserConfirmation: false
        ),
        .init(
            name: "read_memory_summary",
            description: "Read one local memory summary by its Solora identifier.",
            fields: [
                .init(name: "memoryID", type: .string, required: true, description: "An identifier returned by memory search.")
            ],
            requiresUserConfirmation: false
        ),
        .init(
            name: "open_memory_detail",
            description: "Open a specific memory in the user's Solora lore after they explicitly ask to see it. Use an identifier returned by memory search.",
            fields: [
                .init(name: "memoryID", type: .string, required: true, description: "An identifier returned by memory search.")
            ],
            requiresUserConfirmation: false
        ),
        .init(
            name: "prepare_memory_draft",
            description: "Prepare a local career-memory draft without saving it.",
            fields: [
                .init(name: "title", type: .string, required: true, description: "A concise factual title."),
                .init(name: "summary", type: .string, required: true, description: "Career evidence or reflection."),
                .init(name: "occurredAt", type: .date, required: true, description: "The date associated with the memory."),
                .init(name: "category", type: .string, required: false, description: "An optional career-memory category.")
            ],
            requiresUserConfirmation: false
        ),
        .init(
            name: "request_memory_change_confirmation",
            description: "Ask the user to review and confirm a prepared creation or update. This tool never writes by itself.",
            fields: [
                .init(name: "draftID", type: .string, required: true, description: "A draft identifier returned by prepare_memory_draft."),
                .init(name: "change", type: .enumeration, required: true, description: "Create, or update with an existing memory identifier."),
                .init(name: "memoryID", type: .string, required: false, description: "Required only for an update; use an identifier returned by memory search.")
            ],
            requiresUserConfirmation: true
        ),
        .init(
            name: "begin_reflection",
            description: "Begin a local reflection session for a user-provided event or thought.",
            fields: [
                .init(name: "context", type: .string, required: true, description: "Brief context supplied by the user or current app surface.")
            ],
            requiresUserConfirmation: false
        ),
        .init(
            name: "continue_reflection",
            description: "Add a user-provided note to an existing local reflection session.",
            fields: [
                .init(name: "sessionID", type: .string, required: true, description: "The active local reflection identifier."),
                .init(name: "note", type: .string, required: true, description: "Text explicitly supplied by the user.")
            ],
            requiresUserConfirmation: false
        ),
        .init(
            name: "navigate_app",
            description: "Navigate to a Solora surface only when the user requested it.",
            fields: [
                .init(name: "surface", type: .enumeration, required: true, description: "Now, Lore, Share, or You."),
                .init(name: "userRequested", type: .boolean, required: true, description: "Must be true for navigation to occur.")
            ],
            requiresUserConfirmation: false
        ),
        .init(
            name: "request_creation_flow_confirmation",
            description: "Ask the user to confirm before opening a Solora creation/share flow. This tool never creates or shares output by itself.",
            fields: [
                .init(name: "kind", type: .enumeration, required: true, description: "Story, post, CV, or interview talking points."),
                .init(name: "target", type: .string, required: false, description: "Optional role, audience, or occasion supplied by the user.")
            ],
            requiresUserConfirmation: true
        )
    ]

    private var memories: [SoloraAssistantMemorySummary] = []
    private var drafts: [String: SoloraAssistantMemoryDraft] = [:]
    private var reflections: [String: SoloraAssistantReflectionSession] = [:]

    func replaceMemorySummaries(_ summaries: [SoloraAssistantMemorySummary]) {
        memories = summaries.sorted { $0.occurredAt > $1.occurredAt }
    }

    func execute(_ call: SoloraAssistantToolCall) -> SoloraAssistantToolResult {
        switch call {
        case .searchMemorySummaries(let query, let limit):
            let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let safeLimit = min(20, max(1, limit))
            let matches = memories.filter { memory in
                cleanQuery.isEmpty
                    || memory.title.lowercased().contains(cleanQuery)
                    || memory.summary.lowercased().contains(cleanQuery)
                    || memory.category?.lowercased().contains(cleanQuery) == true
            }
            return .memorySummaries(Array(matches.prefix(safeLimit)))

        case .readMemorySummary(let memoryID):
            guard let memory = memories.first(where: { $0.id == memoryID }) else {
                return .unavailable("That memory is not available in the current local archive.")
            }
            return .memorySummary(memory)

        case .openMemoryDetail(let memoryID):
            guard let memory = memories.first(where: { $0.id == memoryID }) else {
                return .unavailable("That memory is not available in the current local archive.")
            }
            return .memoryOpened(memory)

        case .prepareMemoryDraft(let title, let summary, let occurredAt, let category):
            let draft = SoloraAssistantMemoryDraft(
                id: UUID().uuidString,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
                occurredAt: occurredAt,
                category: category?.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            guard let validationMessage = draft.validationMessage else {
                drafts[draft.id] = draft
                return .draftPrepared(draft)
            }
            return .unavailable(validationMessage)

        case .requestMemoryChangeConfirmation(let draftID, let change):
            guard let draft = drafts[draftID], draft.isValid else {
                return .unavailable("Prepare a valid memory draft before requesting confirmation.")
            }
            if case .update(let memoryID) = change,
               !memories.contains(where: { $0.id == memoryID }) {
                return .unavailable("The memory requested for update is not in the current local archive.")
            }
            return .confirmationRequired(.init(
                id: UUID().uuidString,
                draft: draft,
                change: change
            ))

        case .beginReflection(let context):
            let cleanContext = String(context.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500))
            guard !cleanContext.isEmpty else {
                return .unavailable("Add a little context before beginning a reflection.")
            }
            let session = SoloraAssistantReflectionSession(
                id: UUID().uuidString,
                context: cleanContext,
                prompt: "What changed because you were there?",
                notes: []
            )
            reflections[session.id] = session
            return .reflection(session)

        case .continueReflection(let sessionID, let note):
            guard var session = reflections[sessionID] else {
                return .unavailable("That reflection session is no longer available locally.")
            }
            let cleanNote = String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(2_000))
            guard !cleanNote.isEmpty else {
                return .unavailable("Add a thought before continuing the reflection.")
            }
            session.notes.append(cleanNote)
            session.prompt = Self.followUpPrompt(after: session.notes.count)
            reflections[session.id] = session
            return .reflection(session)

        case .navigate(let surface, let userRequested):
            guard userRequested else {
                return .unavailable("Solora only navigates when the user asks it to.")
            }
            return .navigationRequested(surface)

        case .requestCreationFlowConfirmation(let kind, let target):
            let cleanTarget = target?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(200)
            return .creationFlowConfirmationRequired(.init(
                id: UUID().uuidString,
                kind: kind,
                target: cleanTarget.map(String.init).flatMap { $0.isEmpty ? nil : $0 }
            ))
        }
    }

    private static func followUpPrompt(after noteCount: Int) -> String {
        switch noteCount {
        case 1: "What evidence or outcome would help future you remember why this mattered?"
        case 2: "Which strength did you use here?"
        default: "You have enough to keep this as a career memory."
        }
    }
}
