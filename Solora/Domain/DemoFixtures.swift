import Foundation

enum DemoFixtures {
    static let moments = [
        SoloraMoment(id: "clarity", title: "Found clarity in a tough brief", summary: "Framed the work, aligned the room, and set a confident next move.", date: Date(timeIntervalSince1970: 1_720_000_000), world: .memoryShelves),
        SoloraMoment(id: "momentum", title: "Made the first move", summary: "Reached out with a thoughtful note and opened a useful new conversation.", date: Date(timeIntervalSince1970: 1_720_086_400), world: .memoryShelves),
        SoloraMoment(id: "room", title: "Aligned the room", summary: "Turned scattered feedback into one decision the whole team could support.", date: Date(timeIntervalSince1970: 1_720_172_800), world: .memoryShelves),
        SoloraMoment(id: "bridge", title: "Built the bridge", summary: "Connected two student groups and found the shared outcome behind the work.", date: Date(timeIntervalSince1970: 1_720_259_200), world: .memoryShelves),
        SoloraMoment(id: "brief", title: "Shipped the brief", summary: "Made a complex product idea simple enough for design and engineering to act on.", date: Date(timeIntervalSince1970: 1_720_345_600), world: .memoryShelves)
    ]

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
