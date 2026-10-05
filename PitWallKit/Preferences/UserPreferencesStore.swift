import Foundation
import Observation

/// Locally persisted user preferences.
///
/// Backed by the shared app-group defaults so the widget extension reads the
/// same favorites and notification settings as the app. Falls back to standard
/// defaults when the group is unavailable (e.g. unsigned local runs).
@MainActor
@Observable
final class UserPreferencesStore {

    static let appGroupID = "group.com.pitwallapp.shared"

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.onboardingComplete) }
    }

    var favoriteDriverIDs: Set<String> {
        didSet { defaults.set(Array(favoriteDriverIDs).sorted(), forKey: Keys.favoriteDrivers) }
    }

    var favoriteConstructorID: String? {
        didSet { defaults.set(favoriteConstructorID, forKey: Keys.favoriteConstructor) }
    }

    var notifications: NotificationPreferences {
        didSet {
            if let data = try? JSONEncoder().encode(notifications) {
                defaults.set(data, forKey: Keys.notifications)
            }
        }
    }

    var appearance: AppearanceMode {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    /// Race weekends the user follows (shows follow state on Race Detail).
    var followedRaceIDs: Set<String> {
        didSet { defaults.set(Array(followedRaceIDs).sorted(), forKey: Keys.followedRaces) }
    }

    private let defaults: UserDefaults

    // MARK: - Init

    init(defaults: UserDefaults? = nil) {
        if let defaults {
            self.defaults = defaults
        } else if let shared = UserDefaults(suiteName: Self.appGroupID) {
            self.defaults = shared
        } else {
            self.defaults = .standard
        }

        let d = self.defaults
        hasCompletedOnboarding = d.bool(forKey: Keys.onboardingComplete)
        favoriteDriverIDs = Set(d.stringArray(forKey: Keys.favoriteDrivers) ?? [])
        favoriteConstructorID = d.string(forKey: Keys.favoriteConstructor)
        if let data = d.data(forKey: Keys.notifications),
           let prefs = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            notifications = prefs
        } else {
            notifications = .default
        }
        appearance = AppearanceMode(rawValue: d.string(forKey: Keys.appearance) ?? "") ?? .dark
        followedRaceIDs = Set(d.stringArray(forKey: Keys.followedRaces) ?? [])
    }

    // MARK: - Favorites

    func isFavoriteDriver(_ id: String) -> Bool {
        favoriteDriverIDs.contains(id)
    }

    func toggleDriverFavorite(_ id: String) {
        if favoriteDriverIDs.contains(id) {
            favoriteDriverIDs.remove(id)
        } else {
            favoriteDriverIDs.insert(id)
        }
    }

    func setFavoriteConstructor(_ id: String?) {
        favoriteConstructorID = id
    }

    func isFavoriteConstructor(_ id: String) -> Bool {
        favoriteConstructorID == id
    }

    func toggleFollowedRace(_ id: String) {
        if followedRaceIDs.contains(id) {
            followedRaceIDs.remove(id)
        } else {
            followedRaceIDs.insert(id)
        }
    }

    private enum Keys {
        static let onboardingComplete = "pw.onboardingComplete"
        static let favoriteDrivers = "pw.favoriteDriverIDs"
        static let favoriteConstructor = "pw.favoriteConstructorID"
        static let notifications = "pw.notificationPreferences"
        static let appearance = "pw.appearance"
        static let followedRaces = "pw.followedRaceIDs"
    }
}
