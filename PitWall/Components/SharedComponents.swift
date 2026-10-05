import SwiftUI

/// Colored bar marking a driver's or team's constructor color.
struct TeamColorBar: View {
    let color: Color
    var height: CGFloat = 18

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color)
            .frame(width: 4, height: height)
            .accessibilityHidden(true)
    }
}

/// Chip for a finishing position, colored by result class:
/// win, podium, points, no points, or DNF.
struct FormChip: View {
    let position: Int?
    let status: String?

    init(position: Int? = nil, status: String? = nil) {
        self.position = position
        self.status = status
    }

    private var label: String {
        if let status, !status.isEmpty { return status }
        return PWFormat.position(position)
    }

    private var tint: Color {
        if let status, !status.isEmpty { return PWColors.live }
        switch position {
        case 1: return PWColors.gold
        case 2...3: return PWColors.accent
        case 4...10: return PWColors.textSecondary
        default: return PWColors.textTertiary
        }
    }

    var body: some View {
        Text(label)
            .font(PWTypography.captionBold)
            .foregroundStyle(Color.black)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(tint))
            .accessibilityLabel(position.map { "Finished \($0)" } ?? (status ?? "Not classified"))
    }
}

/// Session state pill: LIVE / UPCOMING / COMPLETE.
struct SessionStateBadge: View {
    let state: SessionState

    var body: some View {
        switch state {
        case .live:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.black)
                    .frame(width: 5, height: 5)
                Text("LIVE")
            }
            .font(PWTypography.microCaps)
            .kerning(1.0)
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(PWColors.live))
        case .upcoming:
            Text("UPCOMING")
                .font(PWTypography.microCaps)
                .kerning(1.0)
                .foregroundStyle(PWColors.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(PWColors.accentSoft))
        case .completed:
            Text("COMPLETE")
                .font(PWTypography.microCaps)
                .kerning(1.0)
                .foregroundStyle(PWColors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(PWColors.surfaceSunken))
        }
    }
}

/// Square stat tile used in detail screens.
struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: PWSpacing.xxs) {
            Text(value)
                .font(PWTypography.statValue)
                .foregroundStyle(PWColors.textPrimary)
                .monospacedDigit()
            Text(label.uppercased())
                .font(PWTypography.microCaps)
                .kerning(1.2)
                .foregroundStyle(PWColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PWSpacing.md)
        .pwCardBackground(color: PWColors.surfaceSunken, radius: PWRadius.md)
    }
}

/// Gradient placeholder for feed imagery until remote images arrive.
struct FeedImagePlaceholder: View {
    let sourceType: FeedSourceType
    let tint: Color

    private var symbol: String {
        switch sourceType {
        case .official: return "flag.checkered"
        case .team: return "car.front.waves.up"
        case .driver: return "helmet.fill"
        case .media: return "camera.fill"
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [tint.opacity(0.55), tint.opacity(0.12), PWColors.surfaceElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .accessibilityHidden(true)
    }
}

/// A classified result row.
struct ResultRowView: View {
    let entry: ResultEntry
    let driver: Driver?
    let constructor: Constructor?

    var body: some View {
        HStack(spacing: PWSpacing.sm) {
            Text(PWFormat.ordinal(entry.position))
                .font(PWTypography.rowTitle)
                .monospacedDigit()
                .foregroundStyle(entry.position == 1 ? PWColors.gold : PWColors.textSecondary)
                .frame(width: 26, alignment: .leading)

            TeamColorBar(color: constructor.map { TeamPalette.color(for: $0) } ?? PWColors.textTertiary)

            Text(driver?.fullName ?? entry.driverID)
                .font(PWTypography.rowTitle)
                .foregroundStyle(PWColors.textPrimary)

            Spacer()

            if let status = entry.status {
                Text(status)
                    .font(PWTypography.captionBold)
                    .foregroundStyle(PWColors.live)
            } else {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(entry.gapToWinner ?? "WINNER")
                        .font(PWTypography.caption)
                        .monospacedDigit()
                        .foregroundStyle(PWColors.textTertiary)
                    if entry.points > 0 {
                        Text(PWFormat.points(entry.points))
                            .font(PWTypography.captionBold)
                            .monospacedDigit()
                            .foregroundStyle(PWColors.textSecondary)
                    }
                }
            }
        }
        .padding(.vertical, PWSpacing.xs)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Components") {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            FormChip(position: 1)
            FormChip(position: 3)
            FormChip(position: 9)
            FormChip(status: "DNF")
        }
        SessionStateBadge(state: .live)
        SessionStateBadge(state: .upcoming)
        SessionStateBadge(state: .completed)
        ResultRowView(
            entry: ResultEntry(position: 2, driverID: "verstappen", constructorID: "redbull",
                               gapToWinner: "+5.321s", points: 18, status: nil),
            driver: MockRoster.driver(for: "verstappen"),
            constructor: MockRoster.constructor(for: "redbull")
        )
        FeedImagePlaceholder(sourceType: .team, tint: ColorHex.color("#FF8000"))
            .frame(height: 90)
    }
    .padding()
    .background(PWColors.background)
}
