import CryptoKit
import Foundation

struct CalendarEventCandidate: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
}

enum CalendarMemoryMapper {
    static func moment(
        from event: CalendarEventCandidate,
        reflection: String,
        userID: String
    ) -> SoloraMoment? {
        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReflection.isEmpty else { return nil }

        let title = String(event.title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
        let summary = String(trimmedReflection.prefix(2_000))
        let source = "\(userID)\u{0}\(event.id)\u{0}\(event.startDate.timeIntervalSince1970)"
        let digest = SHA256.hash(data: Data(source.utf8))
            .map { String(format: "%02x", $0) }
            .joined()

        return SoloraMoment(
            id: "calendar-\(digest)",
            title: title.isEmpty ? "Calendar reflection" : title,
            summary: summary,
            date: event.startDate,
            world: .memoryShelves,
            category: "calendar"
        )
    }
}
