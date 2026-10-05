import Foundation

/// Championship table row for one driver.
struct DriverStanding: Codable, Identifiable, Equatable, Sendable {
    let position: Int
    let driver: Driver
    let constructor: Constructor
    let points: Int
    let wins: Int
    /// Points behind the championship leader. 0 for the leader.
    let pointsBehindLeader: Int

    var id: String { driver.id }
}

/// Championship table row for one constructor.
struct ConstructorStanding: Codable, Identifiable, Equatable, Sendable {
    let position: Int
    let constructor: Constructor
    let points: Int
    let wins: Int
    /// Points behind the championship leader. 0 for the leader.
    let pointsBehindLeader: Int

    var id: String { constructor.id }
}
