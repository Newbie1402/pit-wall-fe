import SwiftUI

/// Home: next session hero, this weekend, my drivers, latest feed.
struct HomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppNavigation.self) private var navigation

    @State private var viewModel: HomeViewModel?
    @State private var constructors: [Constructor] = []
    @State private var showsReminderDeniedAlert = false

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                PWLoadingView(message: "Loading season…")
                    .task {
                        if viewModel == nil {
                            viewModel = HomeViewModel(
                                raceRepository: environment.raceRepository,
                                driverRepository: environment.driverRepository,
                                constructorRepository: environment.constructorRepository,
                                standingsRepository: environment.standingsRepository,
                                feedRepository: environment.feedRepository,
                                preferences: environment.preferences
                            )
                            await viewModel?.load()
                        }
                    }
            }
        }
        .navigationTitle("PITWALL")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                PWTypography.SectionLabel(text: "PitWall", color: PWColors.textPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Text("\(yearLabel)")
                    .font(PWTypography.captionBold)
                    .kerning(1.4)
                    .foregroundStyle(PWColors.textTertiary)
            }
        }
        .alert("Notifications Disabled", isPresented: $showsReminderDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications for PitWall in Settings to get session reminders.")
        }
    }

    private var yearLabel: String {
        "SEASON \(viewModel?.state.value?.seasonYear ?? MockSeasonFactory.seasonYear)"
    }

    @ViewBuilder
    private func content(_ viewModel: HomeViewModel) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            PWLoadingView(message: "Building your pit wall…")
        case .failed(let message):
            PWErrorStateView(message: message) {
                Task { await viewModel.load(force: true) }
            }
            .frame(maxHeight: .infinity)
        case .loaded(let content):
            ScrollView {
                VStack(alignment: .leading, spacing: PWSpacing.xl) {
                    NextSessionHeroCard(
                        race: content.next.race,
                        session: content.next.session,
                        isLive: content.next.isLive,
                        isReminderSet: environment.reminderCoordinator.isReminderSet(for: content.next.session)
                    ) {
                        Task { await toggleReminder(content) }
                    }

                    VStack(alignment: .leading, spacing: PWSpacing.sm) {
                        SectionHeaderView(title: "This Weekend")
                        WeekendScheduleSection(race: content.next.race)
                    }

                    VStack(alignment: .leading, spacing: PWSpacing.sm) {
                        SectionHeaderView(title: "My Drivers")
                        MyDriversSection(drivers: content.myDrivers) {
                            navigation.selectedTab = .settings
                        }
                    }

                    VStack(alignment: .leading, spacing: PWSpacing.sm) {
                        SectionHeaderView(title: "Latest", actionTitle: "See all") {
                            navigation.selectedTab = .feed
                        }
                        LatestFeedSection(
                            items: content.feed,
                            constructors: constructors,
                            onEmptyAction: {}
                        )
                    }
                }
                .pwSectionSpacing()
                .padding(.vertical, PWSpacing.md)
            }
            .refreshable {
                await viewModel.load(force: true)
            }
            .task {
                if constructors.isEmpty {
                    constructors = (try? await environment.constructorRepository.constructors()) ?? []
                }
            }
        }
    }

    private func toggleReminder(_ content: HomeViewModel.Content) async {
        let outcome = await environment.reminderCoordinator.toggleReminder(
            race: content.next.race,
            session: content.next.session
        )
        if outcome == .denied {
            showsReminderDeniedAlert = true
        }
    }
}

#Preview("Home") {
    NavigationStack {
        HomeView()
    }
    .environment(AppEnvironment.preview())
    .environment(AppNavigation())
}
