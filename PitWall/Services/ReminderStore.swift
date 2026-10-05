import Foundation

/// Persists scheduled session reminders so screens can show reminder state
/// and reminders survive relaunches.
@MainActor
@Observable
final class ReminderStore {

    private(set) var reminders: [SessionReminder] = []

    private let defaults: UserDefaults
    private let storageKey = "pw.sessionReminders"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SessionReminder].self, from: data) {
            reminders = decoded
        }
    }

    func isReminderSet(forSessionID sessionID: String) -> Bool {
        reminders.contains { $0.id == sessionID }
    }

    func reminder(forSessionID sessionID: String) -> SessionReminder? {
        reminders.first { $0.id == sessionID }
    }

    func setReminder(_ reminder: SessionReminder) {
        reminders.removeAll { $0.id == reminder.id }
        reminders.append(reminder)
        persist()
    }

    func removeReminder(forSessionID sessionID: String) {
        reminders.removeAll { $0.id == sessionID }
        persist()
    }

    /// Reminder identifiers that belong to a race weekend (any session).
    func reminderIDs(forRaceID raceID: String) -> [String] {
        reminders.filter { $0.raceID == raceID }.map { $0.id }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(reminders) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
