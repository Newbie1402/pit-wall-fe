import SwiftUI

/// Card container for content blocks.
struct PWCard<Content: View>: View {
    var padding: CGFloat = PWSpacing.md
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .pwCardBackground()
    }
}

/// Uppercase section title with optional trailing action.
struct SectionHeaderView: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            PWTypography.SectionLabel(text: title)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle.uppercased())
                        .font(PWTypography.captionBold)
                        .foregroundStyle(PWColors.accent)
                }
                .accessibilityLabel(actionTitle)
            }
        }
    }
}

/// Small pill label, e.g. "NEXT", "ROUND 17", "LIVE".
struct PWTag: View {
    let text: String
    var color: Color = PWColors.accent
    var filled = true

    var body: some View {
        Text(text.uppercased())
            .font(PWTypography.microCaps)
            .kerning(1.0)
            .foregroundStyle(filled ? Color.black : color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(filled ? color : color.opacity(0.16))
            )
    }
}

/// Circular championship/finishing position badge.
struct PositionBadge: View {
    let position: Int
    var color: Color = PWColors.textSecondary

    var body: some View {
        Text("P\(position)")
            .font(PWTypography.captionBold)
            .foregroundStyle(color)
            .frame(width: 34, height: 34)
            .background(
                Circle().fill(color.opacity(0.14))
            )
            .accessibilityLabel("Position \(position)")
    }
}

#Preview("DS Components") {
    VStack(spacing: 16) {
        SectionHeaderView(title: "This Weekend", actionTitle: "See all", action: {})
        SectionHeaderView(title: "Latest")
        HStack {
            PWTag(text: "Next")
            PWTag(text: "Live", color: PWColors.live)
            PWTag(text: "Sprint Weekend", color: PWColors.textSecondary, filled: false)
        }
        HStack {
            PositionBadge(position: 1, color: PWColors.gold)
            PositionBadge(position: 7)
        }
        PWCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("Card Title").font(PWTypography.cardTitle)
                Text("Supporting text").font(PWTypography.body).foregroundStyle(PWColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .padding()
    .background(PWColors.background)
}
