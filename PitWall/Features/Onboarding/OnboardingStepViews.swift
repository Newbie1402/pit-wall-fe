import SwiftUI

/// Step 1 — Welcome.
struct WelcomeStepView: View {
    let getStarted: () -> Void

    var body: some View {
        VStack(spacing: PWSpacing.xl) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: PWRadius.xl, style: .continuous)
                    .fill(PWColors.accentSoft)
                    .frame(width: 108, height: 108)
                Image(systemName: "flag.checkered")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(PWColors.accent)
            }

            VStack(spacing: PWSpacing.sm) {
                Text("PITWALL")
                    .font(PWTypography.heroTitle)
                    .kerning(6)
                    .foregroundStyle(PWColors.textPrimary)

                Text("Your personal Formula 1 pit wall.")
                    .font(PWTypography.body)
                    .foregroundStyle(PWColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: PWSpacing.md) {
                featureRow(icon: "timer", text: "Live countdowns to every session, in your timezone")
                featureRow(icon: "bell.badge", text: "Reminders so you never miss lights out")
                featureRow(icon: "heart.text.square", text: "A feed built around your team and drivers")
            }
            .padding(PWSpacing.lg)
            .pwCardBackground()

            Spacer()
        }
        .padding(.horizontal, PWSpacing.screenPadding)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: PWSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PWColors.accent)
                .frame(width: 24)
            Text(text)
                .font(PWTypography.captionMedium)
                .foregroundStyle(PWColors.textSecondary)
        }
    }
}

/// Step 2 — Favorite team.
struct TeamStepView: View {
    let constructors: Loadable<[Constructor]>
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PWSpacing.lg) {
            stepHeader(title: "Pick your team",
                       subtitle: "Your garage colors across the app. You can change this any time.")

            switch constructors {
            case .idle, .loading:
                PWLoadingView(message: "Loading teams…")
            case .failed(let message):
                PWErrorStateView(message: message)
            case .loaded(let loaded):
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: PWSpacing.sm),
                                        GridItem(.flexible(), spacing: PWSpacing.sm)],
                              spacing: PWSpacing.sm) {
                        ForEach(loaded) { constructor in
                            ConstructorCard(
                                constructor: constructor,
                                isSelected: selection == constructor.id
                            ) {
                                selection = selection == constructor.id ? nil : constructor.id
                            }
                        }
                    }
                    .padding(.bottom, PWSpacing.xl)
                }
            }
        }
        .padding(.horizontal, PWSpacing.screenPadding)
    }
}

/// Step 3 — Favorite drivers.
struct DriverStepView: View {
    let drivers: Loadable<[Driver]>
    let constructors: [Constructor]
    @Binding var selectedIDs: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: PWSpacing.lg) {
            stepHeader(title: "Follow drivers",
                       subtitle: selectedIDs.isEmpty
                            ? "Choose at least one driver to personalize your feed."
                            : "\(selectedIDs.count) driver\(selectedIDs.count == 1 ? "" : "s") selected")

            switch drivers {
            case .idle, .loading:
                PWLoadingView(message: "Loading grid…")
            case .failed(let message):
                PWErrorStateView(message: message)
            case .loaded(let loaded):
                ScrollView {
                    DriverSelectionList(
                        drivers: loaded,
                        constructors: constructors,
                        selectedIDs: $selectedIDs
                    )
                    .padding(.bottom, PWSpacing.xl)
                }
            }
        }
        .padding(.horizontal, PWSpacing.screenPadding)
    }
}

/// Step 4 — Notification preferences.
struct NotificationStepView: View {
    @Binding var preferences: NotificationPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: PWSpacing.lg) {
            stepHeader(title: "Session reminders",
                       subtitle: "We'll nudge you before lights out. Permission is requested only if you turn anything on.")

            VStack(spacing: PWSpacing.sm) {
                notificationToggle("Race", icon: "flag.checkered", isOn: $preferences.race)
                notificationToggle("Qualifying", icon: "timer", isOn: $preferences.qualifying)
                notificationToggle("Sprint", icon: "bolt.fill", isOn: $preferences.sprint)
                notificationToggle("Practice", icon: "steeringwheel", isOn: $preferences.practice)
            }

            VStack(alignment: .leading, spacing: PWSpacing.xs) {
                PWTypography.SectionLabel(text: "Remind me")
                Picker("Lead time", selection: $preferences.leadTimeMinutes) {
                    Text("15 min before").tag(15)
                    Text("30 min before").tag(30)
                    Text("60 min before").tag(60)
                }
                .pickerStyle(.segmented)
            }
            .padding(PWSpacing.md)
            .pwCardBackground()

            Spacer()
        }
        .padding(.horizontal, PWSpacing.screenPadding)
    }

    private func notificationToggle(_ title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: PWSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PWColors.accent)
                    .frame(width: 24)
                Text(title)
                    .font(PWTypography.bodyMedium)
                    .foregroundStyle(PWColors.textPrimary)
            }
        }
        .tint(PWColors.accent)
        .padding(PWSpacing.md)
        .pwCardBackground()
    }
}

/// Step 5 — Summary.
struct SummaryStepView: View {
    let model: OnboardingFlowModel
    let constructors: [Constructor]

    var body: some View {
        VStack(alignment: .leading, spacing: PWSpacing.lg) {
            stepHeader(title: "You're all set",
                       subtitle: "Here's your pit wall. Change anything later in Settings.")

            if let constructorID = model.selectedConstructorID,
               let constructor = constructors.first(where: { $0.id == constructorID }) {
                ConstructorCard(constructor: constructor, isSelected: true, action: {})
            }

            if !model.selectedDriverIDs.isEmpty {
                VStack(alignment: .leading, spacing: PWSpacing.sm) {
                    PWTypography.SectionLabel(text: "Followed drivers")
                    FlowChipsView(items: model.selectedDriverIDs.compactMap { id in
                        MockRoster.driver(for: id)?.fullName
                    }.sorted())
                }
            }

            VStack(alignment: .leading, spacing: PWSpacing.sm) {
                PWTypography.SectionLabel(text: "Reminders")
                HStack(spacing: PWSpacing.xs) {
                    PWTag(text: "Race", color: PWColors.accent, filled: model.notifications.race)
                    PWTag(text: "Quali", color: PWColors.accent, filled: model.notifications.qualifying)
                    PWTag(text: "Sprint", color: PWColors.accent, filled: model.notifications.sprint)
                    PWTag(text: "Practice", color: PWColors.accent, filled: model.notifications.practice)
                }
                Text("Lead time: \(model.notifications.leadTimeMinutes) minutes")
                    .font(PWTypography.caption)
                    .foregroundStyle(PWColors.textTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, PWSpacing.screenPadding)
    }
}

/// Wrapping chip row for compact summaries.
struct FlowChipsView: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: PWSpacing.xs)], spacing: PWSpacing.xs) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(PWTypography.captionMedium)
                    .foregroundStyle(PWColors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(PWColors.surfaceElevated))
            }
        }
    }
}

/// Shared step header copy.
extension View {
    func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: PWSpacing.xs) {
            Text(title)
                .font(PWTypography.screenTitle)
                .foregroundStyle(PWColors.textPrimary)
            Text(subtitle)
                .font(PWTypography.caption)
                .foregroundStyle(PWColors.textTertiary)
        }
    }
}

#Preview("Welcome") {
    WelcomeStepView {}
        .background(OnboardingBackground())
}

#Preview("Notifications Step") {
    NotificationStepView(preferences: .constant(.default))
        .background(OnboardingBackground())
}
