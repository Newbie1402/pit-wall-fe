import SwiftUI

/// Settings sub-screen for changing the favorite constructor.
struct FavoriteTeamEditorView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    @State private var constructors: [Constructor] = []

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: PWSpacing.sm),
                                GridItem(.flexible(), spacing: PWSpacing.sm)],
                      spacing: PWSpacing.sm) {
                ForEach(constructors) { constructor in
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
        .navigationTitle("FAVORITE TEAM")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if constructors.isEmpty {
                constructors = (try? await environment.constructorRepository.constructors()) ?? []
            }
        }
    }
}

/// Settings sub-screen for changing favorite drivers.
struct FavoriteDriversEditorView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    @State private var drivers: [Driver] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PWSpacing.md) {
                Text(environment.preferences.favoriteDriverIDs.isEmpty
                     ? "Follow at least one driver."
                     : "\(environment.preferences.favoriteDriverIDs.count) followed")
                    .font(PWTypography.caption)
                    .foregroundStyle(PWColors.textTertiary)

                DriverSelectionList(
                    drivers: drivers,
                    constructors: MockRoster.constructors,
                    selectedIDs: Binding(
                        get: { environment.preferences.favoriteDriverIDs },
                        set: { environment.preferences.favoriteDriverIDs = $0 }
                    )
                )
            }
            .pwSectionSpacing()
            .padding(.vertical, PWSpacing.md)
        }
        .navigationTitle("FAVORITE DRIVERS")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if drivers.isEmpty {
                drivers = (try? await environment.driverRepository.drivers()) ?? []
            }
        }
    }
}
