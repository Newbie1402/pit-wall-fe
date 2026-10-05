import SwiftUI

@main
struct PitWallApp: App {

    @State private var environment: AppEnvironment
    @State private var navigation = AppNavigation()

    init() {
        environment = AppEnvironment.live()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .environment(navigation)
                .tint(PWColors.accent)
                .preferredColorScheme(environment.preferences.appearance.colorScheme)
                .onOpenURL { url in
                    if let route = DeepLinkParser.route(from: url) {
                        navigation.pushHomeRoute(route)
                    }
                }
        }
    }
}

extension AppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Parses `pitwall://` deep links pushed by widgets. Expected forms:
/// `pitwall://race/{id}`, `pitwall://driver/{id}`, `pitwall://team/{id}`.
enum DeepLinkParser {
    static func route(from url: URL) -> AppRoute? {
        guard url.scheme == "pitwall" else { return nil }
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard let host = url.host(percentEncoded: false), pathComponents.count == 1 else { return nil }

        switch host {
        case "race": return .race(pathComponents[0])
        case "driver": return .driver(pathComponents[0])
        case "team": return .team(pathComponents[0])
        default: return nil
        }
    }
}
