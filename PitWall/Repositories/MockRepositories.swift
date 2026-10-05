import Foundation

/// Shared failure injection for mock repositories, letting tests and previews
/// exercise error states without a network.
enum MockRepositoryFailure {
    case none
    case always
}

/// Small simulated latency so loading states are visible in mocks.
enum MockLatency {
    static func wait() async throws {
        let milliseconds = UInt64.random(in: 220...620)
        try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }
}

/// Mock-backed season and race data.
final class MockRaceRepository: RaceRepository {

    private let factory: MockSeasonFactory
    private let failureMode: MockRepositoryFailure

    init(factory: MockSeasonFactory = .shared, failureMode: MockRepositoryFailure = .none) {
        self.factory = factory
        self.failureMode = failureMode
    }

    func season(year: Int) async throws -> Season {
        try await simulate()
        return factory.season
    }

    func race(id: String) async throws -> Race {
        try await simulate()
        guard let race = factory.season.races.first(where: { $0.id == id }) else {
            throw APIError.requestFailed("Race \(id) not found.")
        }
        return race
    }

    func results(for raceID: String) async throws -> RaceResult {
        try await simulate()
        guard let result = factory.results.first(where: { $0.raceID == raceID }) else {
            throw APIError.requestFailed("No results for race \(raceID).")
        }
        return result
    }

    private func simulate() async throws {
        if case .always = failureMode {
            throw APIError.requestFailed("Mock failure")
        }
        try await MockLatency.wait()
    }
}

/// Mock-backed driver data.
final class MockDriverRepository: DriverRepository {

    private let factory: MockSeasonFactory
    private let failureMode: MockRepositoryFailure

    init(factory: MockSeasonFactory = .shared, failureMode: MockRepositoryFailure = .none) {
        self.factory = factory
        self.failureMode = failureMode
    }

    func drivers() async throws -> [Driver] {
        try await simulate()
        return MockRoster.drivers
    }

    func driver(id: String) async throws -> Driver {
        try await simulate()
        guard let driver = MockRoster.driver(for: id) else {
            throw APIError.requestFailed("Driver \(id) not found.")
        }
        return driver
    }

    func seasonStats(forDriverID driverID: String) async throws -> DriverSeasonStats {
        try await simulate()
        guard let stats = factory.seasonStats(forDriverID: driverID) else {
            throw APIError.requestFailed("No stats for driver \(driverID).")
        }
        return stats
    }

    private func simulate() async throws {
        if case .always = failureMode {
            throw APIError.requestFailed("Mock failure")
        }
        try await MockLatency.wait()
    }
}

/// Mock-backed constructor data.
final class MockConstructorRepository: ConstructorRepository {

    private let factory: MockSeasonFactory
    private let failureMode: MockRepositoryFailure

    init(factory: MockSeasonFactory = .shared, failureMode: MockRepositoryFailure = .none) {
        self.factory = factory
        self.failureMode = failureMode
    }

    func constructors() async throws -> [Constructor] {
        try await simulate()
        return MockRoster.constructors
    }

    func constructor(id: String) async throws -> Constructor {
        try await simulate()
        guard let constructor = MockRoster.constructor(for: id) else {
            throw APIError.requestFailed("Constructor \(id) not found.")
        }
        return constructor
    }

    func seasonStats(forConstructorID constructorID: String) async throws -> ConstructorSeasonStats {
        try await simulate()
        guard let stats = factory.seasonStats(forConstructorID: constructorID) else {
            throw APIError.requestFailed("No stats for constructor \(constructorID).")
        }
        return stats
    }

    private func simulate() async throws {
        if case .always = failureMode {
            throw APIError.requestFailed("Mock failure")
        }
        try await MockLatency.wait()
    }
}

/// Mock-backed standings.
final class MockStandingsRepository: StandingsRepository {

    private let factory: MockSeasonFactory
    private let failureMode: MockRepositoryFailure

    init(factory: MockSeasonFactory = .shared, failureMode: MockRepositoryFailure = .none) {
        self.factory = factory
        self.failureMode = failureMode
    }

    func driverStandings(year: Int) async throws -> [DriverStanding] {
        try await simulate()
        return factory.driverStandings
    }

    func constructorStandings(year: Int) async throws -> [ConstructorStanding] {
        try await simulate()
        return factory.constructorStandings
    }

    private func simulate() async throws {
        if case .always = failureMode {
            throw APIError.requestFailed("Mock failure")
        }
        try await MockLatency.wait()
    }
}

/// Mock-backed feed.
final class MockFeedRepository: FeedRepository {

    private let factory: MockSeasonFactory
    private let failureMode: MockRepositoryFailure

    init(factory: MockSeasonFactory = .shared, failureMode: MockRepositoryFailure = .none) {
        self.factory = factory
        self.failureMode = failureMode
    }

    func feed() async throws -> [FeedItem] {
        try await simulate()
        return factory.feed
    }

    private func simulate() async throws {
        if case .always = failureMode {
            throw APIError.requestFailed("Mock failure")
        }
        try await MockLatency.wait()
    }
}
