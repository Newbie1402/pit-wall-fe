import SwiftUI

/// Parses "#RRGGBB" hex strings into SwiftUI colors.
enum ColorHex {

    static func color(_ hex: String) -> Color {
        Color(uiColor: uiColor(hex))
    }

    static func uiColor(_ hex: String) -> UIColor {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.hasPrefix("#") { sanitized.removeFirst() }
        guard sanitized.count == 6,
              let value = UInt32(sanitized, radix: 16) else {
            return UIColor.systemGray
        }
        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}

/// Team brand colors used across the app and widgets.
enum TeamPalette {

    static func color(for constructor: Constructor) -> Color {
        ColorHex.color(constructor.colorHex)
    }

    static func color(forConstructorID id: String, in constructors: [Constructor]) -> Color {
        constructors.first { $0.id == id }.map { ColorHex.color($0.colorHex) } ?? PWColors.accent
    }
}
