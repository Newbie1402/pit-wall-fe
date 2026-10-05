import Foundation
import Observation

/// Drives Driver Detail: profile, season stats, recent form and results.
@MainActor
@Observable
final class DriverDetailViewModel {

    struct Content {
        let driver: Driver
        let constructor: Constructor
        let stats: DriverSeasonStats
    }

    private(set) var state: Loadable<Content> = .idle

    private let driverID: String
    private let driverRepository: any DriverRepository
    private let constructorRepository: any ConstructorRepository

    init(driverID: String,
         driverRepository: any DriverRepository,
         constructorRepository: any ConstructorRepository) {
        self.driverID = driverID
        self.driverRepository = driverRepository
        self.constructorRepository = constructorRepository
    }

    func load() async {
        if case .loaded = state { return }
        if state.isLoading { return }
        state = .loading

        do {
            async let driver = driverRepository.driver(id: driverID)
            async let constructor = constructorRepository.constructor(id: try await driver.constructorID)
            async let stats = driverRepository.seasonStats(forDriverID: driverID)

            let loadedDriver = try await driver
            let loadedConstructor = try await constructor
            let loadedStats = try await stats
            state = .loaded(Content(driver: loadedDriver, constructor: loadedConstructor, stats: loadedStats))
        } catch {
            state = .failed(PWErrorMapper.message(for: error))
        }
    }
}
