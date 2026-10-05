import SwiftUI

/// "THIS WEEKEND" — session rows for the upcoming race weekend.
struct WeekendScheduleSection: View {
    let race: Race

    var body: some View {
        VStack(spacing: PWSpacing.xs) {
            ForEach(race.sessionsInOrder) { session in
                row(for: session)
            }
        }
        .pwCardBackground()
    }

    private func row(for session: RaceSession) -> some View {
        HStack(spacing: PWSpacing.md) {
            Text(session.type.shortName)
                .font(PWTypography.captionBold)
                .monospacedDigit()
                .foregroundStyle(PWColors.textSecondary)
                .frame(width: 42, alignment: .leading)

            Text(session.type.displayName)
                .font(PWTypography.bodyMedium)
                .foregroundStyle(PWColors.textPrimary)

            Spacer()

            if session.state(at: Date()) == .live {
                SessionStateBadge(state: .live)
            } else {
                Text(PitWallDate.weekdayDayMonthString(from: session.startDate))
                    .font(PWTypography.caption)
                    .monospacedDigit()
                    .foregroundStyle(PWColors.textTertiary)
                Text(PitWallDate.timeString(from: session.startDate))
                    .font(PWTypography.captionBold)
                    .monospacedDigit()
                    .foregroundStyle(PWColors.textPrimary)
            }
        }
        .padding(.horizontal, PWSpacing.md)
        .padding(.vertical, PWSpacing.sm)
        .accessibilityElement(children: .combine)
    }
}

/// "MY DRIVERS" — horizontal rail of favorite driver cards.
struct MyDriversSection: View {
    let drivers: [HomeViewModel.MyDriver]
    let onEmptyAction: () -> Void

    var body: some View {
        if drivers.isEmpty {
            PWEmptyStateView(
                icon: "person.crop.circle.badge.questionmark",
                title: "No favorites yet",
                message: "Follow drivers to get their results, form and news here.",
                actionTitle: "Choose Favorites",
                action: onEmptyAction
            )
            .pwCardBackground()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PWSpacing.sm) {
                    ForEach(drivers) { myDriver in
                        NavigationLink(value: AppRoute.driver(myDriver.driver.id)) {
                            DriverCard(
                                driver: myDriver.driver,
                                constructor: myDriver.constructor,
                                standing: myDriver.standing,
                                lastRaceResult: myDriver.lastResult
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, PWSpacing.screenPadding)
                .padding(.vertical, 2)
            }
            .padding(.horizontal, -PWSpacing.screenPadding)
        }
    }
}

/// "LATEST" — top personalized feed cards.
struct LatestFeedSection: View {
    let items: [FeedItem]
    let constructors: [Constructor]
    let onEmptyAction: () -> Void

    var body: some View {
        if items.isEmpty {
            PWEmptyStateView(
                icon: "newspaper",
                title: "Nothing here yet",
                message: "News and highlights from your favorites will appear here."
            )
            .pwCardBackground()
        } else {
            VStack(spacing: PWSpacing.sm) {
                ForEach(items.prefix(3)) { item in
                    NavigationLink(value: AppRoute.driver(item.driverID ?? "")) {
                        FeedCardView(item: item, tint: tint(for: item))
                    }
                    .buttonStyle(.plain)
                    .disabled(item.driverID == nil)
                }
            }
        }
    }

    private func tint(for item: FeedItem) -> Color {
        guard let teamID = item.teamID,
              let constructor = constructors.first(where: { $0.id == teamID }) else {
            return PWColors.accent
        }
        return TeamPalette.color(for: constructor)
    }
}
