# Specification: main-tab-view

## Context
MainTabView — корневой контейнер приложения. Четыре вкладки: Library, Reading, Catalogs, Settings. NavigationState управляет активной вкладкой. Deep links (vreader://open?bookID=) обрабатываются здесь и делегируются NavigationState.

## User Scenarios
1. **Пользователь переключает вкладки:** Плавный переход, состояние каждой вкладки сохраняется.
2. **Spotlight deep link:** vreader://open?bookID=XYZ → переключение на Library вкладку → открытие книги.
3. **Фоновое воспроизведение аудио:** Мини-плеер показывается поверх tab bar.

## Functional Requirements
- FR-01: TabView с 4 вкладками: library (книга), reading (текущее чтение), catalogs (поиск), settings (шестерёнка)
- FR-02: NavigationState.selectedTab управляет активной вкладкой
- FR-03: Каждая вкладка имеет NavigationStack с navigationPath из NavigationState
- FR-04: onOpenURL обработчик: vreader://open?bookID= → NavigationState.openBook(id:)
- FR-05: onOpenURL: vreader://library → NavigationState.selectedTab = .library
- FR-06: Мини-плеер (AudioMiniPlayerView) показывается поверх tab bar когда PlayerState.isPlaying == true
- FR-07: Все иконки вкладок через SF Symbols
- FR-08: Все строки через L10n
- FR-09: Поддержка iPad: sidebar navigation вместо tab bar

## Non-Functional Requirements
- NFR-01: Переключение вкладок < 100ms
- NFR-02: Состояние NavigationStack сохраняется при переключении вкладок

## Boundaries (что НЕ входит)
- Не реализовывать содержимое вкладок Reading, Catalogs, Settings полностью
- Не реализовывать AudioMiniPlayerView полностью (заглушка)

## Acceptance Criteria
- [ ] Все 4 вкладки переключаются
- [ ] Deep link vreader://open?bookID= обрабатывается
- [ ] NavigationState управляет активной вкладкой
- [ ] iPad sidebar navigation работает
- [ ] Все строки через L10n

## Open Questions
- Нужна ли анимация badge на вкладке Reading при новых аннотациях?
- Как обрабатывать deep link если приложение только запускается (cold start)?