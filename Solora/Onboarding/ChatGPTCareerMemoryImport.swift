import CryptoKit
import Foundation

enum CareerMemoryKind: String, CaseIterable, Identifiable, Sendable {
    case achievement
    case experience
    case skill
    case goal
    case role
    case education
    case preference

    var id: String { rawValue }

    var title: String {
        switch self {
        case .achievement: "Achievement"
        case .experience: "Experience"
        case .skill: "Skill"
        case .goal: "Goal"
        case .role: "Role"
        case .education: "Education"
        case .preference: "Work preference"
        }
    }
}

struct CareerMemoryDraft: Identifiable, Equatable, Sendable {
    let id: UUID
    var isIncluded: Bool
    var kind: CareerMemoryKind
    var title: String
    var summary: String
    var occurredOn: String

    init(
        id: UUID = UUID(),
        isIncluded: Bool = true,
        kind: CareerMemoryKind,
        title: String,
        summary: String,
        occurredOn: String
    ) {
        self.id = id
        self.isIncluded = isIncluded
        self.kind = kind
        self.title = title
        self.summary = summary
        self.occurredOn = occurredOn
    }

    var validationMessages: [String] {
        var messages: [String] = []
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanTitle.isEmpty {
            messages.append("Add a short title.")
        } else if cleanTitle.count > 120 {
            messages.append("Keep the title to 120 characters or fewer.")
        }

        if cleanSummary.isEmpty {
            messages.append("Add a factual career-memory summary.")
        } else if cleanSummary.count > 2_000 {
            messages.append("Keep the summary to 2,000 characters or fewer.")
        }

        if Self.date(from: occurredOn) == nil {
            messages.append("Use a real date in YYYY-MM-DD format.")
        }

        return messages
    }

    var isValid: Bool { validationMessages.isEmpty }

    func makeMoment() -> SoloraMoment? {
        guard let date = Self.date(from: occurredOn), isValid else { return nil }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanOccurredOn = occurredOn.trimmingCharacters(in: .whitespacesAndNewlines)
        return SoloraMoment(
            id: Self.momentID(kind: kind, title: cleanTitle, summary: cleanSummary, occurredOn: cleanOccurredOn),
            title: cleanTitle,
            summary: cleanSummary,
            date: date,
            world: .memoryShelves,
            category: kind.rawValue
        )
    }

    private static func momentID(
        kind: CareerMemoryKind,
        title: String,
        summary: String,
        occurredOn: String
    ) -> String {
        let canonicalMemory = [kind.rawValue, title, summary, occurredOn]
            .joined(separator: "\u{1f}")
        let digest = SHA256.hash(data: Data(canonicalMemory.utf8))
        return "chatgpt-" + digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func date(from value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 10 else { return nil }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false

        guard let date = formatter.date(from: trimmed), formatter.string(from: date) == trimmed else {
            return nil
        }
        return date
    }
}

struct CareerMemoryImportParseResult: Equatable, Sendable {
    let drafts: [CareerMemoryDraft]
    let notices: [String]
}

enum ChatGPTCareerMemoryImport {
    static let schema = "solora.career-memory-import"
    static let version = 1
    static let maximumPasteLength = 200_000
    static let maximumMemoryCount = 50

    static let prompt = """
    I am building my private career-memory archive in Solora. Help me hand over only useful career information that I have already shared with you or that is present in your saved memory about me.

    Include concrete achievements, work or project experiences, demonstrated skills, career goals, roles, education, and genuine work preferences. Do not infer missing facts. Do not include unrelated personal details, passwords, authentication details, financial information, health information, exact home addresses, private messages, or information about other people that is not necessary to understand my work.

    Return valid JSON only, with no Markdown fence or commentary. Use this exact versioned structure:

    {
      "schema": "solora.career-memory-import",
      "version": 1,
      "memories": [
        {
          "kind": "achievement",
          "title": "A concise, specific title",
          "summary": "One or two factual sentences describing what happened, my contribution, and the useful evidence or outcome.",
          "occurredOn": "YYYY-MM-DD"
        }
      ]
    }

    Rules:
    - Return no more than 20 memories. Return fewer when the evidence is limited.
    - kind must be one of: achievement, experience, skill, goal, role, education, preference.
    - title must be 120 characters or fewer.
    - summary must be 2,000 characters or fewer and should avoid hype or invented metrics.
    - occurredOn must be the best supported date in YYYY-MM-DD format. Use null if you cannot support a date; I will add it during review in Solora.
    - Keep distinct evidence as distinct memories and do not duplicate the same event.
    """

    static func parse(_ pastedText: String) throws -> CareerMemoryImportParseResult {
        let trimmed = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CareerMemoryImportError.emptyPaste }
        guard trimmed.count <= maximumPasteLength else { throw CareerMemoryImportError.pasteTooLarge }

        guard let openBrace = trimmed.firstIndex(of: "{"),
              let closeBrace = trimmed.lastIndex(of: "}"),
              openBrace <= closeBrace else {
            throw CareerMemoryImportError.missingJSONObject
        }

        let jsonText = String(trimmed[openBrace...closeBrace])
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: Data(jsonText.utf8))
        } catch {
            throw CareerMemoryImportError.invalidJSON
        }

        guard let envelope = object as? [String: Any] else {
            throw CareerMemoryImportError.invalidEnvelope
        }
        guard envelope["schema"] as? String == schema else {
            throw CareerMemoryImportError.unsupportedSchema
        }
        guard let parsedVersion = envelope["version"] as? NSNumber,
              parsedVersion.intValue == version,
              parsedVersion.doubleValue == Double(version) else {
            throw CareerMemoryImportError.unsupportedVersion
        }
        guard let rawMemories = envelope["memories"] as? [Any], !rawMemories.isEmpty else {
            throw CareerMemoryImportError.noMemories
        }
        guard rawMemories.count <= maximumMemoryCount else {
            throw CareerMemoryImportError.tooManyMemories(maximumMemoryCount)
        }

        var drafts: [CareerMemoryDraft] = []
        var notices: [String] = []

        for (index, rawMemory) in rawMemories.enumerated() {
            guard let memory = rawMemory as? [String: Any] else {
                notices.append("Memory \(index + 1) was skipped because it was not an object.")
                continue
            }

            let rawKind = stringValue(memory["kind"])
            let kind: CareerMemoryKind
            if let parsedKind = rawKind.flatMap(CareerMemoryKind.init(rawValue:)) {
                kind = parsedKind
            } else {
                kind = .experience
                notices.append("Memory \(index + 1) had an unknown kind, so it is marked as Experience for review.")
            }

            let title = stringValue(memory["title"]) ?? ""
            let summary = stringValue(memory["summary"]) ?? ""
            let occurredOn = stringValue(memory["occurredOn"]) ?? ""

            drafts.append(CareerMemoryDraft(
                kind: kind,
                title: title,
                summary: summary,
                occurredOn: occurredOn
            ))
        }

        guard !drafts.isEmpty else { throw CareerMemoryImportError.noUsableMemories }

        let duplicateCount = drafts.count - Set(drafts.map {
            "\($0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())|\($0.occurredOn)"
        }).count
        if duplicateCount > 0 {
            notices.append("Review \(duplicateCount) possible duplicate \(duplicateCount == 1 ? "memory" : "memories") before saving.")
        }
        if drafts.count > 20 {
            notices.append("ChatGPT returned more than the requested 20 memories. Remove anything that is not useful before saving.")
        }

        return CareerMemoryImportParseResult(drafts: drafts, notices: notices)
    }

    static func save(_ moments: [SoloraMoment], userID: String) throws {
        guard userID != AuthenticatedUser.demo.id else {
            throw CareerMemoryImportError.authenticationRequired
        }
        guard !moments.isEmpty else { throw CareerMemoryImportError.noSelectedMemories }

        for moment in moments {
            try FirebaseMomentRepository.validate(moment)
        }
        for moment in moments {
            try FirebaseMomentRepository.saveMoment(moment, userID: userID) { _ in }
        }
    }

    private static func stringValue(_ value: Any?) -> String? {
        guard let value = value as? String else { return nil }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum CareerMemoryImportError: LocalizedError, Equatable {
    case emptyPaste
    case pasteTooLarge
    case missingJSONObject
    case invalidJSON
    case invalidEnvelope
    case unsupportedSchema
    case unsupportedVersion
    case noMemories
    case tooManyMemories(Int)
    case noUsableMemories
    case noSelectedMemories
    case authenticationRequired

    var errorDescription: String? {
        switch self {
        case .emptyPaste:
            "Paste ChatGPT's JSON response first."
        case .pasteTooLarge:
            "That response is too large to review safely. Ask ChatGPT for 20 career memories or fewer."
        case .missingJSONObject, .invalidJSON:
            "Solora could not read valid JSON. Paste the complete response, or ask ChatGPT to return JSON only."
        case .invalidEnvelope, .unsupportedSchema:
            "This is not a Solora career-memory response. Copy the prompt again and retry in ChatGPT."
        case .unsupportedVersion:
            "This response uses a different schema version. Copy Solora's current prompt and try again."
        case .noMemories:
            "The response contains no career memories to review."
        case .tooManyMemories(let maximum):
            "The response contains too many memories. Ask ChatGPT for \(maximum) or fewer."
        case .noUsableMemories:
            "The response did not contain any editable memory objects."
        case .noSelectedMemories:
            "Choose at least one valid memory to save."
        case .authenticationRequired:
            "Sign in with Google before saving memories to your private lore."
        }
    }
}
