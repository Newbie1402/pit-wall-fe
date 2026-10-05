import Foundation

/// Race weekends and seasons.
protocol RaceRepository: Sendable {
    func season(year: Int) async throws -> Season
    func race(id: String) async throws -> Race
}

/// Drivers and their season statistics.
protocol DriverRepository: Sendable {
    func drivers() async throws -> [Driver]
    func driver(id: String) async throws -> Driver
    func seasonStats(forDriverID driverID: String) async throws -> DriverSeasonStats
}

/// Constructors and their season statistics.
protocol ConstructorRepository: Sendable {
    func constructors() async throws -> [Constructor]
    func constructor(id: String) async throws -> Constructor
    func seasonStats(forConstructorID constructorID: String) async throws -> ConstructorSeasonStats
}

/// Championship tables.
protocol StandingsRepository: Sendable {
    func driverStandings(year: Int) async throws -> [DriverStanding]
    func constructorStandings(year: Int) async throws -> [ConstructorStanding]
}

/// Personalized feed.
protocol FeedRepository: Sendable {
    func feed() async throws -> [FeedItem]
}
