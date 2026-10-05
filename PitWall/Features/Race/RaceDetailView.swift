import SwiftUI

/// Race Detail: header, weekend schedule with reminder bells, follow and
/// calendar actions, and results for completed sessions.
struct RaceDetailView: View {
    let raceID: String

    @Environment(AppEnvironment.self) private var environment

    @State private var viewModel: RaceDetailViewModel?
    @State private var showsReminderDeniedAlert = false
    @State private var addedToCalendarCount: Int?
    @State private var calendarFailure = false

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                PWLoadingView(message: "Loading weekend…")
                    .task {
                        if viewModel == nil {
                            viewModel = RaceDetailViewModel(raceID: raceID, raceRepository: environment.raceRepository)
                            await viewModel?.load()
                        }
                    }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
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
        .alert("Added to Calendar", isPresented: Binding(
            get: { addedToCalendarCount != nil },
            set: { if !$0 { addedToCalendarCount = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(addedToCalendarCount ?? 0) upcoming session(s) were added to your calendar.")
        }
        .alert("Calendar Unavailable", isPresented: $calendarFailure) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("PitWall could not access your calendar. Check permission in Settings.")
        }
    }

    private var navigationTitle: String {
        viewModel?.state.value?.race.shortName.uppercased() ?? "RACE"
    }

    @ViewBuilder
    private func content(_ viewModel: RaceDetailViewModel) -> some View {
        switch viewModel.state {
        case .idle, .loading:
            PWLoadingView(message: "Loading weekend…")
        case .failed(let message):
            PWErrorStateView(message: message) {
                Task { await viewModel.load() }
            }
            .frame(maxHeight: .infinity)
        case .loaded(let content):
            ScrollView {
                VStack(alignment: .leading, spacing: PWSpacing.lg) {
                    headerCard(content)

                    actionRow(content)

                    VStack(alignment: .leading, spacing: PWSpacing.sm) {
                        PWTypography.SectionLabel(text: "Weekend Schedule")
                        VStack(spacing: 0) {
                            ForEach(content.race.sessionsInOrder) { session in
                                SessionRowView(
                                    session: session,
                                    race: content.race,
                                    result: content.results[session.type],
                                    isReminderSet: environment.reminderCoordinator.isReminderSet(for: session)
                                ) {
                                    Task { await toggleReminder(content, session: session) }
                                }
                                Divider()
                                    .padding(.leading, PWSpacing.md)
                                    .opacity(0.5)
                            }
                        }
                        .pwCardBackground()
                    }
                }
                .pwSectionSpacing()
                .padding(.vertical, PWSpacing.md)
            }
        }
    }

    // MARK: - Pieces

    private func headerCard(_ content: RaceDetailViewModel.Content) -> some View {
        let race = content.race
        let window = race.weekendWindow()
        return VStack(alignment: .leading, spacing: PWSpacing.sm) {
            HStack(alignment: .top, spacing: PWSpacing.sm) {
                Text(race.countryFlag)
                    .font(.system(size: 34))
                VStack(alignment: .leading, spacing: 2) {
                    Text(race.name)
                        .font(PWTypography.heroTitle)
                        .foregroundStyle(PWColors.textPrimary)
                    Text("ROUND \(race.round) • \(race.countryName.uppercased())")
                        .font(PWTypography.microCaps)
                        .kerning(1.6)
                        .foregroundStyle(PWColors.textTertiary)
                }
                Spacer()
                raceStateBadge(race)
            }

            Text(race.circuit.name)
                .font(PWTypography.bodyMedium)
                .foregroundStyle(PWColors.textSecondary)

            if let window {
                Text(PitWallDate.dateRangeString(from: window.start, to: window.end))
                    .font(PWTypography.caption)
                    .monospacedDigit()
                    .foregroundStyle(PWColors.textTertiary)
            }
        }
        .padding(PWSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pwCardBackground(color: PWColors.surfaceElevated)
    }

    private func raceStateBadge(_ race: Race) -> some View {
        switch race.state(at: Date()) {
        case .completed:
            PWTag(text: "Completed", color: PWColors.textSecondary, filled: false)
        case .inProgress:
            PWTag(text: "Live", color: PWColors.live)
        case .upcoming:
            PWTag(text: "Upcoming", color: PWColors.accent, filled: false)
        }
    }

    private func actionRow(_ content: RaceDetailViewModel.Content) -> some View {
        let isFollowed = environment.preferences.followedRaceIDs.contains(content.race.id)
        return VStack(spacing: PWSpacing.sm) {
            PWButton(
                title: isFollowed ? "Following Weekend" : "Follow Weekend",
                icon: isFollowed ? "heart.fill" : "heart"
            ) {
                environment.preferences.toggleFollowedRace(content.race.id)
            }

            if content.race.state(at: Date()) != .completed {
                PWButton(title: "Add to Calendar", icon: "calendar.badge.plus", style: .secondary) {
                    Task { await addToCalendar(content) }
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleReminder(_ content: RaceDetailViewModel.Content, session: RaceSession) async {
        let outcome = await environment.reminderCoordinator.toggleReminder(
            race: content.race,
            session: session
        )
        if outcome == .denied {
            showsReminderDeniedAlert = true
        }
    }

    private func addToCalendar(_ content: RaceDetailViewModel.Content) async {
        let now = Date()
        let upcomingSessions = content.race.sessionsInOrder.filter { $0.state(at: now) != .completed }
        guard !upcomingSessions.isEmpty else { return }
        do {
            let count = try await environment.calendar.addSessions(
                upcomingSessions,
                race: content.race,
                localTimeZone: .current
            )
            addedToCalendarCount = count
        } catch {
            calendarFailure = true
        }
    }
}

#Preview("Race Detail – Upcoming") {
    NavigationStack {
        RaceDetailView(raceID: "singapore")
    }
    .environment(AppEnvironment.preview())
}
