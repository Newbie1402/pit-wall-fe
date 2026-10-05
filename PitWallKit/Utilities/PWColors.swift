import SwiftUI

/// PitWall color tokens. Dark-first: the dark values are the canonical design,
/// light variants are provided so both modes render intentionally.
///
/// Never hardcode colors in views — always go through this palette (or team
/// colors from `TeamPalette`).
enum PWColors {

    // MARK: Backgrounds

    static let background = dynamic(
        light: UIColor(red: 0.956, green: 0.961, blue: 0.969, alpha: 1),
        dark: UIColor(red: 0.039, green: 0.043, blue: 0.055, alpha: 1)
    )

    static let surface = dynamic(
        light: .white,
        dark: UIColor(red: 0.082, green: 0.094, blue: 0.114, alpha: 1)
    )

    static let surfaceElevated = dynamic(
        light: .white,
        dark: UIColor(red: 0.110, green: 0.125, blue: 0.153, alpha: 1)
    )

    static let surfaceSunken = dynamic(
        light: UIColor(red: 0.925, green: 0.933, blue: 0.945, alpha: 1),
        dark: UIColor(red: 0.055, green: 0.063, blue: 0.078, alpha: 1)
    )

    // MARK: Text

    static let textPrimary = dynamic(
        light: UIColor(red: 0.055, green: 0.063, blue: 0.078, alpha: 1),
        dark: UIColor(red: 0.965, green: 0.969, blue: 0.976, alpha: 1)
    )

    static let textSecondary = dynamic(
        light: UIColor(red: 0.322, green: 0.353, blue: 0.400, alpha: 1),
        dark: UIColor(red: 0.639, green: 0.667, blue: 0.706, alpha: 1)
    )

    static let textTertiary = dynamic(
        light: UIColor(red: 0.541, green: 0.573, blue: 0.620, alpha: 1),
        dark: UIColor(red: 0.424, green: 0.455, blue: 0.502, alpha: 1)
    )

    // MARK: Accent — PitWall signal lime

    static let accent = dynamic(
        light: UIColor(red: 0.545, green: 0.647, blue: 0.063, alpha: 1),
        dark: UIColor(red: 0.745, green: 0.929, blue: 0.200, alpha: 1)
    )

    /// Accent at reduced strength for tinted backgrounds.
    static let accentSoft = dynamic(
        light: UIColor(red: 0.545, green: 0.647, blue: 0.063, alpha: 0.14),
        dark: UIColor(red: 0.745, green: 0.929, blue: 0.200, alpha: 0.13)
    )

    // MARK: Semantic

    /// Live sessions and urgent states.
    static let live = dynamic(
        light: UIColor(red: 0.867, green: 0.176, blue: 0.216, alpha: 1),
        dark: UIColor(red: 1.0, green: 0.302, blue: 0.318, alpha: 1)
    )

    /// Wins and podium highlights.
    static let gold = dynamic(
        light: UIColor(red: 0.788, green: 0.624, blue: 0.078, alpha: 1),
        dark: UIColor(red: 0.961, green: 0.773, blue: 0.094, alpha: 1)
    )

    static let success = dynamic(
        light: UIColor(red: 0.145, green: 0.596, blue: 0.322, alpha: 1),
        dark: UIColor(red: 0.220, green: 0.784, blue: 0.353, alpha: 1)
    )

    static let danger = live

    static let separator = dynamic(
        light: UIColor(red: 0.878, green: 0.890, blue: 0.906, alpha: 1),
        dark: UIColor(red: 0.145, green: 0.161, blue: 0.192, alpha: 1)
    )

    // MARK: Helpers

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
