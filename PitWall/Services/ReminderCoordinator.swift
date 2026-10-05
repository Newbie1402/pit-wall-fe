import Foundation
import Observation

/// Result of a reminder toggle, letting screens surface denial alerts.
enum ReminderOutcome: Equatable {
    case scheduled
    case removed
    case denied
}

/// Coordinates scheduling and cancelling session reminders across screens.
///
/// Permission is requested only when the user actively sets a reminder.
@MainActor
final class ReminderCoordinator {

    private let notifications: any NotificationScheduling
    private let reminders: ReminderStore
    private let preferences: UserPreferencesStore

    init(notifications: any NotificationScheduling,
         reminders: ReminderStore,
         preferences: UserPreferencesStore) {
        self.notifications = notifications
        self.reminders = reminders
        self.preferences = preferences
    }

    func isReminderSet(for session: RaceSession) -> Bool {
        reminders.isReminderSet(forSessionID: session.id)
    }

    func toggleReminder(race: Race, session: RaceSession) async -> ReminderOutcome {
        if isReminderSet(for: session) {
            await notifications.cancel(reminderIDs: [session.id])
            reminders.removeReminder(forSessionID: session.id)
            return .removed
        }

        let status = await notifications.authorizationStatus()
        if status == .denied {
            return .denied
        }
        if status == .notDetermined {
            let granted = await notifications.requestAuthorization()
            if !granted {
                return .denied
            }
        }

        let leadSeconds = TimeInterval(preferences.notifications.leadTimeMinutes * 60)
        var fireDate = session.startDate.addingTimeInterval(-leadSeconds)
        if fireDate <= Date() {
            fireDate = session.startDate
        }

        let reminder = SessionReminder(
            sessionID: session.id,
            raceID: race.id,
            sessionType: session.type,
            fireDate: fireDate
        )
        do {
            try await notifications.schedule(reminder: reminder,
                                             raceName: race.name,
                                             circuitName: race.circuit.name)
        } catch {
            return .denied
        }
        reminders.setReminder(reminder)
        return .scheduled
    }
}
