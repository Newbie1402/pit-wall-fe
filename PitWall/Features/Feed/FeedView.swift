import SwiftUI

/// Personalized feed: favorite sources first, then the rest by recency.
struct FeedView: View {
    @Environment(AppEnvironment.self) private var environment

    @State private var viewModel: FeedViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                PWLoadingView(message: "Loading feed…")
                    .task {
                        if viewModel == nil {
                            viewModel = FeedViewModel(
                                feedRepository: environment.feedRepository,
                                preferences: environment.preferences
                            )
                            await viewModel?.load()
                        }
                    }
            }
        }
        .navigationTitle("FEED")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ viewModel: FeedViewModel) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            PWLoadingView(message: "Loading feed…")
        case .failed(let message):
            PWErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
            .frame(maxHeight: .infinity)
        case .loaded(let items):
            if items.isEmpty {
                PWEmptyStateView(
                    icon: "newspaper",
                    title: "Your feed is quiet",
                    message: "Follow drivers and a team in Settings to build your feed."
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: PWSpacing.sm) {
                        ForEach(items) { item in
                            FeedCardView(
                                item: item,
                                tint: tint(for: item)
                            )
                        }
                    }
                    .pwSectionSpacing()
                    .padding(.vertical, PWSpacing.sm)
                }
                .refreshable {
                    await viewModel.load()
                }
            }
        }
    }

    private func tint(for item: FeedItem) -> Color {
        guard let teamID = item.teamID else { return PWColors.accent }
        return TeamPalette.color(forConstructorID: teamID, in: MockRoster.constructors)
    }
}

#Preview("Feed") {
    NavigationStack {
        FeedView()
    }
    .environment(AppEnvironment.preview())
}
