import Foundation

/// A Formula 1 driver on the current grid.
struct Driver: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    /// Three-letter timing code, e.g. "NOR".
    let code: String
    let firstName: String
    let lastName: String
    /// Permanent car number.
    let number: Int
    let constructorID: String
    /// Country emoji flag.
    let countryFlag: String

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    /// Name formatted for dense layouts: "L. NORRIS".
    var shortName: String {
        "\(firstName.prefix(1)). \(lastName.uppercased())"
    }
}

/// A Formula 1 constructor (team).
struct Constructor: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    /// Short name for dense layouts, e.g. "McLaren".
    let shortName: String
    /// Brand color used across the app, e.g. "#FF8000".
    let colorHex: String
    let countryFlag: String
}
