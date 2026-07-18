import XCTest
@testable import Solora

final class CalendarIntegrationTests: XCTestCase {
    func testCalendarDecoderKeepsOnlyEligibleCompletedEvents() throws {
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-07-18T12:00:00Z"))
        let lowerBound = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-06-18T12:00:00Z"))
        let payload = Data(#"""
        {
          "items": [
            {"id":"keep","status":"confirmed","summary":"Product review","eventType":"default","start":{"dateTime":"2026-07-18T09:00:00Z"},"end":{"dateTime":"2026-07-18T10:00:00Z"}},
            {"id":"future","status":"confirmed","summary":"Still running","eventType":"default","start":{"dateTime":"2026-07-18T11:00:00Z"},"end":{"dateTime":"2026-07-18T13:00:00Z"}},
            {"id":"cancelled","status":"cancelled","summary":"Cancelled","eventType":"default","start":{"dateTime":"2026-07-17T09:00:00Z"},"end":{"dateTime":"2026-07-17T10:00:00Z"}},
            {"id":"focus","status":"confirmed","summary":"Focus","eventType":"focusTime","start":{"dateTime":"2026-07-17T09:00:00Z"},"end":{"dateTime":"2026-07-17T10:00:00Z"}},
            {"id":"declined","status":"confirmed","summary":"Declined","eventType":"default","start":{"dateTime":"2026-07-17T09:00:00Z"},"end":{"dateTime":"2026-07-17T10:00:00Z"},"attendees":[{"self":true,"responseStatus":"declined"}]}
          ]
        }
        """#.utf8)

        let page = try GoogleCalendarClient.decodeCandidates(
            from: payload,
            now: now,
            lowerBound: lowerBound
        )

        XCTAssertEqual(page.events.map(\.id), ["keep"])
        XCTAssertEqual(page.events.first?.title, "Product review")
    }

    func testReviewedCalendarEventMapsToCompatibleMoment() throws {
        let event = CalendarEventCandidate(
            id: "google-event-id",
            title: "Product strategy workshop",
            startDate: Date(timeIntervalSince1970: 1_752_835_200),
            endDate: Date(timeIntervalSince1970: 1_752_838_800),
            isAllDay: false
        )

        let moment = try XCTUnwrap(CalendarMemoryMapper.moment(
            from: event,
            reflection: "  I clarified the launch decision.  ",
            userID: "user-1"
        ))

        XCTAssertTrue(moment.id.hasPrefix("calendar-"))
        XCTAssertEqual(moment.title, event.title)
        XCTAssertEqual(moment.summary, "I clarified the launch decision.")
        XCTAssertEqual(moment.date, event.startDate)
        XCTAssertEqual(moment.category, "calendar")
        XCTAssertNil(moment.stickerPath)
        XCTAssertEqual(moment.photoPaths, [])
    }

    func testBlankCalendarReflectionDoesNotCreateMoment() {
        let event = CalendarEventCandidate(
            id: "event",
            title: "Workshop",
            startDate: .now,
            endDate: .now,
            isAllDay: false
        )

        XCTAssertNil(CalendarMemoryMapper.moment(
            from: event,
            reflection: "  \n ",
            userID: "user-1"
        ))
    }
}
