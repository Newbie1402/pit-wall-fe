import Foundation

/// Selection of the "next relevant" session across the season.
///
/// A live session counts as the next relevant one — the user wants to know
/// what is happening right now. Otherwise the earliest upcoming session wins.
enum NextSessionSelector {

    struct Selection: Equatable, Sendable {
        let race: Race
        let session: RaceSession
        /// True when the selected session is running right now.
        let isLive: Bool
    }

    /// The next relevant session across `races`, or nil when the season is over.
    static func select(in races: [Race], at now: Date) -> Selection? {
        let orderedRaces = races.sorted { $0.round < $1.round }

        var best: Selection?
        for race in orderedRaces {
            for session in race.sessionsInOrder {
                switch session.state(at: now) {
                case .live:
                    return Selection(race: race, session: session, isLive: true)
                case .upcoming:
                    if best == nil {
                        best = Selection(race: race, session: session, isLive: false)
                    }
                case .completed:
                    continue
                }
            }
        }
        return best
    }
}

/// Sorts sessions chronologically with a stable tie-break on type.
enum SessionSorter {

    static func sorted(_ sessions: [RaceSession]) -> [RaceSession] {
        sessions.sorted {
            if $0.startDate != $1.startDate {
                return $0.startDate < $1.startDate
            }
            return typeOrder($0.type) < typeOrder($1.type)
        }
    }

    private static func typeOrder(_ type: SessionType) -> Int {
        SessionType.allCases.firstIndex(of: type) ?? .max
    }
}
