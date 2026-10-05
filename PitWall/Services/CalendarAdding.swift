import Foundation
import EventKit

/// Abstraction over the system calendar.
///
/// Access is requested only when the user taps an "Add to Calendar" action.
protocol CalendarAdding: Sendable {
    /// Requests write access if not determined. Returns whether calendar access is available.
    func requestAccess() async -> Bool

    /// Adds one calendar event per session. Returns the number of events created.
    func addSessions(_ sessions: [RaceSession],
                     race: Race,
                     localTimeZone: TimeZone) async throws -> Int
}

/// EventKit-backed implementation using write-only calendar access.
struct EventKitCalendarService: CalendarAdding {

    private let store: EKEventStore

    init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    func requestAccess() async -> Bool {
        (try? await store.requestWriteOnlyAccessToEvents()) ?? false
    }

    func addSessions(_ sessions: [RaceSession],
                     race: Race,
                     localTimeZone: TimeZone) async throws -> Int {
        guard await requestAccess() else { return 0 }

        var created = 0
        for session in sessions {
            let event = EKEvent(eventStore: store)
            event.title = "\(race.shortName) — \(session.type.displayName)"
            event.location = race.circuit.name
            event.startDate = session.startDate
            event.endDate = session.effectiveEndDate
            event.timeZone = TimeZone(identifier: "UTC")
            event.notes = "\(race.name) • Round \(race.round)\nAdded by PitWall."
            event.calendar = store.defaultCalendarForNewEvents
            try store.save(event, span: .thisEvent)
            created += 1
        }
        return created
    }
}

/// In-memory implementation for previews and tests.
final class MockCalendarService: CalendarAdding, @unchecked Sendable {
    private(set) var addedSessions: [RaceSession] = []
    private let shouldAuthorize: Bool

    init(shouldAuthorize: Bool = true) {
        self.shouldAuthorize = shouldAuthorize
    }

    func requestAccess() async -> Bool {
        shouldAuthorize
    }

    func addSessions(_ sessions: [RaceSession], race: Race, localTimeZone: TimeZone) async throws -> Int {
        addedSessions.append(contentsOf: sessions)
        return sessions.count
    }
}
