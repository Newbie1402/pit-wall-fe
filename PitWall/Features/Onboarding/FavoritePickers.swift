import SwiftUI

/// Selectable constructor cell, shared by onboarding and Settings.
struct ConstructorCard: View {
    let constructor: Constructor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PWSpacing.sm) {
                RoundedRectangle(cornerRadius: PWRadius.sm, style: .continuous)
                    .fill(TeamPalette.color(for: constructor))
                    .frame(width: 8, height: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(constructor.shortName)
                        .font(PWTypography.rowTitle)
                        .foregroundStyle(PWColors.textPrimary)
                        .lineLimit(1)
                    Text(constructor.countryFlag)
                        .font(PWTypography.caption)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? PWColors.accent : PWColors.textTertiary)
            }
            .padding(PWSpacing.md)
            .pwCardBackground(
                color: isSelected ? PWColors.accentSoft : PWColors.surface,
                radius: PWRadius.md
            )
            .overlay(
                RoundedRectangle(cornerRadius: PWRadius.md, style: .continuous)
                    .strokeBorder(isSelected ? PWColors.accent : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(constructor.shortName), \(isSelected ? "selected" : "not selected")")
        .accessibilityAddTraits(.isButton)
    }
}

/// Grouped, multi-select driver list, shared by onboarding and Settings.
struct DriverSelectionList: View {
    let drivers: [Driver]
    let constructors: [Constructor]
    @Binding var selectedIDs: Set<String>

    var body: some View {
        VStack(spacing: PWSpacing.md) {
            ForEach(constructors) { constructor in
                let teamDrivers = drivers.filter { $0.constructorID == constructor.id }
                if !teamDrivers.isEmpty {
                    VStack(alignment: .leading, spacing: PWSpacing.xs) {
                        HStack(spacing: PWSpacing.xs) {
                            TeamColorBar(color: TeamPalette.color(for: constructor))
                            Text(constructor.shortName.uppercased())
                                .font(PWTypography.sectionHeader)
                                .foregroundStyle(PWColors.textTertiary)
                                .kerning(1.4)
                        }
                        .padding(.top, PWSpacing.xxs)

                        ForEach(teamDrivers) { driver in
                            driverRow(driver)
                        }
                    }
                }
            }
        }
    }

    private func driverRow(_ driver: Driver) -> some View {
        let isSelected = selectedIDs.contains(driver.id)
        return Button {
            if selectedIDs.contains(driver.id) {
                selectedIDs.remove(driver.id)
            } else {
                selectedIDs.insert(driver.id)
            }
        } label: {
            HStack(spacing: PWSpacing.sm) {
                Text(driver.code)
                    .font(PWTypography.rowTitle)
                    .foregroundStyle(PWColors.textSecondary)
                    .frame(width: 44, alignment: .leading)
                VStack(alignment: .leading, spacing: 1) {
                    Text(driver.fullName)
                        .font(PWTypography.bodyMedium)
                        .foregroundStyle(PWColors.textPrimary)
                    Text("#\(driver.number)")
                        .font(PWTypography.caption)
                        .foregroundStyle(PWColors.textTertiary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? PWColors.accent : PWColors.textTertiary)
                    .font(.system(size: 18))
            }
            .padding(.vertical, PWSpacing.sm)
            .padding(.horizontal, PWSpacing.md)
            .pwCardBackground(color: isSelected ? PWColors.accentSoft : PWColors.surface, radius: PWRadius.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(driver.fullName), \(isSelected ? "selected" : "not selected")")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Favorite Pickers") {
    ScrollView {
        VStack(spacing: 16) {
            ConstructorCard(constructor: MockRoster.constructors[0], isSelected: true, action: {})
            ConstructorCard(constructor: MockRoster.constructors[2], isSelected: false, action: {})
            DriverSelectionList(
                drivers: MockRoster.drivers,
                constructors: Array(MockRoster.constructors.prefix(2)),
                selectedIDs: .constant(["norris"])
            )
        }
        .padding()
    }
    .background(PWColors.background)
}
