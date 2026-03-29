# Specification: main-tab-view

## Context
`ContentView` / `MainTabView` — корневой контейнер приложения с TabView: library, reading, catalogs, settings. Существующие `ContentView.swift` и `MainTabView.swift` требуют ревизии.

## User Scenarios
1. **Пользователь запускает приложение:** Видит TabView с 4 вкладками, открывается последняя активная вкладка.
2. **Deep link открывает книгу:** Автоматически переключается на вкладку library/reading.
3. **Пользователь в ридере:** Нижний TabBar скрывается для immersive чтения.

## Functional Requirements
- FR-01: `MainTabView` — SwiftUI View с `TabView`.
- FR-02: Вкладки: `.library` (иконка books.vertical), `.reading` (иконка book.open), `.catalogs` (иконка network), `.settings` (иконка gear).
- FR-03: Все строки через `L10n.*`.
- FR-04: Тема через `@Environment(\.appTheme)`.
- FR-05: `NavigationState`, `LibraryState`, `PlayerState`, `ReaderState` инжектируются через `.environment()`.
- FR-06: `onOpenURL` обрабатывает URL schemes через `NavigationState.handleURL`.
- FR-07: TabBar скрывается при `ReaderState.isFullscreen == true`.
- FR-08: Badge на вкладке reading если есть активная аудиокнига (`PlayerState.isPlaying`).
- FR-09: `ModelContainer` инжектируется через `.modelContainer()`.

## Non-Functional Requirements
- NFR-01: Переключение вкладок < 100ms.

## Boundaries (что НЕ входит)
- Не реализовывать содержимое вкладок — только контейнер.

## Acceptance Criteria
- [ ] 4 вкладки отображаются корректно.
- [ ] URL scheme обрабатывается и переключает нужную вкладку.
- [ ] Тема применяется корректно.
- [ ] Все строки через L10n.
- [ ] Существующие ContentView.swift и MainTabView.swift обновлены.

## Open Questions
- Использовать `TabView` с `.tabViewStyle(.automatic)` или кастомный TabBar?
- Нужна ли анимация при переключении вкладок?