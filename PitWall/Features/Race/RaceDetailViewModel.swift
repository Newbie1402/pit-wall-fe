import Foundation
import Observation

/// Drives Race Detail: weekend schedule, per-session results, follow state.
@MainActor
@Observable
final class RaceDetailViewModel {

    struct Content {
        let race: Race
        /// Results for completed sessions, keyed by session type.
        let results: [SessionType: SessionResult]
    }

    private(set) var state: Loadable<Content> = .idle

    private let raceID: String
    private let raceRepository: any RaceRepository

    init(raceID: String, raceRepository: any RaceRepository) {
        self.raceID = raceID
        self.raceRepository = raceRepository
    }

    func load() async {
        if case .loaded = state { return }
        if state.isLoading { return }
        state = .loading

        do {
            let race = try await raceRepository.race(id: raceID)
            var results: [SessionType: SessionResult] = [:]
            let now = Date()
            if race.state(at: now) == .completed || race.sessionsInOrder.contains(where: { $0.state(at: now) == .completed }) {
                if let raceResult = try? await raceRepository.results(for: raceID) {
                    for sessionResult in raceResult.results {
                        results[sessionResult.sessionType] = sessionResult
                    }
                }
            }
            state = .loaded(Content(race: race, results: results))
        } catch {
            state = .failed(PWErrorMapper.message(for: error))
        }
    }
}
