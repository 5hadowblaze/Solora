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
}
