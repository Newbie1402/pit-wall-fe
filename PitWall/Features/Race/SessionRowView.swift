import SwiftUI

/// One session of a race weekend: local date/time, state, reminder bell, and
/// results (top 3) when the session is completed.
struct SessionRowView: View {
    let session: RaceSession
    let race: Race
    let result: SessionResult?
    let isReminderSet: Bool
    let onToggleReminder: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: PWSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.type.displayName)
                        .font(PWTypography.bodyMedium)
                        .foregroundStyle(PWColors.textPrimary)
                    Text(rowDateString)
                        .font(PWTypography.caption)
                        .monospacedDigit()
                        .foregroundStyle(PWColors.textTertiary)
                }

                Spacer()

                SessionStateBadge(state: session.state(at: Date()))

                reminderButton
            }
            .padding(.horizontal, PWSpacing.md)
            .padding(.vertical, PWSpacing.sm)

            if let result, !result.entries.isEmpty {
                VStack(spacing: 0) {
                    ForEach(result.entries.prefix(3)) { entry in
                        ResultRowView(
                            entry: entry,
                            driver: MockRoster.driver(for: entry.driverID),
                            constructor: MockRoster.constructor(for: entry.constructorID)
                        )
                        .padding(.horizontal, PWSpacing.md)
                    }
                }
                .padding(.bottom, PWSpacing.sm)
            }
        }
        .background(session.state(at: Date()) == .live ? PWColors.surfaceElevated : .clear)
    }

    private var rowDateString: String {
        let day = PitWallDate.weekdayDayMonthString(from: session.startDate)
        let time = PitWallDate.timeString(from: session.startDate)
        return "\(day) • \(time)"
    }

    private var reminderButton: some View {
        Button(action: onToggleReminder) {
            Image(systemName: isReminderSet ? "bell.fill" : "bell")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isReminderSet ? PWColors.accent : PWColors.textTertiary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(PWColors.surfaceSunken))
        }
        .buttonStyle(.plain)
        .disabled(session.state(at: Date()) == .completed)
        .accessibilityLabel(isReminderSet ? "Remove reminder for \(session.type.displayName)" : "Remind me about \(session.type.displayName)")
    }
}
