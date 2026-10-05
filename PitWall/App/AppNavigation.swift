import Foundation
import Observation

/// Hashable destinations used across every tab's navigation stack.
enum AppRoute: Hashable {
    case race(Race.ID)
    case driver(Driver.ID)
    case team(Constructor.ID)
}

/// Tab identifiers for the main navigation.
enum AppTab: Hashable {
    case home
    case calendar
    case standings
    case feed
    case settings
}

/// Cross-tab navigation state, used by deep links and programmatic jumps.
@MainActor
@Observable
final class AppNavigation {
    var selectedTab: AppTab = .home
    /// Home tab's NavigationStack path, so deep links can push routes.
    var homePath: [AppRoute] = []
    /// Route waiting to be pushed onto Home's stack. Consumed by MainTabView.
    var pendingRoute: AppRoute?

    func pushHomeRoute(_ route: AppRoute) {
        selectedTab = .home
        homePath.append(route)
    }
}
