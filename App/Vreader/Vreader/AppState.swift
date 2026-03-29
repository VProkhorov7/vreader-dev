import SwiftUI
import Combine

enum TabTag: String, CaseIterable, Hashable {
    case library  = "library"
    case reading  = "reading"
    case catalogs = "catalogs"
}

// TODO: Refactor per ADR-009 - split into NavigationState, LibraryState, PlayerState, ReaderState
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var selectedTab: TabTag = .library
    @Published var currentBook: Book?  = nil
    @Published var showSettings: Bool  = false

    private init() {}

    /// Возврат на главный экран библиотеки
    func goHome() {
        selectedTab = .library
    }
}
