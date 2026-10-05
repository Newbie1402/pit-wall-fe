import SwiftUI

/// Driver Detail: identity hero, championship position, stats grid, last-5
/// form and recent race results, with follow/unfollow.
struct DriverDetailView: View {
    let driverID: String

    @Environment(AppEnvironment.self) private var environment

    @State private var viewModel: DriverDetailViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                PWLoadingView(message: "Loading driver…")
                    .task {
                        if viewModel == nil {
                            viewModel = DriverDetailViewModel(
                                driverID: driverID,
                                driverRepository: environment.driverRepository,
                                constructorRepository: environment.constructorRepository
                            )
                            await viewModel?.load()
                        }
                    }
            }
        }
        .navigationTitle("DRIVER")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ viewModel: DriverDetailViewModel) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            PWLoadingView(message: "Loading driver…")
        case .failed(let message):
            PWErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
            .frame(maxHeight: .infinity)
        case .loaded(let content):
            ScrollView {
                VStack(alignment: .leading, spacing: PWSpacing.lg) {
                    heroCard(content)
                    formSection(content)
                    recentRacesSection(content)
                }
                .pwSectionSpacing()
                .padding(.vertical, PWSpacing.md)
            }
        }
    }

    // MARK: - Hero

    private func heroCard(_ content: DriverDetailViewModel.Content) -> some View {
        let teamColor = TeamPalette.color(for: content.constructor)
        let isFollowed = environment.preferences.isFavoriteDriver(content.driver.id)
        return VStack(alignment: .leading, spacing: PWSpacing.md) {
            HStack(alignment: .top, spacing: PWSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.driver.code)
                        .font(PWTypography.countdown(44))
                        .foregroundStyle(teamColor)
                    Text(content.driver.fullName.uppercased())
                        .font(PWTypography.heroTitle)
                        .foregroundStyle(PWColors.textPrimary)
                }
                Spacer()
                Text("#\(content.driver.number)")
                    .font(PWTypography.statValueLarge)
                    .monospacedDigit()
                    .foregroundStyle(PWColors.textTertiary)
            }

            HStack(spacing: PWSpacing.xs) {
                TeamColorBar(color: teamColor, height: 16)
                Text(content.constructor.name.uppercased())
                    .font(PWTypography.captionBold)
                    .kerning(1.2)
                    .foregroundStyle(PWColors.textSecondary)
                Text(content.driver.countryFlag)
                    .font(PWTypography.caption)
            }

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
                            .foregroundStyle(PWColors.accent)
                        Text("SEASON")
                            .font(PWTypography.microCaps)
                            .kerning(1.4)
                            .foregroundStyle(PWColors.textTertiary)
                    }
                }
                .padding(PWSpacing.md)
                .pwCardBackground(color: PWColors.surfaceSunken, radius: PWRadius.md)
            }

            PWButton(
                title: isFollowed ? "Following Driver" : "Follow Driver",
                icon: isFollowed ? "heart.fill" : "heart"
            ) {
                environment.preferences.toggleDriverFavorite(content.driver.id)
            }
        }
        .padding(PWSpacing.lg)
        .pwCardBackground(color: PWColors.surfaceElevated)
    }

    // MARK: - Stats + Form

    private func formSection(_ content: DriverDetailViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: PWSpacing.sm) {
            PWTypography.SectionLabel(text: "Statistics")
            HStack(spacing: PWSpacing.sm) {
                StatTile(value: "\(content.stats.wins)", label: "Wins")
                StatTile(value: "\(content.stats.podiums)", label: "Podiums")
                StatTile(value: "\(content.stats.poles)", label: "Poles")
                StatTile(value: "\(content.stats.fastestLaps)", label: "Fastest")
            }

            VStack(alignment: .leading, spacing: PWSpacing.xs) {
                PWTypography.SectionLabel(text: "Last 5")
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

    // MARK: - Recent races

    private func recentRacesSection(_ content: DriverDetailViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: PWSpacing.sm) {
            PWTypography.SectionLabel(text: "Recent Races")
            if content.stats.recentRaces.isEmpty {
                PWEmptyStateView(icon: "flag.slash", title: "No results yet",
                                 message: "Results will appear after the first race.")
                    .pwCardBackground()
            } else {
                VStack(spacing: 0) {
                    ForEach(content.stats.recentRaces.prefix(8)) { weekend in
                        HStack(spacing: PWSpacing.sm) {
                            Text(weekend.countryFlag)
                                .font(PWTypography.body)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(weekend.raceName.withoutGrandPrixSuffix)
                                    .font(PWTypography.rowTitle)
                                    .foregroundStyle(PWColors.textPrimary)
                                Text(qualifyingLine(weekend))
                                    .font(PWTypography.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(PWColors.textTertiary)
                            }
                            Spacer()
                            if let status = weekend.status {
                                Text(status)
                                    .font(PWTypography.captionBold)
                                    .foregroundStyle(PWColors.live)
                            } else {
                                FormChip(position: weekend.racePosition)
                            }
                            Text(weekend.points > 0 ? "+\(weekend.points)" : "—")
                                .font(PWTypography.captionBold)
                                .monospacedDigit()
                                .foregroundStyle(PWColors.textSecondary)
                                .frame(width: 30, alignment: .trailing)
                        }
                        .padding(.horizontal, PWSpacing.md)
                        .padding(.vertical, PWSpacing.sm)
                        Divider()
                            .padding(.leading, PWSpacing.md)
                            .opacity(0.5)
                    }
                }
                .pwCardBackground()
            }
        }
    }

    private func qualifyingLine(_ weekend: RaceWeekendResult) -> String {
        guard let quali = weekend.qualifyingPosition else { return "Round \(weekend.round)" }
        return "Round \(weekend.round) • Q\(quali)"
    }
}

#Preview("Driver Detail") {
    NavigationStack {
        DriverDetailView(driverID: "norris")
    }
    .environment(AppEnvironment.preview())
}
