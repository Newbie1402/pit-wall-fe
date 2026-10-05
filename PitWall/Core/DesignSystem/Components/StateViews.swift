import SwiftUI

/// Reusable async UI states: loading, empty, error.
///
/// Every major screen renders one of these states through its `Loadable` data.
struct PWLoadingView: View {
    var message: String = "Loading…"

    var body: some View {
        VStack(spacing: PWSpacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(PWColors.accent)
            Text(message)
                .font(PWTypography.caption)
                .foregroundStyle(PWColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

struct PWEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: PWSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(PWColors.textTertiary)
                .padding(.bottom, PWSpacing.xxs)

            Text(title)
                .font(PWTypography.cardTitle)
                .foregroundStyle(PWColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(PWTypography.caption)
                .foregroundStyle(PWColors.textTertiary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                PWButton(title: actionTitle, style: .secondary, action: action)
                    .padding(.top, PWSpacing.xs)
            }
        }
        .padding(PWSpacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct PWErrorStateView: View {
    let message: String
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: PWSpacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(PWColors.live)

            Text("Something went wrong")
                .font(PWTypography.cardTitle)
                .foregroundStyle(PWColors.textPrimary)

            Text(message)
                .font(PWTypography.caption)
                .foregroundStyle(PWColors.textTertiary)
                .multilineTextAlignment(.center)

            if let retry {
                PWButton(title: "Try Again", style: .secondary, action: retry)
                    .padding(.top, PWSpacing.xs)
            }
        }
        .padding(PWSpacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview("States") {
    ScrollView {
        VStack(spacing: 24) {
            PWLoadingView(message: "Loading season…")
                .frame(height: 160)
            PWEmptyStateView(icon: "star.slash", title: "No favorites yet",
                             message: "Follow drivers to see them here.",
                             actionTitle: "Choose Favorites", action: {})
            PWErrorStateView(message: "The season could not be loaded.", retry: {})
        }
    }
    .background(PWColors.background)
}
