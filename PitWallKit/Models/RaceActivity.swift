import Foundation
import ActivityKit

/// Attributes for the future live race Activity (Live Activity + Dynamic Island).
///
/// Kept deliberately compact: Live Activity update payloads must stay small.
/// The static data is set once when the activity starts; `ContentState` carries
/// everything that changes during the race.
struct RaceActivityAttributes: ActivityAttributes {
    /// Static for the lifetime of the activity.
    let raceID: String
    let raceName: String
    let round: Int
    let countryFlag: String
    let totalLaps: Int

    public struct ContentState: Codable, Hashable {
        /// Current lap. 0 during formation lap.
        var lap: Int
        var leaderCode: String
        /// Championship position of the user's favorite driver, when known.
        var favoriteDriverPosition: Int?
        /// Favorite driver's gap to leader, formatted, e.g. "+2.4s".
        var favoriteDriverGap: String?
        /// Top driver codes, ordered by current position, capped at 3.
        var topDriverCodes: [String]
        /// True when the race is under safety car.
        var isSafetyCar: Bool
    }
}

/// UI-side snapshot of a live race, mirroring `RaceActivityAttributes.ContentState`.
/// ViewModels and previews use this until the backend pushes live state.
struct RaceLiveState: Codable, Equatable, Sendable {
    let raceID: String
    let lap: Int
    let totalLaps: Int
    let leaderCode: String
    let favoriteDriverPosition: Int?
    let favoriteDriverGap: String?
    let topDriverCodes: [String]
    let isSafetyCar: Bool
}
