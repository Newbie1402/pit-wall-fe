import SwiftUI

/// Favorite-driver card for Home's "MY DRIVERS" rail.
struct DriverCard: View {
    let driver: Driver
    let constructor: Constructor
    let standing: DriverStanding?
    let lastRaceResult: RaceWeekendResult?

    var body: some View {
        VStack(alignment: .leading, spacing: PWSpacing.sm) {
            HStack(spacing: PWSpacing.xs) {
                TeamColorBar(color: TeamPalette.color(for: constructor), height: 26)
                VStack(alignment: .leading, spacing: 0) {
                    Text(driver.code)
                        .font(PWTypography.cardTitleRounded)
                        .foregroundStyle(PWColors.textPrimary)
                    Text(driver.shortName)
                        .font(PWTypography.caption)
                        .foregroundStyle(PWColors.textTertiary)
                }
                Spacer()
                if let position = standing?.position {
                    Text(PWFormat.position(position))
                        .font(PWTypography.statValue)
                        .monospacedDigit()
                        .foregroundStyle(TeamPalette.color(for: constructor))
                }
            }

            Text(constructor.shortName)
                .font(PWTypography.caption)
                .foregroundStyle(PWColors.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(PWFormat.points(standing?.points ?? 0))
                    .font(PWTypography.rowTitle)
                    .monospacedDigit()
                    .foregroundStyle(PWColors.textPrimary)
                Text("CHAMPIONSHIP")
                    .font(PWTypography.microCaps)
                    .kerning(1.2)
                    .foregroundStyle(PWColors.textTertiary)
            }

            if let last = lastRaceResult {
                HStack(spacing: PWSpacing.xs) {
                    Text("LAST")
                        .font(PWTypography.microCaps)
                        .kerning(1.2)
                        .foregroundStyle(PWColors.textTertiary)
                    FormChip(position: last.racePosition, status: last.status)
                }
            }
        }
        .padding(PWSpacing.md)
        .frame(width: 158, alignment: .leading)
        .pwCardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        var parts = ["\(driver.fullName), \(constructor.shortName)"]
        if let standing {
            parts.append("Position \(standing.position), \(standing.points) points")
        }
        if let last = lastRaceResult {
            if let status = last.status {
                parts.append("Last race \(status)")
            } else if let position = last.racePosition {
                parts.append("Last race finished \(position)")
            }
        }
        return parts.joined(separator: ". ")
    }
}

#Preview("DriverCard") {
    HStack(spacing: 12) {
        DriverCard(
            driver: MockRoster.drivers[0],
            constructor: MockRoster.constructors[0],
            standing: DriverStanding(position: 1, driver: MockRoster.drivers[0],
                                     constructor: MockRoster.constructors[0], points: 331,
                                     wins: 7, pointsBehindLeader: 0),
            lastRaceResult: RaceWeekendResult(raceID: "azerbaijan", round: 16, raceName: "Azerbaijan Grand Prix",
                                              countryFlag: "🇦🇿", racePosition: 1, qualifyingPosition: 2,
                                              points: 25, status: nil)
        )
    }
    .padding()
    .background(PWColors.background)
}
