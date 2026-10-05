import Foundation

/// Deterministic pseudo-random generator (SplitMix64).
///
/// Mock results must be stable within a process so screens agree with each
/// other, while still looking organic.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func nextDouble() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z = z ^ (z >> 31)
        return Double(z >> 11) / Double(1 << 53)
    }

    mutating func double(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextDouble() * (range.upperBound - range.lowerBound)
    }

    mutating func chance(_ probability: Double) -> Bool {
        nextDouble() < probability
    }
}

/// Builds the complete mock 2026 season.
///
/// Dates are anchored to "now": round 17 (Singapore) is the next Sunday after
/// `now + 4 days`, earlier rounds sit one week apart. This guarantees the app
/// always exercises a live countdown, completed races with results, and
/// future races — regardless of when it runs.
final class MockSeasonFactory {

    static let seasonYear = 2026
    static let anchorRound = 17

    /// Shared instance for the app/widget process, built once.
    static let shared = MockSeasonFactory()

    let season: Season
    let results: [RaceResult]
    let feed: [FeedItem]

    private let drivers: [Driver]
    private let constructors: [Constructor]
    private var cachedDriverStandings: [DriverStanding]?
    private var cachedConstructorStandings: [ConstructorStanding]?

    init(now: Date = Date()) {
        drivers = MockRoster.drivers
        constructors = MockRoster.constructors

        let calendarDefinitions = Self.calendarDefinitions
        let anchorDate = Self.upcomingRaceDate(after: now)

        var builtRaces: [Race] = []
        builtRaces.reserveCapacity(calendarDefinitions.count)

        for definition in calendarDefinitions {
            let offsetDays = definition.round - Self.anchorRound
            let raceDate = anchorDate.addingTimeInterval(Double(offsetDays) * 7 * 86_400)
            let race = Self.makeRace(from: definition, raceDate: raceDate)
            builtRaces.append(race)
        }

        season = Season(
            id: "season-\(Self.seasonYear)",
            year: Self.seasonYear,
            races: builtRaces
        )

        results = Self.generateResults(for: builtRaces, now: now)
        feed = MockFeedFactory.makeFeed(now: now)
    }

    // MARK: - Standings

    var driverStandings: [DriverStanding] {
        if let cachedDriverStandings { return cachedDriverStandings }
        let summary = StandingsCalculator.championshipSummary(
            races: season.racesInRoundOrder,
            results: results,
            drivers: drivers,
            constructors: constructors
        )
        cachedDriverStandings = summary.driverStandings
        return summary.driverStandings
    }

    var constructorStandings: [ConstructorStanding] {
        if let cachedConstructorStandings { return cachedConstructorStandings }
        let summary = StandingsCalculator.championshipSummary(
            races: season.racesInRoundOrder,
            results: results,
            drivers: drivers,
            constructors: constructors
        )
        cachedConstructorStandings = summary.constructorStandings
        return summary.constructorStandings
    }

    func seasonStats(forDriverID driverID: String) -> DriverSeasonStats? {
        StandingsCalculator.driverStats(
            driverID: driverID,
            races: season.racesInRoundOrder,
            results: results,
            drivers: drivers,
            constructors: constructors
        )
    }

    func seasonStats(forConstructorID constructorID: String) -> ConstructorSeasonStats? {
        StandingsCalculator.constructorStats(
            constructorID: constructorID,
            races: season.racesInRoundOrder,
            results: results,
            drivers: drivers,
            constructors: constructors
        )
    }

    // MARK: - Calendar

    /// The next Sunday at 12:00 UTC following `now + 4 days`, used as the
    /// anchor race date for round 17.
    static func upcomingRaceDate(after now: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current

        var date = calendar.date(byAdding: .day, value: 4, to: now) ?? now
        while calendar.component(.weekday, from: date) != 1 { // 1 == Sunday
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
    }

    private static func makeRace(from definition: RaceDefinition, raceDate: Date) -> Race {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current

        let friday = calendar.date(byAdding: .day, value: -2, to: raceDate) ?? raceDate
        let saturday = calendar.date(byAdding: .day, value: -1, to: raceDate) ?? raceDate

        func session(_ day: Date, _ hour: Int, _ type: SessionType, duration: TimeInterval) -> RaceSession {
            let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? raceDate
            return RaceSession(
                id: "\(definition.id)-\(type.rawValue)",
                raceID: definition.id,
                type: type,
                startDate: start,
                endDate: start.addingTimeInterval(duration)
            )
        }

        let template = definition.timeTemplate
        var sessions: [RaceSession] = [
            session(friday, template.practice1Hour, .practice1, duration: 3600),
        ]

        if definition.isSprint {
            sessions.append(session(friday, template.practice2Hour, .sprintQualifying, duration: 2700))
            sessions.append(session(saturday, template.practice1Hour + 3, .sprint, duration: 2700))
            sessions.append(session(saturday, template.practice2Hour, .qualifying, duration: 3600))
        } else {
            sessions.append(session(friday, template.practice2Hour, .practice2, duration: 3600))
            sessions.append(session(saturday, template.practice3Hour, .practice3, duration: 3600))
            sessions.append(session(saturday, template.qualifyingHour, .qualifying, duration: 3600))
        }

        sessions.append(session(raceDate, template.raceHour, .race, duration: 7200))

        return Race(
            id: definition.id,
            seasonID: "season-\(seasonYear)",
            round: definition.round,
            name: definition.name,
            shortName: definition.shortName,
            countryFlag: definition.countryFlag,
            countryName: definition.countryName,
            locality: definition.locality,
            circuit: Circuit(
                id: "\(definition.id)-circuit",
                name: definition.circuitName,
                lengthKilometers: definition.circuitLengthKm,
                laps: definition.laps
            ),
            sessions: sessions
        )
    }

    // MARK: - Results

    private static func generateResults(for races: [Race], now: Date) -> [RaceResult] {
        var generator = SeededRandom(seed: 0x5EED_F1A7_2026)
        var generated: [RaceResult] = []

        for race in races.sorted(by: { $0.round < $1.round }) {
            guard let raceSession = race.raceSession,
                  raceSession.state(at: now) == .completed else { continue }

            var sessionResults: [SessionResult] = []

            // Qualifying
            let qualifyingOrder = simulateOrder(generator: &generator)
            sessionResults.append(
                SessionResult(sessionType: .qualifying,
                              entries: classificationEntries(qualifyingOrder, gapStyle: .qualifying, generator: &generator))
            )

            // Sprint, where applicable
            if race.isSprintWeekend {
                let sprintOrder = simulateOrder(generator: &generator)
                sessionResults.append(
                    SessionResult(sessionType: .sprint,
                                  entries: classificationEntries(sprintOrder, gapStyle: .sprint, generator: &generator))
                )
            }

            // Race — round 16 is scripted so the most recent completed race
            // has a known, believable podium.
            var raceOrder: [String]
            if race.round == 16 {
                let scripted = ["norris", "verstappen", "piastri"]
                let simulated = simulateOrder(generator: &generator)
                raceOrder = scripted + simulated.filter { !scripted.contains($0) }
            } else {
                raceOrder = simulateOrder(generator: &generator)
            }
            sessionResults.append(
                SessionResult(sessionType: .race,
                              entries: classificationEntries(raceOrder, gapStyle: .race, generator: &generator))
            )

            generated.append(RaceResult(raceID: race.id, results: sessionResults))
        }

        return generated
    }

    private static func simulateOrder(generator: inout SeededRandom) -> [String] {
        struct Scored {
            let driverID: String
            let score: Double
            let didNotFinish: Bool
        }

        var scored: [Scored] = MockRoster.drivers.map { driver in
            let skill = Self.driverSkill[driver.id] ?? 0.75
            let teamStrength = Self.constructorStrength[driver.constructorID] ?? 0.7
            let noise = generator.double(in: 0...0.22)
            let score = skill * 0.62 + teamStrength * 0.38 + noise
            let dnf = generator.chance(0.08)
            return Scored(driverID: driver.id, score: score, didNotFinish: dnf)
        }

        scored.sort {
            if $0.didNotFinish != $1.didNotFinish { return !$0.didNotFinish }
            return $0.score > $1.score
        }
        return scored.map { $0.driverID }
    }

    /// Builds classified result entries with gaps and points from an ordered driver list.
    private static func classificationEntries(_ order: [String],
                                              gapStyle: GapStyle,
                                              generator: inout SeededRandom) -> [ResultEntry] {
        let pointsTable: [Int]
        let classifiedCount: Int
        switch gapStyle {
        case .qualifying:
            pointsTable = []
            classifiedCount = order.count
        case .sprint:
            pointsTable = [8, 7, 6, 5, 4, 3, 2, 1]
            classifiedCount = 12
        case .race:
            pointsTable = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
            classifiedCount = 18
        }

        var entries: [ResultEntry] = []
        var position = 1
        for driverID in order {
            guard position <= classifiedCount else { break }
            let constructorID = MockRoster.constructorID(forDriverID: driverID) ?? "unknown"
            let gap: String?
            if position == 1 {
                gap = nil
            } else {
                switch gapStyle {
                case .qualifying:
                    gap = String(format: "+%.3fs", generator.double(in: 0.05...2.5) + Double(position) * 0.08)
                case .sprint, .race:
                    gap = String(format: "+%.3fs", generator.double(in: 0.3...35) + Double(position) * 0.4)
                }
            }
            let points = position <= pointsTable.count ? pointsTable[position - 1] : 0
            entries.append(ResultEntry(
                position: position,
                driverID: driverID,
                constructorID: constructorID,
                gapToWinner: gap,
                points: points,
                status: nil
            ))
            position += 1
        }

        // Unclassified drivers appear at the tail with DNF status.
        for driverID in order.dropFirst(classifiedCount) {
            entries.append(ResultEntry(
                position: position,
                driverID: driverID,
                constructorID: MockRoster.constructorID(forDriverID: driverID) ?? "unknown",
                gapToWinner: nil,
                points: 0,
                status: "DNF"
            ))
            position += 1
        }

        return entries
    }

    private enum GapStyle {
        case qualifying
        case sprint
        case race
    }

    // MARK: - Static data

    struct RaceDefinition {
        let id: String
        let round: Int
        let name: String
        let shortName: String
        let countryFlag: String
        let countryName: String
        let locality: String
        let circuitName: String
        let circuitLengthKm: Double?
        let laps: Int?
        let isSprint: Bool
        let timeTemplate: SessionTimeTemplate
    }

    struct SessionTimeTemplate {
        let practice1Hour: Int
        let practice2Hour: Int
        let practice3Hour: Int
        let qualifyingHour: Int
        let raceHour: Int

        static let europe = SessionTimeTemplate(practice1Hour: 12, practice2Hour: 16, practice3Hour: 11, qualifyingHour: 15, raceHour: 14)
        static let asia = SessionTimeTemplate(practice1Hour: 3, practice2Hour: 7, practice3Hour: 5, qualifyingHour: 9, raceHour: 12)
        static let middleEast = SessionTimeTemplate(practice1Hour: 11, practice2Hour: 15, practice3Hour: 12, qualifyingHour: 16, raceHour: 16)
        static let americas = SessionTimeTemplate(practice1Hour: 16, practice2Hour: 20, practice3Hour: 17, qualifyingHour: 21, raceHour: 19)
        static let vegas = SessionTimeTemplate(practice1Hour: 20, practice2Hour: 23, practice3Hour: 21, qualifyingHour: 0, raceHour: 6)
    }

    private static let calendarDefinitions: [RaceDefinition] = [
        RaceDefinition(id: "australia", round: 1, name: "Australian Grand Prix", shortName: "Australia",
                       countryFlag: "🇦🇺", countryName: "Australia", locality: "Melbourne",
                       circuitName: "Albert Park Circuit", circuitLengthKm: 5.278, laps: 58,
                       isSprint: false, timeTemplate: .asia),
        RaceDefinition(id: "china", round: 2, name: "Chinese Grand Prix", shortName: "China",
                       countryFlag: "🇨🇳", countryName: "China", locality: "Shanghai",
                       circuitName: "Shanghai International Circuit", circuitLengthKm: 5.451, laps: 56,
                       isSprint: true, timeTemplate: .asia),
        RaceDefinition(id: "japan", round: 3, name: "Japanese Grand Prix", shortName: "Japan",
                       countryFlag: "🇯🇵", countryName: "Japan", locality: "Suzuka",
                       circuitName: "Suzuka International Racing Course", circuitLengthKm: 5.807, laps: 53,
                       isSprint: false, timeTemplate: .asia),
        RaceDefinition(id: "bahrain", round: 4, name: "Bahrain Grand Prix", shortName: "Bahrain",
                       countryFlag: "🇧🇭", countryName: "Bahrain", locality: "Sakhir",
                       circuitName: "Bahrain International Circuit", circuitLengthKm: 5.412, laps: 57,
                       isSprint: false, timeTemplate: .middleEast),
        RaceDefinition(id: "saudiarabia", round: 5, name: "Saudi Arabian Grand Prix", shortName: "Saudi Arabia",
                       countryFlag: "🇸🇦", countryName: "Saudi Arabia", locality: "Jeddah",
                       circuitName: "Jeddah Corniche Circuit", circuitLengthKm: 6.174, laps: 50,
                       isSprint: false, timeTemplate: .middleEast),
        RaceDefinition(id: "miami", round: 6, name: "Miami Grand Prix", shortName: "Miami",
                       countryFlag: "🇺🇸", countryName: "United States", locality: "Miami",
                       circuitName: "Miami International Autodrome", circuitLengthKm: 5.412, laps: 57,
                       isSprint: true, timeTemplate: .americas),
        RaceDefinition(id: "canada", round: 7, name: "Canadian Grand Prix", shortName: "Canada",
                       countryFlag: "🇨🇦", countryName: "Canada", locality: "Montreal",
                       circuitName: "Circuit Gilles Villeneuve", circuitLengthKm: 4.361, laps: 70,
                       isSprint: false, timeTemplate: .americas),
        RaceDefinition(id: "monaco", round: 8, name: "Monaco Grand Prix", shortName: "Monaco",
                       countryFlag: "🇲🇨", countryName: "Monaco", locality: "Monte Carlo",
                       circuitName: "Circuit de Monaco", circuitLengthKm: 3.337, laps: 78,
                       isSprint: false, timeTemplate: .europe),
        RaceDefinition(id: "spain", round: 9, name: "Spanish Grand Prix", shortName: "Spain",
                       countryFlag: "🇪🇸", countryName: "Spain", locality: "Barcelona",
                       circuitName: "Circuit de Barcelona-Catalunya", circuitLengthKm: 4.657, laps: 66,
                       isSprint: false, timeTemplate: .europe),
        RaceDefinition(id: "austria", round: 10, name: "Austrian Grand Prix", shortName: "Austria",
                       countryFlag: "🇦🇹", countryName: "Austria", locality: "Spielberg",
                       circuitName: "Red Bull Ring", circuitLengthKm: 4.318, laps: 71,
                       isSprint: false, timeTemplate: .europe),
        RaceDefinition(id: "britain", round: 11, name: "British Grand Prix", shortName: "Great Britain",
                       countryFlag: "🇬🇧", countryName: "United Kingdom", locality: "Silverstone",
                       circuitName: "Silverstone Circuit", circuitLengthKm: 5.891, laps: 52,
                       isSprint: false, timeTemplate: .europe),
        RaceDefinition(id: "belgium", round: 12, name: "Belgian Grand Prix", shortName: "Belgium",
                       countryFlag: "🇧🇪", countryName: "Belgium", locality: "Spa-Francorchamps",
                       circuitName: "Circuit de Spa-Francorchamps", circuitLengthKm: 7.004, laps: 44,
                       isSprint: true, timeTemplate: .europe),
        RaceDefinition(id: "hungary", round: 13, name: "Hungarian Grand Prix", shortName: "Hungary",
                       countryFlag: "🇭🇺", countryName: "Hungary", locality: "Budapest",
                       circuitName: "Hungaroring", circuitLengthKm: 4.381, laps: 70,
                       isSprint: false, timeTemplate: .europe),
        RaceDefinition(id: "netherlands", round: 14, name: "Dutch Grand Prix", shortName: "Netherlands",
                       countryFlag: "🇳🇱", countryName: "Netherlands", locality: "Zandvoort",
                       circuitName: "Circuit Zandvoort", circuitLengthKm: 4.259, laps: 72,
                       isSprint: false, timeTemplate: .europe),
        RaceDefinition(id: "italy", round: 15, name: "Italian Grand Prix", shortName: "Italy",
                       countryFlag: "🇮🇹", countryName: "Italy", locality: "Monza",
                       circuitName: "Autodromo Nazionale Monza", circuitLengthKm: 5.793, laps: 53,
                       isSprint: false, timeTemplate: .europe),
        RaceDefinition(id: "azerbaijan", round: 16, name: "Azerbaijan Grand Prix", shortName: "Azerbaijan",
                       countryFlag: "🇦🇿", countryName: "Azerbaijan", locality: "Baku",
                       circuitName: "Baku City Circuit", circuitLengthKm: 6.003, laps: 51,
                       isSprint: false, timeTemplate: .middleEast),
        RaceDefinition(id: "singapore", round: 17, name: "Singapore Grand Prix", shortName: "Singapore",
                       countryFlag: "🇸🇬", countryName: "Singapore", locality: "Marina Bay",
                       circuitName: "Marina Bay Street Circuit", circuitLengthKm: 4.940, laps: 62,
                       isSprint: false, timeTemplate: .asia),
        RaceDefinition(id: "unitedstates", round: 18, name: "United States Grand Prix", shortName: "United States",
                       countryFlag: "🇺🇸", countryName: "United States", locality: "Austin",
                       circuitName: "Circuit of the Americas", circuitLengthKm: 5.513, laps: 56,
                       isSprint: true, timeTemplate: .americas),
        RaceDefinition(id: "mexico", round: 19, name: "Mexico City Grand Prix", shortName: "Mexico City",
                       countryFlag: "🇲🇽", countryName: "Mexico", locality: "Mexico City",
                       circuitName: "Autódromo Hermanos Rodríguez", circuitLengthKm: 4.304, laps: 71,
                       isSprint: false, timeTemplate: .americas),
        RaceDefinition(id: "brazil", round: 20, name: "São Paulo Grand Prix", shortName: "Brazil",
                       countryFlag: "🇧🇷", countryName: "Brazil", locality: "São Paulo",
                       circuitName: "Autódromo José Carlos Pace", circuitLengthKm: 4.309, laps: 71,
                       isSprint: false, timeTemplate: .americas),
        RaceDefinition(id: "lasvegas", round: 21, name: "Las Vegas Grand Prix", shortName: "Las Vegas",
                       countryFlag: "🇺🇸", countryName: "United States", locality: "Las Vegas",
                       circuitName: "Las Vegas Strip Circuit", circuitLengthKm: 6.201, laps: 50,
                       isSprint: false, timeTemplate: .vegas),
        RaceDefinition(id: "qatar", round: 22, name: "Qatar Grand Prix", shortName: "Qatar",
                       countryFlag: "🇶🇦", countryName: "Qatar", locality: "Lusail",
                       circuitName: "Lusail International Circuit", circuitLengthKm: 5.419, laps: 57,
                       isSprint: true, timeTemplate: .middleEast),
        RaceDefinition(id: "madrid", round: 23, name: "Madrid Grand Prix", shortName: "Madrid",
                       countryFlag: "🇪🇸", countryName: "Spain", locality: "Madrid",
                       circuitName: "Madring", circuitLengthKm: 5.474, laps: 57,
                       isSprint: false, timeTemplate: .europe),
        RaceDefinition(id: "abudhabi", round: 24, name: "Abu Dhabi Grand Prix", shortName: "Abu Dhabi",
                       countryFlag: "🇦🇪", countryName: "United Arab Emirates", locality: "Abu Dhabi",
                       circuitName: "Yas Marina Circuit", circuitLengthKm: 5.281, laps: 58,
                       isSprint: false, timeTemplate: .middleEast),
    ]

    private static let driverSkill: [String: Double] = [
        "norris": 0.96, "piastri": 0.95, "verstappen": 0.96,
        "leclerc": 0.92, "russell": 0.91, "hamilton": 0.90,
        "antonelli": 0.87, "alonso": 0.87, "sainz": 0.86,
        "hadjar": 0.84, "albon": 0.84, "gasly": 0.82,
        "lawson": 0.81, "bearman": 0.81, "ocon": 0.80,
        "hulkenberg": 0.80, "bortoleto": 0.79, "perez": 0.78,
        "stroll": 0.77, "bottas": 0.77, "colapinto": 0.76,
        "lindblad": 0.75,
    ]

    private static let constructorStrength: [String: Double] = [
        "mclaren": 0.96, "redbull": 0.92, "ferrari": 0.90, "mercedes": 0.89,
        "astonmartin": 0.82, "williams": 0.81, "racingbulls": 0.79,
        "alpine": 0.76, "haas": 0.75, "audi": 0.73, "cadillac": 0.68,
    ]
}
