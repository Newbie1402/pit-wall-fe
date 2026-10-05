import Foundation
import Observation

/// Drives Team Detail: constructor profile, stats, drivers, team feed.
@MainActor
@Observable
final class TeamDetailViewModel {

    struct Content {
        let constructor: Constructor
        let stats: ConstructorSeasonStats
        let drivers: [DriverStanding]
        let feed: [FeedItem]
    }

    private(set) var state: Loadable<Content> = .idle

    private let teamID: String
    private let constructorRepository: any ConstructorRepository
    private let driverRepository: any DriverRepository
    private let standingsRepository: any StandingsRepository
    private let feedRepository: any FeedRepository

    init(teamID: String,
         constructorRepository: any ConstructorRepository,
         driverRepository: any DriverRepository,
         standingsRepository: any StandingsRepository,
         feedRepository: any FeedRepository) {
        self.teamID = teamID
        self.constructorRepository = constructorRepository
        self.driverRepository = driverRepository
        self.standingsRepository = standingsRepository
        self.feedRepository = feedRepository
    }

    func load() async {
        if case .loaded = state { return }
        if state.isLoading { return }
        state = .loading

        do {
            async let constructor = constructorRepository.constructor(id: teamID)
            async let stats = constructorRepository.seasonStats(forConstructorID: teamID)
            async let standings = standingsRepository.driverStandings(year: MockSeasonFactory.seasonYear)
            async let feed = feedRepository.feed()

            let loadedConstructor = try await constructor
            let loadedStats = try await stats
            let loadedStandings = try await standings
            let loadedFeed = try await feed

            let teamDrivers = loadedStandings
                .filter { $0.driver.constructorID == teamID }
                .sorted { $0.position < $1.position }

            let teamFeed = loadedFeed
                .filter { $0.teamID == teamID }
                .sorted { $0.publishedAt > $1.publishedAt }

            state = .loaded(Content(constructor: loadedConstructor,
                                    stats: loadedStats,
                                    drivers: teamDrivers,
                                    feed: teamFeed))
        } catch {
            state = .failed(PWErrorMapper.message(for: error))
        }
    }
}
