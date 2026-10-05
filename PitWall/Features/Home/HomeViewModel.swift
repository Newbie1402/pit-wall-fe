import Foundation
import Observation

/// Drives the Home screen: next session hero, favorite drivers, latest feed.
@MainActor
@Observable
final class HomeViewModel {

    struct MyDriver: Identifiable {
        let driver: Driver
        let constructor: Constructor
        let standing: DriverStanding?
        let lastResult: RaceWeekendResult?

        var id: String { driver.id }
    }

    struct Content {
        let seasonYear: Int
        let next: NextSessionSelector.Selection
        let myDrivers: [MyDriver]
        let feed: [FeedItem]
    }

    private(set) var state: Loadable<Content> = .idle

    private let raceRepository: any RaceRepository
    private let driverRepository: any DriverRepository
    private let constructorRepository: any ConstructorRepository
    private let standingsRepository: any StandingsRepository
    private let feedRepository: any FeedRepository
    private let preferences: UserPreferencesStore

    init(raceRepository: any RaceRepository,
         driverRepository: any DriverRepository,
         constructorRepository: any ConstructorRepository,
         standingsRepository: any StandingsRepository,
         feedRepository: any FeedRepository,
         preferences: UserPreferencesStore) {
        self.raceRepository = raceRepository
        self.driverRepository = driverRepository
        self.constructorRepository = constructorRepository
        self.standingsRepository = standingsRepository
        self.feedRepository = feedRepository
        self.preferences = preferences
    }

    func load(force: Bool = false) async {
        if case .loaded = state, !force { return }
        if state.isLoading { return }
        state = .loading

        do {
            async let season = raceRepository.season(year: MockSeasonFactory.seasonYear)
            async let standings = standingsRepository.driverStandings(year: MockSeasonFactory.seasonYear)
            async let constructors = constructorRepository.constructors()
            async let feed = feedRepository.feed()

            let loadedSeason = try await season
            let loadedStandings = try await standings
            let loadedConstructors = try await constructors
            let loadedFeed = try await feed

            guard let next = NextSessionSelector.select(in: loadedSeason.races, at: Date()) else {
                state = .failed("The season has finished. New season data is on its way.")
                return
            }

            let myDrivers = await buildMyDrivers(
                standings: loadedStandings,
                constructors: loadedConstructors,
                season: loadedSeason
            )

            let personalizedFeed = FeedPersonalizer.sorted(
                loadedFeed,
                favoriteDriverIDs: preferences.favoriteDriverIDs,
                favoriteConstructorID: preferences.favoriteConstructorID
            )

            state = .loaded(Content(
                seasonYear: loadedSeason.year,
                next: next,
                myDrivers: myDrivers,
                feed: personalizedFeed
            ))
        } catch {
            state = .failed(PWErrorMapper.message(for: error))
        }
    }

    // MARK: - Personalization

    private func buildMyDrivers(standings: [DriverStanding],
                                constructors: [Constructor],
                                season: Season) async -> [MyDriver] {
        let constructorsByID = Dictionary(uniqueKeysWithValues: constructors.map { ($0.id, $0) })
        let standingsByDriver = Dictionary(uniqueKeysWithValues: standings.map { ($0.driver.id, $0) })

        // Last completed race result per driver, for the "LAST" chip.
        var lastResults: [String: RaceWeekendResult] = [:]
        let completedRaces = season.racesInRoundOrder.filter { $0.state(at: Date()) == .completed }
        if let lastCompleted = completedRaces.last,
           let raceResult = try? await raceRepository.results(for: lastCompleted.id) {
            for entry in raceResult.result(for: .race)?.entries ?? [] {
                lastResults[entry.driverID] = RaceWeekendResult(
                    raceID: lastCompleted.id,
                    round: lastCompleted.round,
                    raceName: lastCompleted.name,
                    countryFlag: lastCompleted.countryFlag,
                    racePosition: entry.position,
                    qualifyingPosition: nil,
                    points: entry.points,
                    status: entry.status
                )
            }
        }

        return preferences.favoriteDriverIDs
            .compactMap { id in
                guard let standing = standingsByDriver[id],
                      let constructor = constructorsByID[standing.driver.constructorID] else { return nil }
                return MyDriver(driver: standing.driver,
                                constructor: constructor,
                                standing: standing,
                                lastResult: lastResults[id])
            }
            .sorted { ($0.standing?.position ?? 99) < ($1.standing?.position ?? 99) }
    }
}
