import Foundation

/// Computes championship tables and per-driver/team season statistics from
/// race results. Shared logic: the mock repositories use it today; a backend
/// would replace the inputs, not the rules.
enum StandingsCalculator {

    /// Standard F1 points tables.
    private static let racePoints = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
    private static let sprintPoints = [8, 7, 6, 5, 4, 3, 2, 1]

    struct ChampionshipSummary: Equatable, Sendable {
        let driverStandings: [DriverStanding]
        let constructorStandings: [ConstructorStanding]
    }

    // MARK: - Championship

    static func championshipSummary(races: [Race],
                                    results: [RaceResult],
                                    drivers: [Driver],
                                    constructors: [Constructor],
                                    now: Date = Date()) -> ChampionshipSummary {
        let completedResults = completedResults(races: races, results: results, at: now)

        var driverPoints: [String: Int] = [:]
        var driverWins: [String: Int] = [:]
        var constructorPoints: [String: Int] = [:]
        var constructorWins: [String: Int] = [:]

        for raceResult in completedResults {
            for sessionResult in raceResult.results {
                guard sessionResult.sessionType == .race || sessionResult.sessionType == .sprint else { continue }
                let table = sessionResult.sessionType == .sprint ? sprintPoints : racePoints

                for entry in sessionResult.entries where entry.isClassified {
                    let points = entry.position <= table.count ? table[entry.position - 1] : 0
                    driverPoints[entry.driverID, default: 0] += points
                    constructorPoints[entry.constructorID, default: 0] += points
                    if entry.position == 1 {
                        driverWins[entry.driverID, default: 0] += 1
                        constructorWins[entry.constructorID, default: 0] += 1
                    }
                }
            }
        }

        let driverRows: [DriverStanding] = drivers.map { driver in
            let constructor = constructors.first { $0.id == driver.constructorID }
                ?? Constructor(id: driver.constructorID, name: driver.constructorID,
                               shortName: driver.constructorID, colorHex: "#888888", countryFlag: "")
            return DriverStanding(
                position: 0,
                driver: driver,
                constructor: constructor,
                points: driverPoints[driver.id] ?? 0,
                wins: driverWins[driver.id] ?? 0,
                pointsBehindLeader: 0
            )
        }

        let sortedDrivers = driverRows.sorted { lhs, rhs in
            if lhs.points != rhs.points { return lhs.points > rhs.points }
            if lhs.wins != rhs.wins { return lhs.wins > rhs.wins }
            return lhs.driver.lastName < rhs.driver.lastName
        }
        let leaderDriverPoints = sortedDrivers.first?.points ?? 0
        let rankedDrivers = sortedDrivers.enumerated().map { index, standing in
            DriverStanding(
                position: index + 1,
                driver: standing.driver,
                constructor: standing.constructor,
                points: standing.points,
                wins: standing.wins,
                pointsBehindLeader: leaderDriverPoints - standing.points
            )
        }

        let constructorRows: [ConstructorStanding] = constructors.map { constructor in
            ConstructorStanding(
                position: 0,
                constructor: constructor,
                points: constructorPoints[constructor.id] ?? 0,
                wins: constructorWins[constructor.id] ?? 0,
                pointsBehindLeader: 0
            )
        }
        let sortedConstructors = constructorRows.sorted { lhs, rhs in
            if lhs.points != rhs.points { return lhs.points > rhs.points }
            if lhs.wins != rhs.wins { return lhs.wins > rhs.wins }
            return lhs.constructor.name < rhs.constructor.name
        }
        let leaderConstructorPoints = sortedConstructors.first?.points ?? 0
        let rankedConstructors = sortedConstructors.enumerated().map { index, standing in
            ConstructorStanding(
                position: index + 1,
                constructor: standing.constructor,
                points: standing.points,
                wins: standing.wins,
                pointsBehindLeader: leaderConstructorPoints - standing.points
            )
        }

        return ChampionshipSummary(driverStandings: rankedDrivers, constructorStandings: rankedConstructors)
    }

    // MARK: - Driver stats

    static func driverStats(driverID: String,
                            races: [Race],
                            results: [RaceResult],
                            drivers: [Driver],
                            constructors: [Constructor],
                            now: Date = Date()) -> DriverSeasonStats? {
        guard drivers.contains(where: { $0.id == driverID }) else { return nil }
        let summary = championshipSummary(races: races, results: results,
                                          drivers: drivers, constructors: constructors, now: now)
        let standing = summary.driverStandings.first { $0.driver.id == driverID }

        let completedRaces = races
            .filter { race in
                results.contains { $0.raceID == race.id && $0.results.contains { $0.sessionType == .race } }
            }
            .sorted { $0.round < $1.round }

        var weekendResults: [RaceWeekendResult] = []
        for race in completedRaces {
            guard let raceResult = results.first(where: { $0.raceID == race.id }) else { continue }
            let raceEntry = raceResult.result(for: .race)?.entries.first { $0.driverID == driverID }
            let qualiEntry = raceResult.result(for: .qualifying)?.entries.first { $0.driverID == driverID }
            weekendResults.append(RaceWeekendResult(
                raceID: race.id,
                round: race.round,
                raceName: race.name,
                countryFlag: race.countryFlag,
                racePosition: raceEntry?.position,
                qualifyingPosition: qualiEntry?.position,
                points: raceEntry?.points ?? 0,
                status: raceEntry?.status
            ))
        }

        var wins = 0
        var podiums = 0
        for weekend in weekendResults {
            if weekend.racePosition == 1 { wins += 1 }
            if let position = weekend.racePosition, position <= 3 { podiums += 1 }
        }

        let form = Array(weekendResults.suffix(5).map { $0.racePosition })

        return DriverSeasonStats(
            driverID: driverID,
            championshipPosition: standing?.position,
            points: standing?.points ?? 0,
            wins: wins,
            podiums: podiums,
            poles: weekendResults.filter { $0.qualifyingPosition == 1 }.count,
            fastestLaps: 0,
            recentForm: form,
            recentRaces: Array(weekendResults.reversed())
        )
    }

    // MARK: - Constructor stats

    static func constructorStats(constructorID: String,
                                 races: [Race],
                                 results: [RaceResult],
                                 drivers: [Driver],
                                 constructors: [Constructor],
                                 now: Date = Date()) -> ConstructorSeasonStats? {
        guard constructors.contains(where: { $0.id == constructorID }) else { return nil }
        let summary = championshipSummary(races: races, results: results,
                                          drivers: drivers, constructors: constructors, now: now)
        let standing = summary.constructorStandings.first { $0.constructor.id == constructorID }

        let teamDriverIDs = Set(drivers.filter { $0.constructorID == constructorID }.map { $0.id })
        let completedRaces = races
            .filter { race in
                results.contains { $0.raceID == race.id && $0.results.contains { $0.sessionType == .race } }
            }
            .sorted { $0.round < $1.round }

        var wins = 0
        var podiums = 0
        var recentForm: [Int?] = []

        for race in completedRaces {
            guard let raceResult = results.first(where: { $0.raceID == race.id }),
                  let raceSession = raceResult.result(for: .race) else { continue }

            let teamEntries = raceSession.entries
                .filter { teamDriverIDs.contains($0.driverID) && $0.isClassified }
                .sorted { $0.position < $1.position }

            if let best = teamEntries.first {
                if best.position == 1 { wins += 1 }
                if best.position <= 3 { podiums += 1 }
            }
            recentForm.append(teamEntries.first?.position)
        }

        return ConstructorSeasonStats(
            constructorID: constructorID,
            championshipPosition: standing?.position,
            points: standing?.points ?? 0,
            wins: wins,
            podiums: podiums,
            recentForm: Array(recentForm.suffix(5))
        )
    }

    // MARK: - Helpers

    private static func completedResults(races: [Race], results: [RaceResult], at now: Date) -> [RaceResult] {
        let completedRaceIDs = Set(races.compactMap { race -> String? in
            guard let session = race.raceSession,
                  session.state(at: now) == .completed else { return nil }
            return race.id
        })
        return results.filter { completedRaceIDs.contains($0.raceID) }
    }
}
