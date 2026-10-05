import Foundation
import Observation

/// Drives the season calendar screen.
@MainActor
@Observable
final class CalendarViewModel {

    enum Filter: String, CaseIterable, Identifiable {
        case upcoming
        case completed
        case all

        var id: String { rawValue }

        var title: String {
            switch self {
            case .upcoming: return "Upcoming"
            case .completed: return "Completed"
            case .all: return "All"
            }
        }
    }

    struct Content {
        let season: Season
        let nextRaceID: String?
        /// Winner of each completed race, for the card's "WINNER" line.
        let winnersByRace: [String: String]
    }

    private(set) var state: Loadable<Content> = .idle
    var filter: Filter = .upcoming

    private let raceRepository: any RaceRepository

    init(raceRepository: any RaceRepository) {
        self.raceRepository = raceRepository
    }

    func load() async {
        if case .loaded = state { return }
        if state.isLoading { return }
        state = .loading

        do {
            let season = try await raceRepository.season(year: MockSeasonFactory.seasonYear)
            let now = Date()
            let nextRaceID = season.nextRace(after: now)?.id

            var winners: [String: String] = [:]
            for race in season.races where race.state(at: now) == .completed {
                if let result = try? await raceRepository.results(for: race.id),
                   let winnerEntry = result.result(for: .race)?.winner,
                   let winner = MockRoster.driver(for: winnerEntry.driverID) {
                    winners[race.id] = winner.fullName
                }
            }

            state = .loaded(Content(season: season, nextRaceID: nextRaceID, winnersByRace: winners))
        } catch {
            state = .failed(PWErrorMapper.message(for: error))
        }
    }

    /// Races for the current filter, ordered by round.
    func races(for content: Content) -> [Race] {
        let now = Date()
        let all = content.season.racesInRoundOrder
        switch filter {
        case .upcoming:
            return all.filter { $0.state(at: now) != .completed }
        case .completed:
            return all.filter { $0.state(at: now) == .completed }.reversed()
        case .all:
            return all
        }
    }
}
