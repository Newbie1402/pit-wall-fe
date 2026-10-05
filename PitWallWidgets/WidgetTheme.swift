import SwiftUI

/// Compact typography for widgets (the app's PWTypography is app-target only).
enum WidgetType {
    static let label = Font.system(size: 9, weight: .bold)
    static let caption = Font.system(size: 10, weight: .medium)
    static let title = Font.system(size: 15, weight: .heavy, design: .rounded)
    static let stat = Font.system(size: 20, weight: .heavy, design: .rounded)
    static let countdown = Font.system(size: 24, weight: .heavy, design: .rounded)
}

extension View {
    /// Required widget canvas background, using the shared palette.
    func pwWidgetBackground() -> some View {
        containerBackground(for: .widget) {
            PWColors.background
        }
    }
}
