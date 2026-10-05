import SwiftUI

extension View {

    /// Section content wrapper: horizontal padding.
    func pwSectionSpacing() -> some View {
        padding(.horizontal, PWSpacing.screenPadding)
    }
}

extension String {

    /// Strips common Grand Prix suffixes for compact display, e.g. "Singapore Grand Prix" → "Singapore".
    var withoutGrandPrixSuffix: String {
        replacingOccurrences(of: "Grand Prix", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
