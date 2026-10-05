import SwiftUI

/// Team Detail: constructor hero, season stats, driver line-up, recent form
/// and team-related feed, with follow/unfollow.
struct TeamDetailView: View {
    let teamID: String

    @Environment(AppEnvironment.self) private var environment

    @State private var viewModel: TeamDetailViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                PWLoadingView(message: "Loading team…")
                    .task {
                        if viewModel == nil {
                            viewModel = TeamDetailViewModel(
                                teamID: teamID,
                                constructorRepository: environment.constructorRepository,
                                driverRepository: environment.driverRepository,
                                standingsRepository: environment.standingsRepository,
                                feedRepository: environment.feedRepository
                            )
                            await viewModel?.load()
                        }
                    }
            }
        }
        .navigationTitle("TEAM")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ viewModel: TeamDetailViewModel) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            PWLoadingView(message: "Loading team…")
        case .failed(let message):
            PWErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
            .frame(maxHeight: .infinity)
        case .loaded(let content):
            ScrollView {
                VStack(alignment: .leading, spacing: PWSpacing.lg) {
                    heroCard(content)
                    driversSection(content)
                    formSection(content)
                    if !content.feed.isEmpty {
                        feedSection(content)
                    }
                }
                .pwSectionSpacing()
                .padding(.vertical, PWSpacing.md)
            }
        }
    }

    // MARK: - Hero

    private func heroCard(_ content: TeamDetailViewModel.Content) -> some View {
        let teamColor = TeamPalette.color(for: content.constructor)
        let isFollowed = environment.preferences.isFavoriteConstructor(content.constructor.id)
        return VStack(alignment: .leading, spacing: PWSpacing.md) {
            RoundedRectangle(cornerRadius: PWRadius.md, style: .continuous)
                .fill(
                    LinearGradient(colors: [teamColor.opacity(0.85), teamColor.opacity(0.25)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(height: 8)

            Text(content.constructor.name.uppercased())
                .font(PWTypography.heroTitle)
                .foregroundStyle(PWColors.textPrimary)

            Text("\(content.constructor.countryFlag) \(content.constructor.shortName)")
                .font(PWTypography.captionBold)
                .foregroundStyle(PWColors.textSecondary)

            HStack(spacing: PWSpacing.sm) {
                HStack(spacing: PWSpacing.sm) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(PWFormat.position(content.stats.championshipPosition))
                            .font(PWTypography.statValueLarge)
                            .monospacedDigit()
                            .foregroundStyle(PWColors.textPrimary)
                        Text("CHAMPIONSHIP")
                            .font(PWTypography.microCaps)
                            .kerning(1.4)
                            .foregroundStyle(PWColors.textTertiary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(PWFormat.points(content.stats.points))
                            .font(PWTypography.statValueLarge)
                            .monospacedDigit()
                            .foregroundStyle(teamColor)
                        Text("SEASON")
                            .font(PWTypography.microCaps)
                            .kerning(1.4)
                            .foregroundStyle(PWColors.textTertiary)
                    }
                }
                .padding(PWSpacing.md)
                .pwCardBackground(color: PWColors.surfaceSunken, radius: PWRadius.md)
            }

            HStack(spacing: PWSpacing.sm) {
                StatTile(value: "\(content.stats.wins)", label: "Wins")
                StatTile(value: "\(content.stats.podiums)", label: "Podiums")
            }

            PWButton(
                title: isFollowed ? "Following Team" : "Follow Team",
                icon: isFollowed ? "heart.fill" : "heart"
            ) {
                environment.preferences.setFavoriteConstructor(
                    isFollowed ? nil : content.constructor.id
                )
            }
        }
        .padding(PWSpacing.lg)
        .pwCardBackground(color: PWColors.surfaceElevated)
    }

    // MARK: - Drivers

    private func driversSection(_ content: TeamDetailViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: PWSpacing.sm) {
            PWTypography.SectionLabel(text: "Drivers")
            VStack(spacing: 0) {
                ForEach(content.drivers) { standing in
                    NavigationLink(value: AppRoute.driver(standing.driver.id)) {
                        HStack(spacing: PWSpacing.sm) {
                            Text(standing.driver.code)
                                .font(PWTypography.cardTitleRounded)
                                .foregroundStyle(TeamPalette.color(for: standing.constructor))
                                .frame(width: 56, alignment: .leading)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(standing.driver.fullName)
                                    .font(PWTypography.rowTitle)
                                    .foregroundStyle(PWColors.textPrimary)
                                Text("#\(standing.driver.number)")
                                    .font(PWTypography.caption)
                                    .foregroundStyle(PWColors.textTertiary)
                            }
                            Spacer()
                            Text(PWFormat.position(standing.position))
                                .font(PWTypography.rowTitle)
                                .monospacedDigit()
                                .foregroundStyle(PWColors.textSecondary)
                        }
                        .padding(.horizontal, PWSpacing.md)
                        .padding(.vertical, PWSpacing.sm)
                        Divider()
                            .padding(.leading, PWSpacing.md)
                            .opacity(0.5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .pwCardBackground()
        }
    }

    // MARK: - Form

    private func formSection(_ content: TeamDetailViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: PWSpacing.sm) {
            PWTypography.SectionLabel(text: "Recent Performance")
            VStack(alignment: .leading, spacing: PWSpacing.xs) {
                PWTypography.SectionLabel(text: "Best finisher, last 5")
                HStack(spacing: PWSpacing.xs) {
                    if content.stats.recentForm.isEmpty {
                        Text("No completed races yet")
                            .font(PWTypography.caption)
                            .foregroundStyle(PWColors.textTertiary)
                    } else {
                        ForEach(Array(content.stats.recentForm.enumerated()), id: \.offset) { _, position in
                            FormChip(position: position, status: position == nil ? "DNF" : nil)
                                .frame(minWidth: 38)
                        }
                    }
                }
            }
            .padding(PWSpacing.md)
            .pwCardBackground()
        }
    }

    // MARK: - Feed

    private func feedSection(_ content: TeamDetailViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: PWSpacing.sm) {
            PWTypography.SectionLabel(text: "Team Feed")
            VStack(spacing: PWSpacing.sm) {
                ForEach(content.feed.prefix(4)) { item in
                    FeedCardView(item: item, tint: TeamPalette.color(for: content.constructor))
                }
            }
        }
    }
}

#Preview("Team Detail") {
    NavigationStack {
        TeamDetailView(teamID: "mclaren")
    }
    .environment(AppEnvironment.preview())
}
