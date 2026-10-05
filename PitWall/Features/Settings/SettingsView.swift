import SwiftUI
import UserNotifications

/// Settings: favorites, notifications, calendar, appearance, widgets, about.
struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        @Bindable var preferences = environment.preferences

        List {
            favoritesSection
            notificationsSection(preferences)
            calendarSection
            appearanceSection(preferences)
            widgetsSection
            aboutSection
        }
        .navigationTitle("SETTINGS")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshNotificationStatus() }
    }

    // MARK: - Sections

    private var favoritesSection: some View {
        Section("Favorites") {
            NavigationLink {
                FavoriteTeamEditorView()
            } label: {
                LabeledContent {
                    Text(favoriteTeamName)
                        .foregroundStyle(PWColors.textTertiary)
                } label: {
                    Label("Favorite Team", systemImage: "flag.2.crossed")
                }
            }
            NavigationLink {
                FavoriteDriversEditorView()
            } label: {
                LabeledContent {
                    Text("\(environment.preferences.favoriteDriverIDs.count)")
                        .foregroundStyle(PWColors.textTertiary)
                } label: {
                    Label("Favorite Drivers", systemImage: "helmet")
                }
            }
        }
    }

    private func notificationsSection(_ preferences: Binding<UserPreferencesStore>) -> some View {
        Section {
            Toggle(isOn: preferences.notifications.race) {
                Label("Race Reminders", systemImage: "flag.checkered")
            }
            Toggle(isOn: preferences.notifications.qualifying) {
                Label("Qualifying Reminders", systemImage: "timer")
            }
            Toggle(isOn: preferences.notifications.sprint) {
                Label("Sprint Reminders", systemImage: "bolt.fill")
            }
            Toggle(isOn: preferences.notifications.practice) {
                Label("Practice Reminders", systemImage: "steeringwheel")
            }
            Picker("Lead Time", selection: preferences.notifications.leadTimeMinutes) {
                Text("15 minutes").tag(15)
                Text("30 minutes").tag(30)
                Text("60 minutes").tag(60)
            }
            LabeledContent {
                Text(statusText)
                    .foregroundStyle(statusColor)
            } label: {
                Label("System Permission", systemImage: "bell.badge")
            }
            if notificationStatus == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open System Settings", systemImage: "arrow.up.forward.app")
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Permission is requested when you set your first reminder, never at launch.")
        }
        .tint(PWColors.accent)
    }

    private var calendarSection: some View {
        Section("Calendar") {
            LabeledContent {
                Text("Write access on demand")
                    .foregroundStyle(PWColors.textTertiary)
            } label: {
                Label("Session Events", systemImage: "calendar.badge.plus")
            }
            .tint(PWColors.accent)
        } footer: {
            Text("Use 'Add to Calendar' on any race weekend to export its sessions.")
        }
    }

    private func appearanceSection(_ preferences: Binding<UserPreferencesStore>) -> some View {
        Section("Appearance") {
            Picker("Theme", selection: preferences.appearance) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var widgetsSection: some View {
        Section {
            LabeledContent {
                Text("Ready")
                    .foregroundStyle(PWColors.success)
            } label: {
                Label("Next Race", systemImage: "square.stack.3d.up")
            }
            LabeledContent {
                Text("Ready")
                    .foregroundStyle(PWColors.success)
            } label: {
                Label("Favorite Driver", systemImage: "square.stack.3d.up.fill")
            }
        } header: {
            Text("Widgets")
        } footer: {
            Text("Add 'PitWall' widgets from the Home Screen. They show the next session countdown and your top driver's form.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent {
                Text(appVersion)
                    .foregroundStyle(PWColors.textTertiary)
            } label: {
                Label("Version", systemImage: "info.circle")
            }
            LabeledContent {
                Text("Mock data")
                    .foregroundStyle(PWColors.textTertiary)
            } label: {
                Label("Data Source", systemImage: "internaldrive")
            }
        } footer: {
            Text("PitWall is an unofficial fan companion. Not affiliated with Formula 1. All data in this build is local mock data.")
        }
    }

    // MARK: - Helpers

    private var favoriteTeamName: String {
        guard let id = environment.preferences.favoriteConstructorID,
              let constructor = MockRoster.constructor(for: id) else {
            return "None"
        }
        return constructor.shortName
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        return version
    }

    private var statusText: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return "Allowed"
        case .denied: return "Denied"
        case .notDetermined: return "Not requested"
        @unknown default: return "Unknown"
        }
    }

    private var statusColor: Color {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return PWColors.success
        case .denied: return PWColors.live
        default: return PWColors.textTertiary
        }
    }

    private func refreshNotificationStatus() async {
        notificationStatus = await environment.notifications.authorizationStatus()
    }
}

#Preview("Settings") {
    NavigationStack {
        SettingsView()
    }
    .environment(AppEnvironment.preview())
}
