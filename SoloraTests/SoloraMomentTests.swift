import XCTest
@testable import Solora

final class SoloraMomentTests: XCTestCase {
    func testOnboardingCompletionPersistsUntilTheUserSignsOut() {
        let user = AuthenticatedUser(id: "person-1", displayName: "Amir", email: nil, photoURL: nil)
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        defer { defaults.removePersistentDomain(forName: #function) }

        var onboarding = OnboardingSessionState(defaults: defaults)

        XCTAssertTrue(onboarding.requiresOnboarding(for: user.id))

        onboarding.complete(for: user.id)
        XCTAssertFalse(onboarding.requiresOnboarding(for: user.id))

        let restoredOnboarding = OnboardingSessionState(defaults: defaults)
        XCTAssertFalse(restoredOnboarding.requiresOnboarding(for: user.id))

        onboarding.authenticationDidSignOut(for: user.id)
        XCTAssertTrue(onboarding.requiresOnboarding(for: user.id))
    }

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

    func testAuthenticatedUserDerivesFirstNameAndInitials() {
        let user = AuthenticatedUser(
            id: "person-1",
            displayName: "Amir Dzakwan",
            email: "amir@example.com",
            photoURL: nil
        )

        XCTAssertEqual(user.firstName, "Amir")
        XCTAssertEqual(user.initials, "AD")
    }

    func testCareerFridgeDocumentMapsToSoloraMoment() throws {
        let date = Date(timeIntervalSince1970: 1_750_000_000)
        let moment = try XCTUnwrap(FirebaseMomentRepository.moment(
            documentID: "win-1",
            data: [
                "title": "Won Hackathon Competition!",
                "caption": "Hackathon win, great success!",
                "category": "hackathon",
                "occurredAt": date,
                "stickerPath": "stickers/user/win-1.png",
                "photoPaths": ["win-photos/user/win-1-0.jpg"]
            ]
        ))

        XCTAssertEqual(moment.id, "win-1")
        XCTAssertEqual(moment.title, "Won Hackathon Competition!")
        XCTAssertEqual(moment.summary, "Hackathon win, great success!")
        XCTAssertEqual(moment.date, date)
        XCTAssertEqual(moment.category, "hackathon")
        XCTAssertEqual(moment.stickerPath, "stickers/user/win-1.png")
        XCTAssertEqual(moment.photoPaths, ["win-photos/user/win-1-0.jpg"])
    }

    func testMomentDecodesOlderPayloadWithoutMediaFields() throws {
        let data = Data(#"{"id":"legacy","title":"A win","summary":"Kept moving.","date":0,"world":"memoryShelves"}"#.utf8)
        let moment = try JSONDecoder().decode(SoloraMoment.self, from: data)

        XCTAssertNil(moment.category)
        XCTAssertNil(moment.stickerPath)
        XCTAssertEqual(moment.photoPaths, [])
    }

    func testMomentValidationRejectsOversizedReflection() {
        let moment = SoloraMoment(
            id: "moment-1",
            title: "A useful workshop",
            summary: String(repeating: "a", count: 2_001),
            date: .now,
            world: .memoryShelves
        )

        XCTAssertThrowsError(try FirebaseMomentRepository.validate(moment))
    }

    func testMasterCVDocumentMapsFormattingProfile() throws {
        let master = try XCTUnwrap(FirebaseCVRepository.master(
            documentID: "master-extended-cv",
            data: [
                "title": "Dzakwan Dzulzalani Extended CV",
                "version": 1,
                "contentMarkdown": "**EXPERIENCE**",
                "structuredEntryCount": 68,
                "formatProfile": [
                    "languageVariant": "British English",
                    "voice": "Achievement-focused",
                    "dateStyle": "Month YYYY – Month YYYY",
                    "sourceTypeface": "Garamond",
                    "sourcePageCount": 10
                ]
            ]
        ))

        XCTAssertEqual(master.structuredEntryCount, 68)
        XCTAssertEqual(master.formatProfile.languageVariant, "British English")
        XCTAssertEqual(master.formatProfile.sourceTypeface, "Garamond")
        XCTAssertEqual(master.formatProfile.sourcePageCount, 10)
    }
}
