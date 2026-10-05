import SwiftUI

/// Home hero: the next relevant session with a live countdown, circuit and
/// local start time, plus the primary "Remind Me" action.
struct NextSessionHeroCard: View {
    let race: Race
    let session: RaceSession
    let isLive: Bool
    let isReminderSet: Bool
    let onToggleReminder: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PWSpacing.md) {
            // Header: flag + event name + round tag
            HStack(alignment: .top, spacing: PWSpacing.sm) {
                Text(race.countryFlag)
                    .font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text(race.name.withoutGrandPrixSuffix.uppercased() + " GP")
                        .font(PWTypography.cardTitleRounded)
                        .foregroundStyle(PWColors.textPrimary)
                    Text("ROUND \(race.round)")
                        .font(PWTypography.microCaps)
                        .kerning(1.6)
                        .foregroundStyle(PWColors.textTertiary)
                }
                Spacer()
                if race.isSprintWeekend {
                    PWTag(text: "Sprint", color: PWColors.textSecondary, filled: false)
                }
            }

            // Session line
            HStack(spacing: PWSpacing.xs) {
                Text(session.type.displayName.uppercased())
                    .font(PWTypography.sectionHeader)
                    .kerning(2.0)
                    .foregroundStyle(PWColors.textSecondary)
                if isLive {
                    SessionStateBadge(state: .live)
                }
            }
            .padding(.top, 2)

            // Countdown block
            VStack(alignment: .leading, spacing: PWSpacing.xxs) {
                Text(isLive ? "HAPPENING NOW" : "STARTS IN")
                    .font(PWTypography.microCaps)
                    .kerning(1.8)
                    .foregroundStyle(PWColors.textTertiary)

                if isLive {
                    Text("LIVE")
                        .font(PWTypography.countdown(44))
                        .foregroundStyle(PWColors.live)
                        .kerning(4)
                } else {
                    CountdownText(target: session.startDate)
                        .font(PWTypography.countdown(44))
                }
            }
            .padding(.vertical, PWSpacing.xs)

            // Circuit + local date
            VStack(alignment: .leading, spacing: 2) {
                Text(race.circuit.name.uppercased())
                    .font(PWTypography.captionBold)
                    .kerning(1.0)
                    .foregroundStyle(PWColors.textSecondary)
                Text(heroDateString)
                    .font(PWTypography.caption)
                    .monospacedDigit()
                    .foregroundStyle(PWColors.textTertiary)
            }

            PWButton(
                title: isReminderSet ? "Reminder Set" : "Remind Me",
                icon: isReminderSet ? "bell.fill" : "bell",
                style: isReminderSet ? .secondary : .primary,
                action: onToggleReminder
            )
            .accessibilityHint(isReminderSet ? "Double tap to remove the reminder" : "Double tap to set a reminder")
        }
        .padding(PWSpacing.lg)
        .pwCardBackground(color: PWColors.surfaceElevated)
        .accessibilityElement(children: .contain)
    }

    /// "10 OCT • 20:00" in the user's local timezone.
    private var heroDateString: String {
        let day = PitWallDate.dayMonthString(from: session.startDate)
        let time = PitWallDate.timeString(from: session.startDate)
        return "\(day) • \(time)"
    }
}

#Preview("Hero") {
    let factory = MockSeasonFactory.shared
    let race = factory.season.races.first { $0.id == "singapore" }!
    let session = race.sessions.first { $0.type == .qualifying }!
    return NextSessionHeroCard(race: race, session: session, isLive: false, isReminderSet: false) {}
        .padding()
        .background(PWColors.background)
}
