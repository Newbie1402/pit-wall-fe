import SwiftUI

/// Main tab navigation: Home, Calendar, Standings, Feed, Settings.
struct MainTabView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppNavigation.self) private var navigation

    var body: some View {
        @Bindable var navigation = navigation

        TabView(selection: $navigation.selectedTab) {
            NavigationStack(path: $navigation.homePath) {
                HomeView()
                    .navigationDestination(for: AppRoute.self, destination: destination)
            }
            .tabItem { Label("Home", systemImage: "flag.checkered") }
            .tag(AppTab.home)

            NavigationStack {
                CalendarView()
                    .navigationDestination(for: AppRoute.self, destination: destination)
            }
            .tabItem { Label("Calendar", systemImage: "calendar") }
            .tag(AppTab.calendar)

            NavigationStack {
                StandingsView()
                    .navigationDestination(for: AppRoute.self, destination: destination)
            }
            .tabItem { Label("Standings", systemImage: "list.number") }
            .tag(AppTab.standings)

            NavigationStack {
                FeedView()
                    .navigationDestination(for: AppRoute.self, destination: destination)
            }
            .tabItem { Label("Feed", systemImage: "newspaper") }
            .tag(AppTab.feed)

            NavigationStack {
                SettingsView()
                    .navigationDestination(for: AppRoute.self, destination: destination)
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(AppTab.settings)
        }
        .onChange(of: navigation.pendingRoute) { _, pending in
            guard let pending else { return }
            navigation.pendingRoute = nil
            navigation.pushHomeRoute(pending)
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .race(let raceID):
            RaceDetailView(raceID: raceID)
        case .driver(let driverID):
            DriverDetailView(driverID: driverID)
        case .team(let teamID):
            TeamDetailView(teamID: teamID)
        }
    }
}
