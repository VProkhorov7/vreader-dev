# Specification: navigation-state

## Context
Архитектура запрещает God Object. Состояние разделено на 4 @Observable класса, передаваемых через @Environment. URL schemes: `vreader://oauth/callback`, `vreader://open?bookID=`, `vreader://library`.

## User Scenarios
1. **Пользователь тапает на книгу в Spotlight:** `vreader://open?bookID=XYZ` → `NavigationState.openBook(id:)` → открывается ридер.
2. **OAuth callback:** `vreader://oauth/callback?code=&state=` → `OAuthManager` обрабатывает.
3. **Пользователь переключает вкладки:** `NavigationState.selectedTab` обновляется, UI реагирует.

## Functional Requirements
- FR-01: `NavigationState` — @Observable final class: `selectedTab: AppTab`, `navigationPath: NavigationPath`, `func openBook(id: UUID)`, `func handleURL(_ url: URL) -> Bool`.
- FR-02: `AppTab` enum: `.library`, `.reading`, `.catalogs`, `.settings`.
- FR-03: `LibraryState` — @Observable final class: `currentBook: Book?`, `searchQuery: String`, `activeFilters: LibraryFilters`, `sortOrder: LibrarySortOrder`.
- FR-04: `LibraryFilters` struct: `genre: String?`, `format: BookFormat?`, `contentState: BookContentState?`, `isFinished: Bool?`.
- FR-05: `PlayerState` — @Observable final class: `currentAudioBook: Book?`, `playbackPosition: TimeInterval`, `isPlaying: Bool`, `currentChapterIndex: Int`.
- FR-06: `ReaderState` — @Observable final class: `currentPosition: ReadingPosition`, `currentChapter: String`, `displaySettings: DisplaySettings`.
- FR-07: `DisplaySettings` struct: `fontSize: Double`, `lineSpacing: Double`, `fontFamily: String`, `isNightMode: Bool`.
- FR-08: `ReadingPosition` struct: `bookID: UUID`, `pageIndex: Int`, `chapterID: String`, `characterOffset: Int`.
- FR-09: `handleURL` обрабатывает все зарегистрированные URL schemes.
- FR-10: Все классы передаются через `@Environment` в `VreaderApp`.

## Non-Functional Requirements
- NFR-01: Изменение состояния публикуется на main thread.
- NFR-02: Нет retain cycles между state объектами.

## Boundaries (что НЕ входит)
- Не реализовывать конкретные экраны.
- Не реализовывать OAuthManager.

## Acceptance Criteria
- [ ] Все 4 state класса определены и компилируются.
- [ ] `handleURL` корректно парсит все URL schemes.
- [ ] State объекты доступны через `@Environment` в любом view.
- [ ] Нет предупреждений Swift 6 о concurrency.

## Open Questions
- Нужен ли `NavigationPath` для deep navigation или достаточно `selectedTab`?
- Как сохранять состояние навигации при сворачивании приложения?