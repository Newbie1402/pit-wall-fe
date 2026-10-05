import Foundation

/// A Formula 1 season and its race weekends.
struct Season: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let year: Int
    let races: [Race]

    /// Races ordered by round number.
    var racesInRoundOrder: [Race] {
        races.sorted { $0.round < $1.round }
    }

    /// The race weekend currently in progress or the next one to come.
    func nextRace(after now: Date) -> Race? {
        racesInRoundOrder.first { $0.state(at: now) != .completed }
    }
}

/// One race weekend, composed of the sessions that make it up.
struct Race: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let seasonID: String
    let round: Int
    /// Official event name, e.g. "Singapore Grand Prix".
    let name: String
    /// Short name used on cards, e.g. "Singapore".
    let shortName: String
    /// Country emoji flag, e.g. "🇸🇬".
    let countryFlag: String
    let countryName: String
    let locality: String
    let circuit: Circuit
    let sessions: [RaceSession]

    var isSprintWeekend: Bool {
        sessions.contains { $0.type == .sprint }
    }

    /// All sessions ordered chronologically.
    var sessionsInOrder: [RaceSession] {
        sessions.sorted { $0.startDate < $1.startDate }
    }

    /// The race session itself.
    var raceSession: RaceSession? {
        sessions.first { $0.type == .race }
    }

    /// First session start and last session end, defining the weekend window.
    func weekendWindow() -> (start: Date, end: Date)? {
        let ordered = sessionsInOrder
        guard let first = ordered.first, let last = ordered.last else { return nil }
        return (first.startDate, last.effectiveEndDate)
    }

    func state(at now: Date) -> RaceState {
        guard let window = weekendWindow() else { return .upcoming }
        if now > window.end { return .completed }
        if now >= window.start { return .inProgress }
        return .upcoming
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Race, rhs: Race) -> Bool {
        lhs.id == rhs.id
    }
}

enum RaceState: Equatable, Sendable {
    case upcoming
    case inProgress
    case completed
}

struct Circuit: Codable, Equatable, Sendable, Hashable {
    let id: String
    let name: String
    /// Circuit length in kilometres, when known.
    let lengthKilometers: Double?
    /// Number of laps of the race, when known.
    let laps: Int?
}

enum SessionType: String, Codable, CaseIterable, Sendable, Equatable {
    case practice1
    case practice2
    case practice3
    case sprintQualifying
    case sprint
    case qualifying
    case race

    var displayName: String {
        switch self {
        case .practice1: return "Practice 1"
        case .practice2: return "Practice 2"
        case .practice3: return "Practice 3"
        case .sprintQualifying: return "Sprint Qualifying"
        case .sprint: return "Sprint"
        case .qualifying: return "Qualifying"
        case .race: return "Race"
        }
    }

    /// Compact label used in dense layouts, e.g. "FP1".
    var shortName: String {
        switch self {
        case .practice1: return "FP1"
        case .practice2: return "FP2"
        case .practice3: return "FP3"
        case .sprintQualifying: return "SQ"
        case .sprint: return "SPR"
        case .qualifying: return "QUA"
        case .race: return "RACE"
        }
    }

    /// Typical session duration, used when a backend does not provide an end date.
    var approximateDuration: TimeInterval {
        switch self {
        case .practice1, .practice2, .practice3: return 60 * 60
        case .sprintQualifying: return 45 * 60
        case .sprint: return 45 * 60
        case .qualifying: return 60 * 60
        case .race: return 2 * 60 * 60
        }
    }
}

enum SessionState: Equatable, Sendable {
    case upcoming
    case live
    case completed
}

/// A single session of a race weekend.
struct RaceSession: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let raceID: String
    let type: SessionType
    /// Session start, always UTC-based; display converts to local time.
    let startDate: Date
    /// Session end, when known. Falls back to start + approximate duration.
    let endDate: Date?

    init(id: String, raceID: String, type: SessionType, startDate: Date, endDate: Date? = nil) {
        self.id = id
        self.raceID = raceID
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
    }

    var effectiveEndDate: Date {
        endDate ?? startDate.addingTimeInterval(type.approximateDuration)
    }

    func state(at now: Date) -> SessionState {
        if now < startDate { return .upcoming }
        if now < effectiveEndDate { return .live }
        return .completed
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RaceSession, rhs: RaceSession) -> Bool {
        lhs.id == rhs.id
    }
}
