import WidgetKit
import SwiftUI

/// Timeline entry pointing at one upcoming session.
struct NextRaceEntry: TimelineEntry {
    let date: Date
    let race: Race?
    let session: RaceSession?
    let isLive: Bool
    let favoriteDriverCodes: [String]
}

/// Supplies entries for the next three sessions, then asks for a reload.
struct NextRaceProvider: TimelineProvider {

    func placeholder(in context: Context) -> NextRaceEntry {
        entry(at: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (NextRaceEntry) -> Void) {
        completion(entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextRaceEntry>) -> Void) {
        let now = Date()
        var entries: [NextRaceEntry] = []

        // One entry per upcoming session (max 3), rendered with a countdown
        // captured at the entry date so the widget stays honest between reloads.
        let upcoming = upcomingSessions(after: now).prefix(3)
        for session in upcoming {
            let entryDate = max(now, session.startDate.addingTimeInterval(-6 * 3600))
            entries.append(entry(at: entryDate, session: session))
        }
        if entries.isEmpty {
            entries.append(entry(at: now))
        }

        let reloadDate = entries.last?.session?.effectiveEndDate ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }

    // MARK: - Data

    private func entry(at date: Date, session: RaceSession? = nil) -> NextRaceEntry {
        let factory = MockSeasonFactory.shared
        let selection: NextSessionSelector.Selection?
        if let session {
            let race = factory.season.races.first { $0.id == session.raceID }
            selection = race.map { NextSessionSelector.Selection(race: $0, session: session, isLive: false) }
        } else {
            selection = NextSessionSelector.select(in: factory.season.races, at: date)
        }

        var codes: [String] = []
        if let teamID = UserDefaults.pitwallFavorites().favoriteConstructorID {
            codes = MockRoster.drivers
                .filter { $0.constructorID == teamID }
                .map { $0.code }
        }
        if codes.isEmpty {
            codes = Array(factory.driverStandings.prefix(2)).map { $0.driver.code }
        }

        return NextRaceEntry(
            date: date,
            race: selection?.race,
            session: selection?.session,
            isLive: selection?.isLive ?? false,
            favoriteDriverCodes: Array(codes.prefix(2))
        )
    }

    private func upcomingSessions(after now: Date) -> [RaceSession] {
        MockSeasonFactory.shared.season.racesInRoundOrder
            .flatMap { $0.sessionsInOrder }
            .filter { $0.state(at: now) != .completed }
    }
}

/// Next Race widget: countdown to the next session, favorite codes beneath.
struct NextRaceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.pitwallapp.widgets.NextRace", provider: NextRaceProvider()) { entry in
            NextRaceWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Race")
        .description("Countdown to the next Formula 1 session.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NextRaceWidgetView: View {
    let entry: NextRaceEntry

    var body: some View {
        Group {
            if let race = entry.race, let session = entry.session {
                content(race: race, session: session)
            } else {
                emptyContent
            }
        }
        .pwWidgetBackground()
        .widgetURL(URL(string: "pitwall://race/\(entry.race?.id ?? "home")"))
    }

    private func content(race: Race, session: RaceSession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("NEXT RACE")
                    .font(WidgetType.label)
                    .kerning(1.2)
                    .foregroundStyle(PWColors.accent)
                Spacer()
                Text(race.countryFlag)
                    .font(WidgetType.caption)
            }

            Text(race.shortName.uppercased() + " GP")
                .font(WidgetType.title)
                .foregroundStyle(PWColors.textPrimary)
                .lineLimit(1)

            Text(session.type.displayName.uppercased())
                .font(WidgetType.label)
                .kerning(1.0)
                .foregroundStyle(PWColors.textTertiary)

            Spacer(minLength: 0)

            if entry.isLive {
                Text("LIVE NOW")
                    .font(WidgetType.countdown)
                    .foregroundStyle(PWColors.live)
            } else {
                Text(countdownText(session))
                    .font(WidgetType.countdown)
                    .monospacedDigit()
                    .foregroundStyle(PWColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            if familyShowsExtras {
                Divider()
                    .overlay(PWColors.separator)
                HStack(spacing: 4) {
                    Text(entry.favoriteDriverCodes.joined(separator: " • "))
                        .font(WidgetType.caption)
                        .monospacedDigit()
                        .foregroundStyle(PWColors.textSecondary)
                    Spacer()
                    Text(PitWallDate.timeString(from: session.startDate))
                        .font(WidgetType.caption)
                        .monospacedDigit()
                        .foregroundStyle(PWColors.textTertiary)
                }
            }
        }
        .padding(2)
    }

    private var familyShowsExtras: Bool {
        // Extra rows fit the medium family; the small family stays tight.
        entry.favoriteDriverCodes.count == 2 && countdownText(entry.session!).count < 12
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NEXT RACE")
                .font(WidgetType.label)
                .kerning(1.2)
                .foregroundStyle(PWColors.accent)
            Spacer()
            Text("Season complete")
                .font(WidgetType.title)
                .foregroundStyle(PWColors.textPrimary)
            Text("New season data is on its way.")
                .font(WidgetType.caption)
                .foregroundStyle(PWColors.textTertiary)
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func countdownText(_ session: RaceSession) -> String {
        guard let components = CountdownCalculator.components(from: entry.date, to: session.startDate) else {
            return "STARTING"
        }
        return CountdownFormatter.short(components)
    }
}

#Preview("Next Race – Small", as: .systemSmall) {
    NextRaceWidget()
} timeline: {
    NextRaceEntry(date: .now,
                  race: MockSeasonFactory.shared.season.races.first { $0.id == "singapore" },
                  session: MockSeasonFactory.shared.season.races.first { $0.id == "singapore" }?.sessions.first { $0.type == .qualifying },
                  isLive: false,
                  favoriteDriverCodes: ["NOR", "PIA"])
}
