import Foundation

/// A personalized feed entry (team post, driver post, or series highlight).
///
/// The model is intentionally provider-agnostic: it must never leak a specific
/// social network's shape. The Go backend will map external sources to this.
struct FeedItem: Codable, Identifiable, Equatable, Sendable {
    let id: String
    /// Display name of the source, e.g. "Ferrari" or "F1 Insider".
    let source: String
    let sourceType: FeedSourceType
    /// Constructor this item relates to, when any.
    let teamID: String?
    /// Driver this item relates to, when any.
    let driverID: String?
    let title: String
    let caption: String?
    /// Remote image, when the item carries one. UI shows a styled placeholder otherwise.
    let imageURL: URL?
    /// Link out to the original post or article.
    let externalURL: URL?
    let publishedAt: Date
}

enum FeedSourceType: String, Codable, CaseIterable, Sendable {
    case official
    case team
    case driver
    case media

    var displayName: String {
        switch self {
        case .official: return "Series"
        case .team: return "Team"
        case .driver: return "Driver"
        case .media: return "Media"
        }
    }
}
