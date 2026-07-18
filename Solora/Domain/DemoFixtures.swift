import Foundation

enum DemoFixtures {
    static let moments = [
        SoloraMoment(id: "clarity", title: "Found clarity in a tough brief", summary: "Framed the work, aligned the room, and set a confident next move.", date: Date(timeIntervalSince1970: 1_720_000_000), world: .memoryShelves),
        SoloraMoment(id: "momentum", title: "Made the first move", summary: "Reached out with a thoughtful note and opened a useful new conversation.", date: Date(timeIntervalSince1970: 1_720_086_400), world: .memoryShelves)
    ]

    static let memoryShelvesManifest = WorldManifest(
        kind: .memoryShelves,
        title: "Memory Shelves",
        subtitle: "The evidence that makes up your lore.",
        shelves: ["Wins", "People", "Craft"]
    )

    static func postEventReflection(id: String, date: Date, reflection: String) -> SoloraMoment {
        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        return SoloraMoment(
            id: id,
            title: "Product strategy workshop",
            summary: trimmedReflection.isEmpty
                ? "Captured a post-event reflection and a useful next step."
                : trimmedReflection,
            date: date,
            world: .memoryShelves
        )
    }
}
