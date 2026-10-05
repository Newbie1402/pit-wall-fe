import SwiftUI

/// Layout metrics. One source of truth for spacing and corner radius.
enum PWSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    /// Standard screen horizontal padding.
    static let screenPadding: CGFloat = 16
}

enum PWRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let pill: CGFloat = 100
}

extension View {

    /// Standard card surface used across features.
    func pwCardBackground(radius: CGFloat = PWRadius.lg,
                          color: Color = PWColors.surface) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(color)
        )
    }
}
