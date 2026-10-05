import Foundation

/// Cached, timezone-aware date formatters.
///
/// Backend timestamps arrive as ISO-8601 UTC instants (`Date`). Everything
/// displayed to the user is rendered in the device's local timezone — never a
/// hardcoded one. Formatters accept explicit locale/timezone for testability.
enum PitWallDate {

    /// "20:00"
    static func timeString(from date: Date,
                           timeZone: TimeZone = .current,
                           locale: Locale = .autoupdatingCurrent) -> String {
        formatter(timeZone: timeZone, locale: locale, template: "HH:mm").string(from: date)
    }

    /// "10 OCT"
    static func dayMonthString(from date: Date,
                               timeZone: TimeZone = .current,
                               locale: Locale = .autoupdatingCurrent) -> String {
        formatter(timeZone: timeZone, locale: locale, template: "dd MMM").string(from: date)
            .uppercased()
    }

    /// "FRI 10 OCT"
    static func weekdayDayMonthString(from date: Date,
                                      timeZone: TimeZone = .current,
                                      locale: Locale = .autoupdatingCurrent) -> String {
        formatter(timeZone: timeZone, locale: locale, template: "EEE dd MMM").string(from: date)
            .uppercased()
    }

    /// "10 OCT — 12 OCT" for a weekend window.
    static func dateRangeString(from start: Date, to end: Date,
                                timeZone: TimeZone = .current,
                                locale: Locale = .autoupdatingCurrent) -> String {
        let format = formatter(timeZone: timeZone, locale: locale, template: "dd MMM")
        let startString = format.string(from: start).uppercased()
        let endString = format.string(from: end).uppercased()
        return "\(startString) — \(endString)"
    }

    /// "OCTOBER 2026"
    static func monthYearString(from date: Date,
                                timeZone: TimeZone = .current,
                                locale: Locale = .autoupdatingCurrent) -> String {
        formatter(timeZone: timeZone, locale: locale, template: "MMMM y").string(from: date)
            .uppercased()
    }

    /// Relative feed timestamps: "2h ago", "just now", "3d ago".
    static func relativeTimeString(from date: Date, relativeTo now: Date = Date()) -> String {
        let interval = max(0, now.timeIntervalSince(date))
        let minutes = interval / 60
        switch minutes {
        case ..<1:
            return "just now"
        case ..<60:
            return "\(Int(minutes))m ago"
        case ..<(60 * 24):
            return "\(Int(minutes / 60))h ago"
        default:
            return "\(Int(minutes / (60 * 24)))d ago"
        }
    }

    /// Local date components matching a UTC instant — used to build
    /// notification calendar triggers in the user's timezone.
    static func localDateComponents(for date: Date,
                                    timeZone: TimeZone = .current) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }

    // MARK: - Internals

    private static var cache: [String: DateFormatter] = [:]
    private static let lock = NSLock()

    private static func formatter(timeZone: TimeZone,
                                  locale: Locale,
                                  template: String) -> DateFormatter {
        let key = "\(template)|\(timeZone.identifier)|\(locale.identifier)"
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[key] { return cached }
        let format = DateFormatter()
        format.setLocalizedDateFormatFromTemplate(template)
        format.timeZone = timeZone
        format.locale = locale
        cache[key] = format
        return format
    }
}
