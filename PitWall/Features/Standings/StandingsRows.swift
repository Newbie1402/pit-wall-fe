import SwiftUI

/// Dense driver championship row for the standings table.
struct DriverStandingRow: View {
    let standing: DriverStanding
    let isFollowed: Bool

    var body: some View {
        HStack(spacing: PWSpacing.sm) {
            Text(PWFormat.ordinal(standing.position))
                .font(PWTypography.statValue)
                .monospacedDigit()
                .foregroundStyle(standing.position == 1 ? PWColors.gold : PWColors.textTertiary)
                .frame(width: 38, alignment: .leading)

            TeamColorBar(color: TeamPalette.color(for: standing.constructor), height: 30)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: PWSpacing.xxs) {
                    Text(standing.driver.fullName)
                        .font(PWTypography.rowTitle)
                        .foregroundStyle(PWColors.textPrimary)
                    if isFollowed {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(PWColors.accent)
                            .accessibilityLabel("Followed")
                    }
                }
                Text(standing.constructor.shortName)
                    .font(PWTypography.caption)
                    .foregroundStyle(PWColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(PWFormat.points(standing.points))
                    .font(PWTypography.rowTitle)
                    .monospacedDigit()
                    .foregroundStyle(PWColors.textPrimary)
                Text(PWFormat.gapLabel(behindLeader: standing.pointsBehindLeader))
                    .font(PWTypography.microCaps)
                    .monospacedDigit()
                    .foregroundStyle(PWColors.textTertiary)
            }
        }
        .padding(.horizontal, PWSpacing.md)
        .padding(.vertical, PWSpacing.sm)
        .contentShape(Rectangle())
        .background(isFollowed ? PWColors.accentSoft : .clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(standing.position). \(standing.driver.fullName), \(standing.constructor.shortName), \(standing.points) points")
    }
}

/// Dense constructor championship row for the standings table.
struct ConstructorStandingRow: View {
    let standing: ConstructorStanding
    let isFollowed: Bool

    var body: some View {
        HStack(spacing: PWSpacing.sm) {
            Text(PWFormat.ordinal(standing.position))
                .font(PWTypography.statValue)
                .monospacedDigit()
                .foregroundStyle(standing.position == 1 ? PWColors.gold : PWColors.textTertiary)
                .frame(width: 38, alignment: .leading)

            RoundedRectangle(cornerRadius: PWRadius.sm, style: .continuous)
                .fill(TeamPalette.color(for: standing.constructor))
                .frame(width: 6, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: PWSpacing.xxs) {
                    Text(standing.constructor.shortName)
                        .font(PWTypography.rowTitle)
                        .foregroundStyle(PWColors.textPrimary)
                    if isFollowed {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(PWColors.accent)
                            .accessibilityLabel("Followed")
                    }
                }
                Text("\(standing.wins) win\(standing.wins == 1 ? "" : "s")")
                    .font(PWTypography.caption)
                    .foregroundStyle(PWColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(PWFormat.points(standing.points))
                    .font(PWTypography.rowTitle)
                    .monospacedDigit()
                    .foregroundStyle(PWColors.textPrimary)
                Text(PWFormat.gapLabel(behindLeader: standing.pointsBehindLeader))
                    .font(PWTypography.microCaps)
                    .monospacedDigit()
                    .foregroundStyle(PWColors.textTertiary)
            }
        }
        .padding(.horizontal, PWSpacing.md)
        .padding(.vertical, PWSpacing.sm)
        .contentShape(Rectangle())
        .background(isFollowed ? PWColors.accentSoft : .clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(standing.position). \(standing.constructor.name), \(standing.points) points")
    }
}

#Preview("Standings Rows") {
    let factory = MockSeasonFactory.shared
    let drivers = factory.driverStandings
    let constructors = factory.constructorStandings
    return VStack(spacing: 0) {
        DriverStandingRow(standing: drivers[0], isFollowed: true)
        DriverStandingRow(standing: drivers[2], isFollowed: false)
        Divider()
        ConstructorStandingRow(standing: constructors[0], isFollowed: true)
        ConstructorStandingRow(standing: constructors[3], isFollowed: false)
    }
    .background(PWColors.background)
}
