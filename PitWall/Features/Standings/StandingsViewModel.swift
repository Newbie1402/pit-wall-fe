import Foundation
import Observation

/// Drives the Standings screen (drivers + constructors segments).
@MainActor
@Observable
final class StandingsViewModel {

    enum Segment: String, CaseIterable, Identifiable {
        case drivers
        case constructors

        var id: String { rawValue }

        var title: String {
            switch self {
            case .drivers: return "Drivers"
            case .constructors: return "Constructors"
            }
        }
    }

    struct Content {
        let driverStandings: [DriverStanding]
        let constructorStandings: [ConstructorStanding]
    }

    private(set) var state: Loadable<Content> = .idle
    var segment: Segment = .drivers

    private let standingsRepository: any StandingsRepository

    init(standingsRepository: any StandingsRepository) {
        self.standingsRepository = standingsRepository
    }

    func load() async {
        if case .loaded = state { return }
        if state.isLoading { return }
        state = .loading

        do {
            async let drivers = standingsRepository.driverStandings(year: MockSeasonFactory.seasonYear)
            async let constructors = standingsRepository.constructorStandings(year: MockSeasonFactory.seasonYear)
            state = .loaded(Content(driverStandings: try await drivers,
                                    constructorStandings: try await constructors))
        } catch {
            state = .failed(PWErrorMapper.message(for: error))
        }
    }
}
