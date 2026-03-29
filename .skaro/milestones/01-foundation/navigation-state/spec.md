# Specification: navigation-state

## Context
Архитектура запрещает God Object AppState. Состояние разбито на 4 независимых @Observable класса. Существующий AppState.swift нужно рефакторить или заменить. Классы передаются через @Environment.

## User Scenarios
1. **Пользователь переключает вкладку:** NavigationState.selectedTab обновляется, только TabView перерисовывается.
2. **Начинается воспроизведение аудио:** PlayerState.isPlaying = true, только AudioPlayerView реагирует.
3. **Открывается книга в ридере:** ReaderState обновляется независимо от LibraryState.

## Functional Requirements
- FR-01: NavigationState (@Observable, @MainActor): selectedTab (TabItem enum), navigationPath (NavigationPath), func openBook(id: UUID), func navigateTo(tab: TabItem)
- FR-02: LibraryState (@Observable, @MainActor): currentBook (Book?), searchQuery (String), activeFilters ([LibraryFilter]), sortOrder (LibrarySortOrder), isImporting (Bool)
- FR-03: PlayerState (@Observable, @MainActor): currentAudioBook (Book?), playbackPosition (TimeInterval), isPlaying (Bool), playbackRate (Float), func play(), func pause(), func seek(to:)
- FR-04: ReaderState (@Observable, @MainActor): currentPosition (ReadingPosition?), currentChapter (Int), displaySettings (ReaderDisplaySettings), func updatePosition(_:), func nextChapter(), func prevChapter()
- FR-05: Определить TabItem enum: library, reading, catalogs, settings
- FR-06: Определить ReaderDisplaySettings struct: fontSize (CGFloat), lineSpacing (CGFloat), theme (ThemeID), isNightMode (Bool)
- FR-07: Определить ReadingPosition struct: bookID (UUID), page (Int), progress (Double), timestamp (Date)
- FR-08: Зарегистрировать все 4 класса в VreaderApp через .environment()
- FR-09: Существующий AppState.swift рефакторить: либо удалить, либо сделать тонкой обёрткой

## Non-Functional Requirements
- NFR-01: Изменение PlayerState не должно вызывать перерисовку LibraryView
- NFR-02: Все классы @MainActor для безопасности Swift 6

## Boundaries (что НЕ входит)
- Не реализовывать персистентность состояния (это iCloudSettingsStore и NSUbiquitousKeyValueStore)
- Не реализовывать бизнес-логику (только состояние)
- Не реализовывать CloudKit синхронизацию

## Acceptance Criteria
- [ ] Все 4 класса состояния определены и компилируются
- [ ] TabItem enum содержит все 4 вкладки
- [ ] ReaderDisplaySettings и ReadingPosition определены
- [ ] Классы зарегистрированы в VreaderApp
- [ ] Нет единого AppState God Object
- [ ] Swift 6 concurrency warnings отсутствуют

## Open Questions
- Нужно ли LibraryState хранить список всех книг или это делегируется @Query в View?
- Как передавать NavigationState в deep link обработчик в VreaderApp?