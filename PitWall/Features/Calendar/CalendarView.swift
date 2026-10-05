import SwiftUI

/// Full season calendar with Upcoming / Completed / All filtering.
struct CalendarView: View {
    @Environment(AppEnvironment.self) private var environment

    @State private var viewModel: CalendarViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                PWLoadingView(message: "Loading season…")
                    .task {
                        if viewModel == nil {
                            viewModel = CalendarViewModel(raceRepository: environment.raceRepository)
                            await viewModel?.load()
                        }
                    }
            }
        }
        .navigationTitle("CALENDAR")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ viewModel: CalendarViewModel) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            PWLoadingView(message: "Loading season…")
        case .failed(let message):
            PWErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
            .frame(maxHeight: .infinity)
        case .loaded(let content):
            let races = viewModel.races(for: content)
            VStack(spacing: 0) {
                Picker("Filter", selection: Binding(
                    get: { viewModel.filter },
                    set: { viewModel.filter = $0 }
                )) {
                    ForEach(CalendarViewModel.Filter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, PWSpacing.screenPadding)
                .padding(.vertical, PWSpacing.sm)

                if races.isEmpty {
                    PWEmptyStateView(
                        icon: "calendar.badge.exclamationmark",
                        title: "Nothing here",
                        message: emptyMessage(for: viewModel.filter)
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: PWSpacing.sm) {
                            ForEach(races) { race in
                                NavigationLink(value: AppRoute.race(race.id)) {
                                    RaceCardView(
                                        race: race,
                                        isNext: race.id == content.nextRaceID,
                                        winnerName: content.winnersByRace[race.id]
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .pwSectionSpacing()
                        .padding(.vertical, PWSpacing.sm)
                    }
                }
            }
        }
    }

    private func emptyMessage(for filter: CalendarViewModel.Filter) -> String {
        switch filter {
        case .upcoming: return "The season has wrapped up. Check completed races for results."
        case .completed: return "No races have been run yet this season."
        case .all: return "The season calendar is not available."
        }
    }
}

#Preview("Calendar") {
    NavigationStack {
        CalendarView()
    }
    .environment(AppEnvironment.preview())
}
