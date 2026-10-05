import SwiftUI

/// Championship tables with DRIVERS | CONSTRUCTORS segmentation and dense rows.
struct StandingsView: View {
    @Environment(AppEnvironment.self) private var environment

    @State private var viewModel: StandingsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                PWLoadingView(message: "Loading standings…")
                    .task {
                        if viewModel == nil {
                            viewModel = StandingsViewModel(standingsRepository: environment.standingsRepository)
                            await viewModel?.load()
                        }
                    }
            }
        }
        .navigationTitle("STANDINGS")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ viewModel: StandingsViewModel) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            PWLoadingView(message: "Loading standings…")
        case .failed(let message):
            PWErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
            .frame(maxHeight: .infinity)
        case .loaded(let content):
            VStack(spacing: 0) {
                Picker("Segment", selection: Binding(
                    get: { viewModel.segment },
                    set: { viewModel.segment = $0 }
                )) {
                    ForEach(StandingsViewModel.Segment.allCases) { segment in
                        Text(segment.title.uppercased()).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, PWSpacing.screenPadding)
                .padding(.vertical, PWSpacing.sm)

                switch viewModel.segment {
                case .drivers:
                    driverList(content)
                case .constructors:
                    constructorList(content)
                }
            }
        }
    }

    private func driverList(_ content: StandingsViewModel.Content) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(content.driverStandings) { standing in
                    NavigationLink(value: AppRoute.driver(standing.driver.id)) {
                        DriverStandingRow(
                            standing: standing,
                            isFollowed: environment.preferences.isFavoriteDriver(standing.driver.id)
                        )
                    }
                    .buttonStyle(.plain)
                    Divider()
                        .padding(.leading, 58)
                        .opacity(0.5)
                }
            }
            .pwCardBackground()
            .pwSectionSpacing()
            .padding(.vertical, PWSpacing.sm)
        }
    }

    private func constructorList(_ content: StandingsViewModel.Content) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(content.constructorStandings) { standing in
                    NavigationLink(value: AppRoute.team(standing.constructor.id)) {
                        ConstructorStandingRow(
                            standing: standing,
                            isFollowed: environment.preferences.isFavoriteConstructor(standing.constructor.id)
                        )
                    }
                    .buttonStyle(.plain)
                    Divider()
                        .padding(.leading, 58)
                        .opacity(0.5)
                }
            }
            .pwCardBackground()
            .pwSectionSpacing()
            .padding(.vertical, PWSpacing.sm)
        }
    }
}

#Preview("Standings") {
    NavigationStack {
        StandingsView()
    }
    .environment(AppEnvironment.preview())
}
