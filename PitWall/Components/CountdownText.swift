import SwiftUI

/// Ticking countdown to a target instant.
///
/// Uses `TimelineView` so it re-renders once per second without owning a
/// timer. Renders day/hour/minute/second segments joined by " : "; the days
/// segment is dropped when the target is under 24 hours away.
struct CountdownText: View {
    let target: Date
    var font: Font = PWTypography.countdown()
    var color: Color = PWColors.textPrimary

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(displayText(from: context.date))
                .font(font)
                .monospacedDigit()
                .foregroundStyle(color)
                .kerning(1.0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(from: Date()))
    }

    private func components(from date: Date) -> CountdownComponents? {
        CountdownCalculator.components(from: date, to: target)
    }

    private func displayText(from date: Date) -> String {
        guard let components = components(from: date) else {
            return "00 : 00 : 00"
        }
        var segments: [String] = []
        if components.days > 0 { segments.append(String(format: "%02d", components.days)) }
        segments.append(String(format: "%02d", components.hours))
        segments.append(String(format: "%02d", components.minutes))
        segments.append(String(format: "%02d", components.seconds))
        return segments.joined(separator: " : ")
    }

    private func accessibilityText(from date: Date) -> String {
        guard let components = components(from: date) else {
            return "Starting now"
        }
        return CountdownFormatter.accessibilityLabel(components)
    }
}

#Preview("CountdownText") {
    VStack(spacing: 24) {
        CountdownText(target: Date().addingTimeInterval(3 * 86_400 + 14 * 3600 + 37 * 60))
            .font(PWTypography.countdown())
        CountdownText(target: Date().addingTimeInterval(2 * 3600 + 14 * 60 + 37))
    }
    .padding()
    .background(PWColors.background)
}
