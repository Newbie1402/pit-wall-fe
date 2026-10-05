import Foundation

/// Full result set of one race weekend: results per session.
struct RaceResult: Codable, Identifiable, Equatable, Sendable {
    let raceID: String
    let results: [SessionResult]

    var id: String { raceID }

    func result(for type: SessionType) -> SessionResult? {
        results.first { $0.sessionType == type }
    }
}

/// Classification of one session.
struct SessionResult: Codable, Equatable, Sendable {
    let sessionType: SessionType
    let entries: [ResultEntry]

    /// Winner, when the session has a classified winner.
    var winner: ResultEntry? {
        entries.first { $0.position == 1 }
    }
}

/// One classified entry in a session result.
struct ResultEntry: Codable, Identifiable, Equatable, Sendable {
    let position: Int
    let driverID: String
    let constructorID: String
    /// Gap to the winner, formatted, e.g. "+5.321s". Nil for the winner.
    let gapToWinner: String?
    /// Points awarded for this finishing position.
    let points: Int
    /// Finishing status, e.g. "DNF", "DNS". Nil when finished.
    let status: String?

    var id: String { driverID }

    var isClassified: Bool { status == nil }
}

/// Season statistics for one driver, used by Driver Detail.
struct DriverSeasonStats: Codable, Equatable, Sendable {
    let driverID: String
    let championshipPosition: Int?
    let points: Int
    let wins: Int
    let podiums: Int
    let poles: Int
    let fastestLaps: Int
    /// Positions of the last five races, oldest first. Nil means not classified (DNF/DNS).
    let recentForm: [Int?]
    /// Most recent race weekends with the driver's result.
    let recentRaces: [RaceWeekendResult]
}

/// One past race weekend and a driver's result in it.
struct RaceWeekendResult: Codable, Identifiable, Equatable, Sendable {
    let raceID: String
    let round: Int
    let raceName: String
    let countryFlag: String
    let racePosition: Int?
    let qualifyingPosition: Int?
    let points: Int
    let status: String?

    var id: String { raceID }
}

/// Season statistics for one constructor, used by Team Detail.
struct ConstructorSeasonStats: Codable, Equatable, Sendable {
    let constructorID: String
    let championshipPosition: Int?
    let points: Int
    let wins: Int
    let podiums: Int
    /// Best finish of each of the last five race weekends, oldest first.
    let recentForm: [Int?]
}
