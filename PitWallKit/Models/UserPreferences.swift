import Foundation

/// User notification toggles for session types.
struct NotificationPreferences: Codable, Equatable, Sendable {
    var race: Bool
    var qualifying: Bool
    var sprint: Bool
    var practice: Bool
    /// Minutes before session start the reminder fires.
    var leadTimeMinutes: Int

    static let `default` = NotificationPreferences(
        race: true,
        qualifying: true,
        sprint: false,
        practice: false,
        leadTimeMinutes: 30
    )

    func isEnabled(for type: SessionType) -> Bool {
        switch type {
        case .practice1, .practice2, .practice3: return practice
        case .sprintQualifying, .sprint: return sprint
        case .qualifying: return qualifying
        case .race: return race
        }
    }
}

/// Locally persisted user preferences. The backend will mirror these
/// later; they are the single source of truth for the frontend.
struct UserPreferences: Codable, Equatable, Sendable {
    var hasCompletedOnboarding: Bool
    var favoriteDriverIDs: Set<String>
    var favoriteConstructorID: String?
    var notifications: NotificationPreferences
    var appearance: AppearanceMode

    static let initial = UserPreferences(
        hasCompletedOnboarding: false,
        favoriteDriverIDs: [],
        favoriteConstructorID: nil,
        notifications: .default,
        appearance: .dark
    )
}

enum AppearanceMode: String, Codable, CaseIterable, Sendable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

/// A scheduled session reminder, persisted so the UI can show reminder state
/// and so reminders can be cancelled across launches.
struct SessionReminder: Codable, Equatable, Identifiable, Sendable {
    let sessionID: String
    let raceID: String
    let sessionType: SessionType
    /// The date the reminder fires (session start minus lead time).
    let fireDate: Date

    var id: String { sessionID }
}
