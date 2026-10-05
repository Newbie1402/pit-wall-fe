import SwiftUI

/// Primary call-to-action button, e.g. "REMIND ME".
struct PWButton: View {
    let title: String
    var icon: String? = nil
    var style: Style = .primary
    var isLoading = false
    let action: () -> Void

    enum Style {
        case primary
        case secondary
        case subtle

        var background: Color {
            switch self {
            case .primary: return PWColors.accent
            case .secondary: return PWColors.surfaceElevated
            case .subtle: return PWColors.surfaceSunken
            }
        }

        var foreground: Color {
            switch self {
            case .primary: return .black
            default: return PWColors.textPrimary
            }
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: PWSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(style.foreground)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                }
                Text(title.uppercased())
                    .font(PWTypography.captionBold)
                    .kerning(1.1)
            }
            .foregroundStyle(style.foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: PWRadius.md, style: .continuous)
                    .fill(style.background)
            )
        }
        .disabled(isLoading)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("PWButton") {
    VStack(spacing: 12) {
        PWButton(title: "Remind Me", icon: "bell.fill") {}
        PWButton(title: "Add to Calendar", icon: "calendar.badge.plus", style: .secondary) {}
        PWButton(title: "Skip", style: .subtle) {}
    }
    .padding()
    .background(PWColors.background)
}
