import Foundation
import Observation

/// State machine for the onboarding flow.
@MainActor
@Observable
final class OnboardingFlowModel {

    enum Step: Int, CaseIterable {
        case welcome
        case team
        case drivers
        case notifications
        case summary
    }

    var step: Step = .welcome
    var selectedConstructorID: String?
    var selectedDriverIDs: Set<String> = []
    var notifications: NotificationPreferences = .default
    var isCompleting = false

    var progress: Double {
        Double(step.rawValue) / Double(Step.allCases.count - 1)
    }

    var canProceed: Bool {
        switch step {
        case .team: return selectedConstructorID != nil
        case .drivers: return !selectedDriverIDs.isEmpty
        default: return true
        }
    }

    func advance() {
        guard canProceed, let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    /// Persists choices and requests notification permission when the user
    /// opted into any reminder type. Permission is requested here — never at
    /// app launch.
    func complete(environment: AppEnvironment) async {
        guard !isCompleting else { return }
        isCompleting = true
        defer { isCompleting = false }

        environment.preferences.favoriteConstructorID = selectedConstructorID
        environment.preferences.favoriteDriverIDs = selectedDriverIDs
        environment.preferences.notifications = notifications

        if notifications.race || notifications.qualifying || notifications.sprint || notifications.practice {
            _ = await environment.notifications.requestAuthorization()
        }

        environment.preferences.hasCompletedOnboarding = true
    }
}
