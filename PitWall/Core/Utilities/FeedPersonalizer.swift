import Foundation

/// Ranks feed items by personal relevance: favorite drivers first, then the
/// favorite team, then recency. Shared by Home's "LATEST" and the Feed tab.
enum FeedPersonalizer {

    static func sorted(_ items: [FeedItem],
                       favoriteDriverIDs: Set<String>,
                       favoriteConstructorID: String?) -> [FeedItem] {
        items.sorted { lhs, rhs in
            let lhsScore = relevance(of: lhs, favoriteDriverIDs: favoriteDriverIDs,
                                     favoriteConstructorID: favoriteConstructorID)
            let rhsScore = relevance(of: rhs, favoriteDriverIDs: favoriteDriverIDs,
                                     favoriteConstructorID: favoriteConstructorID)
            if lhsScore != rhsScore { return lhsScore > rhsScore }
            return lhs.publishedAt > rhs.publishedAt
        }
    }

    static func isRelevant(_ item: FeedItem,
                           favoriteDriverIDs: Set<String>,
                           favoriteConstructorID: String?) -> Bool {
        relevance(of: item, favoriteDriverIDs: favoriteDriverIDs,
                  favoriteConstructorID: favoriteConstructorID) > 0
    }

    private static func relevance(of item: FeedItem,
                                  favoriteDriverIDs: Set<String>,
                                  favoriteConstructorID: String?) -> Int {
        var score = 0
        if let driverID = item.driverID, favoriteDriverIDs.contains(driverID) {
            score += 2
        }
        if let teamID = item.teamID, teamID == favoriteConstructorID {
            score += 1
        }
        return score
    }
}
