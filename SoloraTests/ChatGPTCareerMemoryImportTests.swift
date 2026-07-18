import XCTest
@testable import Solora

final class ChatGPTCareerMemoryImportTests: XCTestCase {
    func testParsesVersionedResponseInsideMarkdownFence() throws {
        let response = """
        Here is the requested response:
        ```json
        {
          "schema": "solora.career-memory-import",
          "version": 1,
          "memories": [
            {
              "kind": "achievement",
              "title": "Led the launch decision",
              "summary": "Aligned product and engineering around a clear launch plan.",
              "occurredOn": "2026-06-18"
            }
          ]
        }
        ```
        """

        let result = try ChatGPTCareerMemoryImport.parse(response)

        XCTAssertEqual(result.drafts.count, 1)
        XCTAssertEqual(result.drafts[0].kind, .achievement)
        XCTAssertEqual(result.drafts[0].title, "Led the launch decision")
        XCTAssertTrue(result.drafts[0].isValid)
        XCTAssertEqual(result.drafts[0].makeMoment()?.category, "achievement")
    }

    func testMissingDateRemainsEditableAndCannotBeSavedYet() throws {
        let response = #"{"schema":"solora.career-memory-import","version":1,"memories":[{"kind":"goal","title":"Move into product leadership","summary":"Build on cross-functional delivery experience.","occurredOn":null}]}"#

        let result = try ChatGPTCareerMemoryImport.parse(response)

        XCTAssertEqual(result.drafts[0].occurredOn, "")
        XCTAssertFalse(result.drafts[0].isValid)
        XCTAssertNil(result.drafts[0].makeMoment())
        XCTAssertTrue(result.drafts[0].validationMessages.contains("Use a real date in YYYY-MM-DD format."))
    }

    func testRepeatedApprovedMemoryUsesSameFirestoreDocumentID() throws {
        let draft = CareerMemoryDraft(
            kind: .achievement,
            title: "Led the launch decision",
            summary: "Aligned product and engineering around a clear launch plan.",
            occurredOn: "2026-06-18"
        )

        let first = try XCTUnwrap(draft.makeMoment())
        let repeated = try XCTUnwrap(draft.makeMoment())

        XCTAssertEqual(first.id, repeated.id)
        XCTAssertTrue(first.id.hasPrefix("chatgpt-"))
    }

    func testUnknownKindIsKeptForReviewAsExperience() throws {
        let response = #"{"schema":"solora.career-memory-import","version":1,"memories":[{"kind":"award","title":"Won a team award","summary":"Recognised for improving the release process.","occurredOn":"2026-06-18"}]}"#

        let result = try ChatGPTCareerMemoryImport.parse(response)

        XCTAssertEqual(result.drafts[0].kind, .experience)
        XCTAssertTrue(result.notices.contains { $0.contains("unknown kind") })
    }

    func testRejectsUnsupportedSchemaVersion() {
        let response = #"{"schema":"solora.career-memory-import","version":2,"memories":[{}]}"#

        XCTAssertThrowsError(try ChatGPTCareerMemoryImport.parse(response)) { error in
            XCTAssertEqual(error as? CareerMemoryImportError, .unsupportedVersion)
        }
    }

    func testInvalidFieldsReachReviewInsteadOfBeingPersisted() throws {
        let response = #"{"schema":"solora.career-memory-import","version":1,"memories":[{"kind":"skill","title":42,"summary":"","occurredOn":"not-a-date"}]}"#

        let result = try ChatGPTCareerMemoryImport.parse(response)

        XCTAssertEqual(result.drafts.count, 1)
        XCTAssertFalse(result.drafts[0].isValid)
        XCTAssertEqual(result.drafts[0].validationMessages.count, 3)
    }
}
