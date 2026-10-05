import Foundation

/// The 2026 mock grid: 11 constructors, 22 drivers.
///
/// Rosters and colors are representative mock data for the frontend only.
enum MockRoster {

    static let constructors: [Constructor] = [
        Constructor(id: "mclaren", name: "McLaren Formula 1 Team", shortName: "McLaren",
                    colorHex: "#FF8000", countryFlag: "🇬🇧"),
        Constructor(id: "ferrari", name: "Scuderia Ferrari", shortName: "Ferrari",
                    colorHex: "#E8002D", countryFlag: "🇮🇹"),
        Constructor(id: "redbull", name: "Oracle Red Bull Racing", shortName: "Red Bull",
                    colorHex: "#3671C6", countryFlag: "🇦🇹"),
        Constructor(id: "mercedes", name: "Mercedes-AMG Petronas", shortName: "Mercedes",
                    colorHex: "#27F4D2", countryFlag: "🇩🇪"),
        Constructor(id: "astonmartin", name: "Aston Martin Aramco", shortName: "Aston Martin",
                    colorHex: "#229971", countryFlag: "🇬🇧"),
        Constructor(id: "williams", name: "Atlassian Williams", shortName: "Williams",
                    colorHex: "#64C4FF", countryFlag: "🇬🇧"),
        Constructor(id: "racingbulls", name: "Visa Cash App Racing Bulls", shortName: "Racing Bulls",
                    colorHex: "#6692FF", countryFlag: "🇮🇹"),
        Constructor(id: "alpine", name: "BWT Alpine", shortName: "Alpine",
                    colorHex: "#FF87BC", countryFlag: "🇫🇷"),
        Constructor(id: "haas", name: "MoneyGram Haas", shortName: "Haas",
                    colorHex: "#B6BABD", countryFlag: "🇺🇸"),
        Constructor(id: "audi", name: "Audi F1 Team", shortName: "Audi",
                    colorHex: "#00E701", countryFlag: "🇩🇪"),
        Constructor(id: "cadillac", name: "Cadillac F1 Team", shortName: "Cadillac",
                    colorHex: "#C9A227", countryFlag: "🇺🇸"),
    ]

    static let drivers: [Driver] = [
        Driver(id: "norris", code: "NOR", firstName: "Lando", lastName: "Norris", number: 4,
               constructorID: "mclaren", countryFlag: "🇬🇧"),
        Driver(id: "piastri", code: "PIA", firstName: "Oscar", lastName: "Piastri", number: 81,
               constructorID: "mclaren", countryFlag: "🇦🇺"),
        Driver(id: "verstappen", code: "VER", firstName: "Max", lastName: "Verstappen", number: 1,
               constructorID: "redbull", countryFlag: "🇳🇱"),
        Driver(id: "hadjar", code: "HAD", firstName: "Isack", lastName: "Hadjar", number: 6,
               constructorID: "redbull", countryFlag: "🇫🇷"),
        Driver(id: "leclerc", code: "LEC", firstName: "Charles", lastName: "Leclerc", number: 16,
               constructorID: "ferrari", countryFlag: "🇲🇨"),
        Driver(id: "hamilton", code: "HAM", firstName: "Lewis", lastName: "Hamilton", number: 44,
               constructorID: "ferrari", countryFlag: "🇬🇧"),
        Driver(id: "russell", code: "RUS", firstName: "George", lastName: "Russell", number: 63,
               constructorID: "mercedes", countryFlag: "🇬🇧"),
        Driver(id: "antonelli", code: "ANT", firstName: "Kimi", lastName: "Antonelli", number: 12,
               constructorID: "mercedes", countryFlag: "🇮🇹"),
        Driver(id: "alonso", code: "ALO", firstName: "Fernando", lastName: "Alonso", number: 14,
               constructorID: "astonmartin", countryFlag: "🇪🇸"),
        Driver(id: "stroll", code: "STR", firstName: "Lance", lastName: "Stroll", number: 18,
               constructorID: "astonmartin", countryFlag: "🇨🇦"),
        Driver(id: "albon", code: "ALB", firstName: "Alex", lastName: "Albon", number: 23,
               constructorID: "williams", countryFlag: "🇹🇭"),
        Driver(id: "sainz", code: "SAI", firstName: "Carlos", lastName: "Sainz", number: 55,
               constructorID: "williams", countryFlag: "🇪🇸"),
        Driver(id: "lawson", code: "LAW", firstName: "Liam", lastName: "Lawson", number: 30,
               constructorID: "racingbulls", countryFlag: "🇳🇿"),
        Driver(id: "lindblad", code: "LIN", firstName: "Arvid", lastName: "Lindblad", number: 41,
               constructorID: "racingbulls", countryFlag: "🇬🇧"),
        Driver(id: "gasly", code: "GAS", firstName: "Pierre", lastName: "Gasly", number: 10,
               constructorID: "alpine", countryFlag: "🇫🇷"),
        Driver(id: "colapinto", code: "COL", firstName: "Franco", lastName: "Colapinto", number: 43,
               constructorID: "alpine", countryFlag: "🇦🇷"),
        Driver(id: "bearman", code: "BEA", firstName: "Oliver", lastName: "Bearman", number: 87,
               constructorID: "haas", countryFlag: "🇬🇧"),
        Driver(id: "ocon", code: "OCO", firstName: "Esteban", lastName: "Ocon", number: 31,
               constructorID: "haas", countryFlag: "🇫🇷"),
        Driver(id: "hulkenberg", code: "HUL", firstName: "Nico", lastName: "Hülkenberg", number: 27,
               constructorID: "audi", countryFlag: "🇩🇪"),
        Driver(id: "bortoleto", code: "BOR", firstName: "Gabriel", lastName: "Bortoleto", number: 5,
               constructorID: "audi", countryFlag: "🇧🇷"),
        Driver(id: "perez", code: "PER", firstName: "Sergio", lastName: "Pérez", number: 11,
               constructorID: "cadillac", countryFlag: "🇲🇽"),
        Driver(id: "bottas", code: "BOT", firstName: "Valtteri", lastName: "Bottas", number: 77,
               constructorID: "cadillac", countryFlag: "🇫🇮"),
    ]

    static func constructor(for id: String) -> Constructor? {
        constructors.first { $0.id == id }
    }

    static func driver(for id: String) -> Driver? {
        drivers.first { $0.id == id }
    }

    /// Constructor ID of a driver, from the roster.
    static func constructorID(forDriverID driverID: String) -> String? {
        driver(for: driverID)?.constructorID
    }
}
