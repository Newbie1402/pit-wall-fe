import SwiftUI

/// Onboarding: Welcome → Team → Drivers → Notifications → Summary.
struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model = OnboardingFlowModel()

    @State private var constructors: Loadable<[Constructor]> = .idle
    @State private var drivers: Loadable<[Driver]> = .idle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            progressBar
                .padding(.horizontal, PWSpacing.screenPadding)
                .padding(.top, PWSpacing.sm)

            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            actionBar
                .padding(.horizontal, PWSpacing.screenPadding)
                .padding(.bottom, PWSpacing.lg)
        }
        .background(OnboardingBackground())
        .task { await loadReferenceData() }
        .animation(reduceMotion ? nil : .snappy(duration: 0.32), value: model.step)
    }

    // MARK: - Progress

    private var progressBar: some View {
        VStack(spacing: PWSpacing.xs) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(PWColors.surfaceSunken)
                    Capsule()
                        .fill(PWColors.accent)
                        .frame(width: max(12, proxy.size.width * model.progress))
                }
            }
            .frame(height: 4)

            HStack {
                if model.step != .welcome {
                    Button(action: model.goBack) {
                        Label("Back", systemImage: "chevron.left")
                            .font(PWTypography.captionMedium)
                            .foregroundStyle(PWColors.textSecondary)
                    }
                }
                Spacer()
                Text("STEP \(model.step.rawValue + 1) OF \(OnboardingFlowModel.Step.allCases.count)")
                    .font(PWTypography.microCaps)
                    .kerning(1.4)
                    .foregroundStyle(PWColors.textTertiary)
            }
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private var stepContent: some View {
        switch model.step {
        case .welcome:
            WelcomeStepView {
                model.advance()
            }
        case .team:
            TeamStepView(
                constructors: constructors,
                selection: Binding(
                    get: { model.selectedConstructorID },
                    set: { model.selectedConstructorID = $0 }
                )
            )
        case .drivers:
            DriverStepView(
                drivers: drivers,
                constructors: constructors.value ?? [],
                selectedIDs: Binding(
                    get: { model.selectedDriverIDs },
                    set: { model.selectedDriverIDs = $0 }
                )
            )
        case .notifications:
            NotificationStepView(preferences: Binding(
                get: { model.notifications },
                set: { model.notifications = $0 }
            ))
        case .summary:
            SummaryStepView(model: model, constructors: constructors.value ?? [])
        }
    }

    // MARK: - Actions

    private var actionBar: some View {
        HStack(spacing: PWSpacing.sm) {
            if model.step != .welcome {
                Button {
                    model.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(PWColors.textPrimary)
                        .frame(width: 52, height: 50)
                        .pwCardBackground(color: PWColors.surfaceElevated, radius: PWRadius.md)
                }
                .accessibilityLabel("Back")
            }

            PWButton(
                title: model.step == .summary ? "Enter PitWall" : (model.step == .welcome ? "Get Started" : "Continue"),
                icon: model.step == .summary ? "flag.checkered" : nil,
                isLoading: model.isCompleting
            ) {
                if model.step == .summary {
                    Task { await model.complete(environment: environment) }
                } else {
                    model.advance()
                }
            }
            .opacity(model.canProceed || model.step == .summary || model.step == .welcome ? 1 : 0.5)
            .disabled(!(model.canProceed || model.step == .summary || model.step == .welcome))
        }
    }

    // MARK: - Data

    private func loadReferenceData() async {
        constructors = .loading
        drivers = .loading
        do {
            let loadedConstructors = try await environment.constructorRepository.constructors()
            let loadedDrivers = try await environment.driverRepository.drivers()
            constructors = .loaded(loadedConstructors)
            drivers = .loaded(loadedDrivers)
        } catch {
            constructors = .failed(PWErrorMapper.message(for: error))
            drivers = .failed(PWErrorMapper.message(for: error))
        }
    }
}

/// Soft gradient backdrop shared by onboarding steps.
struct OnboardingBackground: View {
    var body: some View {
        ZStack {
            PWColors.background
            LinearGradient(
                colors: [PWColors.accent.opacity(0.16), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

#Preview("Onboarding") {
    OnboardingView()
        .environment(AppEnvironment.preview(preferences: UserPreferencesStore(
            defaults: UserDefaults(suiteName: "preview-ob-\(UUID().uuidString)"))))
}
