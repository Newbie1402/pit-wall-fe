import Foundation

/// Async screen state: loading → loaded, or loading → failed.
/// `empty` is expressed as `loaded` with an empty payload and rendered by
/// dedicated empty-state views, keeping the state machine simple.
enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .failed(let message) = self { return message }
        return nil
    }
}

/// Maps repository-layer errors to user-facing messages.
enum PWErrorMapper {

    static func message(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.userMessage
        }
        return "Please check your connection and try again."
    }
}
