import Foundation
import UserNotifications

/// Abstraction over the system notification center.
///
/// Permission is requested lazily — never on app launch — only when the user
/// schedules a reminder or opts in during onboarding.
protocol NotificationScheduling: Sendable {
    /// Requests authorization if not determined. Returns whether notifications are allowed.
    func requestAuthorization() async -> Bool

    /// Current authorization status without prompting.
    func authorizationStatus() async -> UNAuthorizationStatus

    /// Schedules a reminder to fire at its stored `fireDate`.
    func schedule(reminder: SessionReminder,
                  raceName: String,
                  circuitName: String) async throws

    /// Cancels scheduled reminders with the given identifiers.
    func cancel(reminderIDs: [String]) async
}

/// UserNotifications-backed implementation.
struct UserNotificationService: NotificationScheduling {

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func schedule(reminder: SessionReminder,
                  raceName: String,
                  circuitName: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "\(raceName) — \(reminder.sessionType.displayName)"
        content.body = Self.body(for: reminder, circuitName: circuitName)
        content.sound = .default

        let components = PitWallDate.localDateComponents(for: reminder.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)

        try await center.add(request)
    }

    func cancel(reminderIDs: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: reminderIDs)
    }

    private static func body(for reminder: SessionReminder, circuitName: String) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .full
        let lead = formatter.string(from: reminder.fireDate.timeIntervalSinceNow.magnitude) ?? "soon"
        return "\(reminder.sessionType.displayName) at \(circuitName) starts in \(lead)."
    }
}

/// In-memory implementation for previews and tests.
final class MockNotificationService: NotificationScheduling, @unchecked Sendable {
    private(set) var scheduled: [SessionReminder] = []
    private(set) var cancelledIDs: [String] = []
    private let shouldAuthorize: Bool

    init(shouldAuthorize: Bool = true) {
        self.shouldAuthorize = shouldAuthorize
    }

    func requestAuthorization() async -> Bool {
        shouldAuthorize
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        shouldAuthorize ? .authorized : .denied
    }

    func schedule(reminder: SessionReminder, raceName: String, circuitName: String) async throws {
        scheduled.append(reminder)
    }

    func cancel(reminderIDs: [String]) async {
        cancelledIDs.append(contentsOf: reminderIDs)
        scheduled.removeAll { reminderIDs.contains($0.id) }
    }
}
