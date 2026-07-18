import XCTest
@testable import Solora

final class SoloraMomentTests: XCTestCase {
    func testMomentJSONRoundTrip() throws {
        let moment = SoloraMoment(
            id: "moment-1",
            title: "Closed a hard role",
            summary: "Turned ambiguity into a clear hire plan.",
            date: Date(timeIntervalSince1970: 1_720_000_000),
            world: .memoryShelves
        )

        let data = try JSONEncoder().encode(moment)
        XCTAssertEqual(try JSONDecoder().decode(SoloraMoment.self, from: data), moment)
    }

    func testUnknownWorldKindFallsBackToMemoryShelves() throws {
        let world = try JSONDecoder().decode(WorldKind.self, from: Data("\"future-world\"".utf8))
        XCTAssertEqual(world, .memoryShelves)
    }

    func testPostEventReflectionUsesTypedReflection() {
        let moment = DemoFixtures.postEventReflection(
            id: "saved-event",
            date: Date(timeIntervalSince1970: 1_720_172_800),
            reflection: "  I clarified the launch decision.  "
        )

        XCTAssertEqual(moment.id, "saved-event")
        XCTAssertEqual(moment.title, "Product strategy workshop")
        XCTAssertEqual(moment.summary, "I clarified the launch decision.")
    }

    func testPostEventReflectionUsesDefaultSummaryWhenBlank() {
        let moment = DemoFixtures.postEventReflection(id: "saved-event", date: .distantPast, reflection: " \n ")

        XCTAssertEqual(moment.summary, "Captured a post-event reflection and a useful next step.")
    }
}
