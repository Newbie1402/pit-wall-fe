import SwiftUI

/// Calendar card. Upcoming weekends show the date range and circuit;
/// completed weekends show the winner. The next race gets a "NEXT" tag.
struct RaceCardView: View {
    let race: Race
    let isNext: Bool
    let winnerName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PWSpacing.sm) {
            HStack(spacing: PWSpacing.xs) {
                Text("ROUND \(race.round)")
                    .font(PWTypography.microCaps)
                    .kerning(1.6)
                    .foregroundStyle(PWColors.textTertiary)
                Spacer()
                if isNext {
                    PWTag(text: "Next")
                } else if race.isSprintWeekend {
                    PWTag(text: "Sprint", color: PWColors.textSecondary, filled: false)
                }
            }

            HStack(spacing: PWSpacing.sm) {
                Text(race.countryFlag)
                    .font(.system(size: 26))
                VStack(alignment: .leading, spacing: 1) {
                    Text(race.shortName.uppercased() + " GP")
                        .font(PWTypography.cardTitle)
                        .foregroundStyle(PWColors.textPrimary)
                    Text(race.locality)
                        .font(PWTypography.caption)
                        .foregroundStyle(PWColors.textSecondary)
                }
                Spacer()
            }

            if race.state(at: Date()) == .completed {
                if let winnerName {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WINNER")
                            .font(PWTypography.microCaps)
                            .kerning(1.6)
                            .foregroundStyle(PWColors.gold)
                        Text(winnerName)
                            .font(PWTypography.rowTitle)
                            .foregroundStyle(PWColors.textPrimary)
                    }
                }
                HStack(spacing: PWSpacing.xxs) {
                    Text("RESULTS")
                        .font(PWTypography.captionBold)
                        .kerning(1.2)
                        .foregroundStyle(PWColors.accent)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(PWColors.accent)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(PitWallDate.dateRangeString(from: window.start, to: window.end))
                        .font(PWTypography.captionBold)
                        .monospacedDigit()
                        .foregroundStyle(PWColors.textPrimary)
                    Text(race.circuit.name)
                        .font(PWTypography.caption)
                        .foregroundStyle(PWColors.textTertiary)
                }
            }
        }
        .padding(PWSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pwCardBackground(color: isNext ? PWColors.surfaceElevated : PWColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: PWRadius.lg, style: .continuous)
                .strokeBorder(isNext ? PWColors.accent.opacity(0.5) : .clear, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var window: (start: Date, end: Date) {
        race.weekendWindow() ?? (Date(), Date())
    }

    private var accessibilitySummary: String {
        var parts = ["Round \(race.round)", race.name]
        if race.state(at: Date()) == .completed {
            if let winnerName { parts.append("Winner \(winnerName)") }
        } else {
            parts.append(PitWallDate.dateRangeString(from: window.start, to: window.end))
        }
        return parts.joined(separator: ", ")
    }
}

#Preview("RaceCard") {
    let factory = MockSeasonFactory.shared
    let singapore = factory.season.races.first { $0.id == "singapore" }!
    return VStack(spacing: 12) {
        RaceCardView(race: singapore, isNext: true, winnerName: nil)
        RaceCardView(race: factory.season.races.first { $0.id == "italy" }!,
                     isNext: false, winnerName: "Lando Norris")
    }
    .padding()
    .background(PWColors.background)
}
