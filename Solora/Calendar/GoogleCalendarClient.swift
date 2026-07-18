import Foundation

struct CalendarEventPage: Sendable {
    let events: [CalendarEventCandidate]
    let nextPageToken: String?
}

enum GoogleCalendarClientError: LocalizedError, Equatable {
    case invalidResponse
    case permissionRequired
    case rateLimited
    case serviceUnavailable
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Google Calendar returned an unreadable response. Please try again."
        case .permissionRequired:
            "Calendar permission has expired or was revoked. Reconnect to continue."
        case .rateLimited:
            "Google Calendar is receiving too many requests. Please try again shortly."
        case .serviceUnavailable:
            "Google Calendar is temporarily unavailable. Please try again later."
        case .requestFailed:
            "Solora couldn't check your calendar. Check your connection and try again."
        }
    }
}

struct GoogleCalendarClient: Sendable {
    private static let maximumEvents = 250
    private static let excludedEventTypes: Set<String> = [
        "birthday", "workingLocation", "focusTime", "outOfOffice"
    ]

    func completedEvents(accessToken: String, now: Date = .now) async throws -> [CalendarEventCandidate] {
        let calendar = Calendar(identifier: .gregorian)
        guard let lowerBound = calendar.date(byAdding: .day, value: -30, to: now) else { return [] }

        var collected: [CalendarEventCandidate] = []
        var pageToken: String?

        repeat {
            let request = try request(
                accessToken: accessToken,
                lowerBound: lowerBound,
                now: now,
                pageToken: pageToken
            )
            let (data, response) = try await URLSession(configuration: .ephemeral).data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GoogleCalendarClientError.invalidResponse
            }
            try validate(httpResponse)

            let page = try Self.decodeCandidates(from: data, now: now, lowerBound: lowerBound)
            collected.append(contentsOf: page.events)
            pageToken = page.nextPageToken
        } while pageToken != nil && collected.count < Self.maximumEvents

        return Array(
            collected
                .sorted { $0.startDate > $1.startDate }
                .prefix(Self.maximumEvents)
        )
    }

    static func decodeCandidates(
        from data: Data,
        now: Date,
        lowerBound: Date
    ) throws -> CalendarEventPage {
        let response: EventsResponse
        do {
            response = try JSONDecoder().decode(EventsResponse.self, from: data)
        } catch {
            throw GoogleCalendarClientError.invalidResponse
        }

        let events = response.items.compactMap { item -> CalendarEventCandidate? in
            guard item.status != "cancelled",
                  !excludedEventTypes.contains(item.eventType ?? "default"),
                  !item.attendees.contains(where: { $0.selfAttendee && $0.responseStatus == "declined" }),
                  let start = parsedDate(item.start),
                  let end = parsedDate(item.end),
                  end.date <= now,
                  end.date >= lowerBound else {
                return nil
            }

            let title = item.summary?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty ?? "Untitled event"
            return CalendarEventCandidate(
                id: item.id,
                title: title,
                startDate: start.date,
                endDate: end.date,
                isAllDay: start.isAllDay
            )
        }

        return CalendarEventPage(events: events, nextPageToken: response.nextPageToken)
    }

    private func request(
        accessToken: String,
        lowerBound: Date,
        now: Date,
        pageToken: String?
    ) throws -> URLRequest {
        var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        var queryItems = [
            URLQueryItem(name: "timeMin", value: formatter.string(from: lowerBound)),
            URLQueryItem(name: "timeMax", value: formatter.string(from: now)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "showDeleted", value: "false"),
            URLQueryItem(name: "maxResults", value: "100"),
            URLQueryItem(
                name: "fields",
                value: "nextPageToken,items(id,status,summary,start(date,dateTime),end(date,dateTime),eventType,attendees(self,responseStatus))"
            )
        ]
        if let pageToken { queryItems.append(URLQueryItem(name: "pageToken", value: pageToken)) }
        components?.queryItems = queryItems
        guard let url = components?.url else { throw GoogleCalendarClientError.invalidResponse }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func validate(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200..<300:
            return
        case 401, 403:
            throw GoogleCalendarClientError.permissionRequired
        case 429:
            throw GoogleCalendarClientError.rateLimited
        case 500...599:
            throw GoogleCalendarClientError.serviceUnavailable
        default:
            throw GoogleCalendarClientError.requestFailed
        }
    }

    private static func parsedDate(_ value: EventDateTime) -> (date: Date, isAllDay: Bool)? {
        if let dateTime = value.dateTime {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let date = formatter.date(from: dateTime) ?? {
                formatter.formatOptions = [.withInternetDateTime]
                return formatter.date(from: dateTime)
            }()
            return date.map { ($0, false) }
        }

        guard let dateString = value.date else { return nil }
        let components = dateString.split(separator: "-").compactMap { Int($0) }
        guard components.count == 3 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let dateComponents = DateComponents(
            timeZone: .current,
            year: components[0],
            month: components[1],
            day: components[2]
        )
        return calendar.date(from: dateComponents).map { ($0, true) }
    }
}

private struct EventsResponse: Decodable {
    let items: [EventItem]
    let nextPageToken: String?

    private enum CodingKeys: String, CodingKey {
        case items
        case nextPageToken
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([EventItem].self, forKey: .items) ?? []
        nextPageToken = try container.decodeIfPresent(String.self, forKey: .nextPageToken)
    }
}

private struct EventItem: Decodable {
    let id: String
    let status: String?
    let summary: String?
    let start: EventDateTime
    let end: EventDateTime
    let eventType: String?
    let attendees: [EventAttendee]

    private enum CodingKeys: String, CodingKey {
        case id
        case status
        case summary
        case start
        case end
        case eventType
        case attendees
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        start = try container.decode(EventDateTime.self, forKey: .start)
        end = try container.decode(EventDateTime.self, forKey: .end)
        eventType = try container.decodeIfPresent(String.self, forKey: .eventType)
        attendees = try container.decodeIfPresent([EventAttendee].self, forKey: .attendees) ?? []
    }
}

private struct EventDateTime: Decodable {
    let date: String?
    let dateTime: String?
}

private struct EventAttendee: Decodable {
    let selfAttendee: Bool
    let responseStatus: String?

    private enum CodingKeys: String, CodingKey {
        case selfAttendee = "self"
        case responseStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selfAttendee = try container.decodeIfPresent(Bool.self, forKey: .selfAttendee) ?? false
        responseStatus = try container.decodeIfPresent(String.self, forKey: .responseStatus)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
