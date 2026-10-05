import SwiftUI

/// Switches between onboarding and the main experience.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    /// UI tests can bypass onboarding deterministically.
    private var skipOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitest-skip-onboarding")
    }

    var body: some View {
        Group {
            if environment.preferences.hasCompletedOnboarding || skipOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: environment.preferences.hasCompletedOnboarding)
    }
}

#Preview("Root – Main") {
    RootView()
        .environment(AppEnvironment.preview())
}

#Preview("Root – Onboarding") {
    RootView()
        .environment(AppEnvironment.preview(preferences: UserPreferencesStore(
            defaults: UserDefaults(suiteName: "preview-root-ob-\(UUID().uuidString)"))))
}
