import Foundation

/// Broken-down countdown to a future instant.
struct CountdownComponents: Equatable, Sendable {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
}

enum CountdownCalculator {

    /// Whole seconds until `target`. Negative when `target` already passed.
    static func totalSeconds(from now: Date, to target: Date) -> Int {
        Int(target.timeIntervalSince(now).rounded(.down))
    }

    /// Days/hours/minutes/seconds until `target`, or nil when the target passed.
    static func components(from now: Date, to target: Date) -> CountdownComponents? {
        let total = totalSeconds(from: now, to: target)
        guard total > 0 else { return nil }

        let days = total / (24 * 3600)
        let hours = (total % (24 * 3600)) / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return CountdownComponents(days: days, hours: hours, minutes: minutes, seconds: seconds)
    }
}

/// Presentation-ready countdown strings, shared with the widgets.
enum CountdownFormatter {

    /// "02 : 14 : 37" — hours:minutes:seconds for same-day sessions.
    static func hourMinuteSecond(_ components: CountdownComponents) -> String {
        String(format: "%02d : %02d : %02d", components.hours, components.minutes, components.seconds)
    }

    /// "3D 14H" — compact form for widgets and tight layouts.
    static func short(_ components: CountdownComponents) -> String {
        if components.days > 0 {
            return String(format: "%dD %dH", components.days, components.hours)
        }
        return String(format: "%02dH %02dM", components.hours, components.minutes)
    }

    /// VoiceOver-friendly, e.g. "2 days, 14 hours, 3 minutes".
    static func accessibilityLabel(_ components: CountdownComponents) -> String {
        var parts: [String] = []
        if components.days > 0 { parts.append("\(components.days) days") }
        if components.hours > 0 { parts.append("\(components.hours) hours") }
        if components.minutes > 0 { parts.append("\(components.minutes) minutes") }
        if parts.isEmpty { parts.append("less than a minute") }
        return parts.joined(separator: ", ")
    }
}
