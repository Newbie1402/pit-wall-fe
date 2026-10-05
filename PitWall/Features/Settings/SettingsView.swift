import SwiftUI

/// Settings root: favorites, notifications, calendar, appearance, widgets,
/// and about. All edits go through `UserPreferencesStore`.
struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    @State private var showsNotificationDeniedHint = false

    var body: some View {
        @Bindable var preferences = environment.preferences

        List {
            favoritesSection
            notificationsSection(preferences)
            appearanceSection(preferences)
            widgetsSection
            aboutSection
        }
        .navigationTitle("SETTINGS")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Favorites

    private var favoritesSection: some View {
        Section("Favorites") {
            NavigationLink {
                SettingsTeamEditorView()
            } label: {
                Label("Favorite Team", systemImage: "flag.2.crossed")
            }
            NavigationLink {
                SettingsDriverEditorView()
            } label: {
                LabeledContent {
                    Text("\(environment.preferences.favoriteDriverIDs.count)")
                        .foregroundStyle(PWColors.textTertiary)
                } label: {
                    Label("Favorite Drivers", systemImage: "person.3")
                }
            }
        }
    }

    // MARK: - Notifications

    private func notificationsSection(_ preferences: Binding<UserPreferencesStore>) -> some View {
        Section {
            Toggle("Race", isOn: preferences.notifications.race)
            Toggle("Qualifying", isOn: preferences.notifications.qualifying)
            Toggle("Sprint", isOn: preferences.notifications.sprint)
            Toggle("Practice", isOn: preferences.notifications.practice)

            Picker("Lead Time", selection: preferences.notifications.leadTimeMinutes) {
                Text("15 minutes before").tag(15)
                Text("30 minutes before").tag(30)
                Text("60 minutes before").tag(60)
            }
        } header: {
            Text("Session Reminders")
        } footer: {
            Text("Reminders fire per session you enable, using the lead time above. System permission is requested when you first set a reminder.")
        }
        .tint(PWColors.accent)
    }

    // MARK: - Appearance

    private func appearanceSection(_ preferences: Binding<UserPreferencesStore>) -> some View {
        Section {
            Picker("Appearance", selection: preferences.appearance) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Appearance")
        } footer: {
            Text("PitWall is designed dark-first; Light keeps full contrast.")
        }
    }

    // MARK: - Widgets

    private var widgetsSection: some View {
        Section {
            LabeledContent("Next Race") {
                Text("Small • Medium")
                    .foregroundStyle(PWColors.textTertiary)
            }
            LabeledContent("Favorite Driver") {
                Text("Small • Medium")
                    .foregroundStyle(PWColors.textTertiary)
            }
        } header: {
            Text("Home Screen Widgets")
        } footer: {
            Text("Long-press the Home Screen, search \"PitWall\" and pick a size. Widgets show your favorites and the next session countdown.")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version") {
                Text(appVersion)
                    .foregroundStyle(PWColors.textTertiary)
                    .monospacedDigit()
            }
            LabeledContent("Data") {
                Text("Mock season 2026")
                    .foregroundStyle(PWColors.textTertiary)
            }
            VStack(alignment: .leading, spacing: PWSpacing.xxs) {
                Text("PitWall is an unofficial Formula 1 companion built for fans. Not affiliated with F1, Formula One Group, or any team. All data in this build is locally generated mock data.")
                    .font(PWTypography.caption)
                    .foregroundStyle(PWColors.textTertiary)
            }
            .padding(.vertical, PWSpacing.xxs)
        }
    }

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        let version = short ?? "1.0"
        guard let build else { return version }
        return "\(version) (\(build))"
    }
}

/// Reuses the onboarding team picker for editing the favorite constructor.
struct SettingsTeamEditorView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var constructors: Loadable<[Constructor]> = .idle

    var body: some View {
        Group {
            switch constructors {
            case .idle, .loading:
                PWLoadingView(message: "Loading teams…")
            case .failed(let message):
                PWErrorStateView(message: message) {
                    Task { await load() }
                }
            case .loaded(let loaded):
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: PWSpacing.sm),
                                        GridItem(.flexible(), spacing: PWSpacing.sm)],
                              spacing: PWSpacing.sm) {
                        ForEach(loaded) { constructor in
                            ConstructorCard(
                                constructor: constructor,
                                isSelected: environment.preferences.isFavoriteConstructor(constructor.id)
                            ) {
                                if environment.preferences.isFavoriteConstructor(constructor.id) {
                                    environment.preferences.setFavoriteConstructor(nil)
                                } else {
                                    environment.preferences.setFavoriteConstructor(constructor.id)
                                }
                            }
                        }
                    }
                    .pwSectionSpacing()
                    .padding(.vertical, PWSpacing.md)
                }
            }
        }
        .navigationTitle("FAVORITE TEAM")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        constructors = .loading
        do {
            constructors = .loaded(try await environment.constructorRepository.constructors())
        } catch {
            constructors = .failed(PWErrorMapper.message(for: error))
        }
    }
}

/// Reuses the onboarding driver list for editing favorite drivers.
struct SettingsDriverEditorView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var drivers: Loadable<[Driver]> = .idle

    var body: some View {
        Group {
            switch drivers {
            case .idle, .loading:
                PWLoadingView(message: "Loading grid…")
            case .failed(let message):
                PWErrorStateView(message: message) {
                    Task { await load() }
                }
            case .loaded(let loaded):
                ScrollView {
                    DriverSelectionList(
                        drivers: loaded,
                        constructors: MockRoster.constructors,
                        selectedIDs: Binding(
                            get: { environment.preferences.favoriteDriverIDs },
                            set: { environment.preferences.favoriteDriverIDs = $0 }
                        )
                    )
                    .pwSectionSpacing()
                    .padding(.vertical, PWSpacing.md)
                }
            }
        }
        .navigationTitle("FAVORITE DRIVERS")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        drivers = .loading
        do {
            drivers = .loaded(try await environment.driverRepository.drivers())
        } catch {
            drivers = .failed(PWErrorMapper.message(for: error))
        }
    }
}

#Preview("Settings") {
    NavigationStack {
        SettingsView()
    }
    .environment(AppEnvironment.preview())
}
