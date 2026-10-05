import Foundation
import Observation

/// Drives the personalized Feed screen.
@MainActor
@Observable
final class FeedViewModel {

    private(set) var state: Loadable<[FeedItem]> = .idle

    private let feedRepository: any FeedRepository
    private let preferences: UserPreferencesStore

    init(feedRepository: any FeedRepository, preferences: UserPreferencesStore) {
        self.feedRepository = feedRepository
        self.preferences = preferences
    }

    func load() async {
        if case .loaded = state { return }
        if state.isLoading { return }
        state = .loading

        do {
            let items = try await feedRepository.feed()
            state = .loaded(FeedPersonalizer.sorted(
                items,
                favoriteDriverIDs: preferences.favoriteDriverIDs,
                favoriteConstructorID: preferences.favoriteConstructorID
            ))
        } catch {
            state = .failed(PWErrorMapper.message(for: error))
        }
    }
}
