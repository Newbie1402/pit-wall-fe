import Foundation
import Observation

/// Dependency container injected into the view tree via `.environment`.
///
/// Views see protocols only — they cannot tell mock repositories from the
/// future remote implementations.
@MainActor
@Observable
final class AppEnvironment {

    let raceRepository: any RaceRepository
    let driverRepository: any DriverRepository
    let constructorRepository: any ConstructorRepository
    let standingsRepository: any StandingsRepository
    let feedRepository: any FeedRepository

    let preferences: UserPreferencesStore
    let notifications: any NotificationScheduling
    let calendar: any CalendarAdding
    let reminders: ReminderStore

    /// Shared reminder scheduling logic used by Home and Race Detail.
    private(set) lazy var reminderCoordinator = ReminderCoordinator(
        notifications: notifications,
        reminders: reminders,
        preferences: preferences
    )

    init(raceRepository: any RaceRepository,
         driverRepository: any DriverRepository,
         constructorRepository: any ConstructorRepository,
         standingsRepository: any StandingsRepository,
         feedRepository: any FeedRepository,
         preferences: UserPreferencesStore,
         notifications: any NotificationScheduling,
         calendar: any CalendarAdding,
         reminders: ReminderStore) {
        self.raceRepository = raceRepository
        self.driverRepository = driverRepository
        self.constructorRepository = constructorRepository
        self.standingsRepository = standingsRepository
        self.feedRepository = feedRepository
        self.preferences = preferences
        self.notifications = notifications
        self.calendar = calendar
        self.reminders = reminders
    }

    /// Production wiring for this stage: mock repositories backed by local
    /// data. Backend integration swaps the repositories here — and nowhere else.
    static func live() -> AppEnvironment {
        AppEnvironment(
            raceRepository: MockRaceRepository(),
            driverRepository: MockDriverRepository(),
            constructorRepository: MockConstructorRepository(),
            standingsRepository: MockStandingsRepository(),
            feedRepository: MockFeedRepository(),
            preferences: UserPreferencesStore(),
            notifications: UserNotificationService(),
            calendar: EventKitCalendarService(),
            reminders: ReminderStore()
        )
    }

    /// Preview wiring: instant mocks, no permission dialogs, seeded favorites.
    static func preview(preferences: UserPreferencesStore? = nil) -> AppEnvironment {
        let store = preferences ?? {
            let fresh = UserPreferencesStore(defaults: UserDefaults(suiteName: "preview-\(UUID().uuidString)"))
            fresh.favoriteDriverIDs = ["norris", "verstappen"]
            fresh.favoriteConstructorID = "mclaren"
            fresh.hasCompletedOnboarding = true
            return fresh
        }()

        return AppEnvironment(
            raceRepository: MockRaceRepository(),
            driverRepository: MockDriverRepository(),
            constructorRepository: MockConstructorRepository(),
            standingsRepository: MockStandingsRepository(),
            feedRepository: MockFeedRepository(),
            preferences: store,
            notifications: MockNotificationService(),
            calendar: MockCalendarService(),
            reminders: ReminderStore()
        )
    }
}
