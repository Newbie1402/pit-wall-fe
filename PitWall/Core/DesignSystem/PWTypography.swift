import SwiftUI

/// PitWall typography. Semantic styles keep type consistent across features;
/// every style respects Dynamic Type through the system font.
enum PWTypography {

    // MARK: Display (hero countdown, splash numbers)

    static func countdown(_ size: CGFloat = 56) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static let heroTitle = Font.system(size: 30, weight: .heavy, design: .rounded)

    static let screenTitle = Font.system(size: 26, weight: .bold, design: .rounded)

    // MARK: Headings

    static let sectionHeader = Font.system(size: 13, weight: .bold, design: .default)

    static let cardTitle = Font.system(size: 17, weight: .bold, design: .default)

    static let cardTitleRounded = Font.system(size: 17, weight: .heavy, design: .rounded)

    static let rowTitle = Font.system(size: 15, weight: .semibold, design: .default)

    // MARK: Body

    static let body = Font.system(size: 15, weight: .regular, design: .default)

    static let bodyMedium = Font.system(size: 15, weight: .medium, design: .default)

    static let statValue = Font.system(size: 21, weight: .bold, design: .rounded)

    static let statValueLarge = Font.system(size: 27, weight: .heavy, design: .rounded)

    // MARK: Captions

    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)

    static let captionBold = Font.system(size: 12, weight: .bold, design: .default)

    static let microCaps = Font.system(size: 10, weight: .bold, design: .default)

    // MARK: View helpers

    /// Uppercase section label with letter spacing, e.g. "THIS WEEKEND".
    struct SectionLabel: View {
        let text: String
        var color: Color = PWColors.textTertiary

        var body: some View {
            Text(text.uppercased())
                .font(PWTypography.sectionHeader)
                .foregroundStyle(color)
                .kerning(1.6)
        }
    }
}
