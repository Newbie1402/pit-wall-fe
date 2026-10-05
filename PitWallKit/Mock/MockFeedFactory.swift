import Foundation

/// Generates the personalized mock feed.
///
/// Items are provider-agnostic (no social-network-specific fields). Most items
/// use the styled placeholder image; a couple reference remote URLs so the
/// AsyncImage failure path stays exercised.
enum MockFeedFactory {

    struct Template {
        let source: String
        let sourceType: FeedSourceType
        let teamID: String?
        let driverID: String?
        let title: String
        let caption: String?
        let hoursAgo: Double
        let remoteImage: Bool
    }

    static func makeFeed(now: Date = Date()) -> [FeedItem] {
        let templates: [Template] = [
            Template(source: "McLaren", sourceType: .team, teamID: "mclaren", driverID: nil,
                     title: "Race week. Singapore lights are waiting 🇸🇬",
                     caption: "Papaya lands in Marina Bay. Set-up notes, tyre decks and night-run prep are done.",
                     hoursAgo: 1.5, remoteImage: false),
            Template(source: "Lando Norris", sourceType: .driver, teamID: "mclaren", driverID: "norris",
                     title: "See you under the lights, Marina Bay 🌃",
                     caption: "Honestly my favourite lap of the year. The wall never blinks.",
                     hoursAgo: 2, remoteImage: false),
            Template(source: "F1 Insider", sourceType: .official, teamID: nil, driverID: nil,
                     title: "Title fight: 3 drivers, 8 rounds, one crown",
                     caption: "The 2026 run-in begins in Singapore. Here is the state of play.",
                     hoursAgo: 3, remoteImage: false),
            Template(source: "Red Bull Racing", sourceType: .team, teamID: "redbull", driverID: nil,
                     title: "High downforce, high stakes.",
                     caption: "RB21 low-speed package debuts this weekend.",
                     hoursAgo: 4.5, remoteImage: false),
            Template(source: "Charles Leclerc", sourceType: .driver, teamID: "ferrari", driverID: "leclerc",
                     title: "Preparing for Singapore 🇸🇬",
                     caption: "Neck training doubled. This place is a sauna at 200 km/h.",
                     hoursAgo: 5, remoteImage: false),
            Template(source: "Ferrari", sourceType: .team, teamID: "ferrari", driverID: nil,
                     title: "Scuderia arrives in Singapore 🇸🇬",
                     caption: "Ninety laps of precision. Maranello's night shift begins.",
                     hoursAgo: 6, remoteImage: false),
            Template(source: "F1 Insider", sourceType: .official, teamID: nil, driverID: nil,
                     title: "How Baku was won: Norris' out-lap masterclass",
                     caption: "Telemetry deep-dive on the lap that settled Azerbaijan.",
                     hoursAgo: 9, remoteImage: true),
            Template(source: "George Russell", sourceType: .driver, teamID: "mercedes", driverID: "russell",
                     title: "Baku P2. Points banked. Next.",
                     caption: "Pit wall called it perfectly. Singapore, we're coming for you.",
                     hoursAgo: 11, remoteImage: false),
            Template(source: "Mercedes-AMG", sourceType: .team, teamID: "mercedes", driverID: nil,
                     title: "Silver Arrows land in Asia ✈️",
                     caption: "Freight arrived in Singapore this morning. Build starts tonight.",
                     hoursAgo: 13, remoteImage: false),
            Template(source: "Aston Martin", sourceType: .team, teamID: "astonmartin", driverID: nil,
                     title: "Green meanies in the Lion City 🇸🇬",
                     caption: "Fernando: \"Singapore always delivers chaos. I like it.\"",
                     hoursAgo: 16, remoteImage: false),
            Template(source: "Max Verstappen", sourceType: .driver, teamID: "redbull", driverID: "verstappen",
                     title: "Sim block done. 62 laps of Marina Bay.",
                     caption: "Traction out of the last sector decides your Sunday. Getting there.",
                     hoursAgo: 19, remoteImage: false),
            Template(source: "Audi F1 Team", sourceType: .team, teamID: "audi", driverID: nil,
                     title: "First night race for the Audi project",
                     caption: "Nico's 200th Grand Prix weekend approaches.",
                     hoursAgo: 22, remoteImage: false),
            Template(source: "F1 Insider", sourceType: .official, teamID: nil, driverID: nil,
                     title: "Watch: top 10 overtakes of the season so far",
                     caption: "Ten minutes of pure commitment.",
                     hoursAgo: 26, remoteImage: true),
            Template(source: "Oscar Piastri", sourceType: .driver, teamID: "mclaren", driverID: "piastri",
                     title: "Back home between flyaways 🇦🇺",
                     caption: "Reset, surf, sim. Singapore is a mental race — arrive fresh.",
                     hoursAgo: 30, remoteImage: false),
            Template(source: "Williams Racing", sourceType: .team, teamID: "williams", driverID: nil,
                     title: "Cooling systems: checked. Night ops: ready.",
                     caption: "Singapore's humidity is the silent rival.",
                     hoursAgo: 34, remoteImage: false),
            Template(source: "F1 Insider", sourceType: .official, teamID: nil, driverID: nil,
                     title: "Grid guide: who's under pressure in the run-in?",
                     caption: "Contract chess and second-seat maths, explained.",
                     hoursAgo: 38, remoteImage: false),
        ]

        return templates.enumerated().map { index, template in
            FeedItem(
                id: "feed-\(index)",
                source: template.source,
                sourceType: template.sourceType,
                teamID: template.teamID,
                driverID: template.driverID,
                title: template.title,
                caption: template.caption,
                imageURL: template.remoteImage ? URL(string: "https://mock.pitwall.app/images/\(index).jpg") : nil,
                externalURL: URL(string: "https://mock.pitwall.app/posts/\(index)"),
                publishedAt: now.addingTimeInterval(-template.hoursAgo * 3600)
            )
        }
    }
}
