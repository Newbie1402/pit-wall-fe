import Foundation

/// Display formatting for positions and points, shared by app and widgets.
enum PWFormat {

    /// "P3" — championship/finishing position.
    static func position(_ value: Int?) -> String {
        guard let value, value > 0 else { return "—" }
        return "P\(value)"
    }

    /// "01" — zero-padded ordinal used in standings lists.
    static func ordinal(_ value: Int) -> String {
        String(format: "%02d", value)
    }

    /// "331 PTS"
    static func points(_ value: Int) -> String {
        "\(value) PTS"
    }

    /// Gap label for a standings row.
    static func gapLabel(behindLeader: Int) -> String {
        behindLeader > 0 ? "+\(behindLeader)" : "LEADER"
    }
}
