# Specification: widget-extension

## Context
WidgetKit extension отображает последнюю читаемую книгу с прогрессом и кнопкой 'Продолжить'. Данные через App Group shared container. Deep link `vreader://open?bookID=`. Размеры: small и medium.

## User Scenarios
1. **Пользователь добавляет виджет на home screen:** Видит обложку текущей книги и прогресс.
2. **Пользователь нажимает 'Продолжить':** Приложение открывается на текущей странице книги.
3. **Пользователь не читает книгу:** Виджет показывает placeholder с призывом открыть библиотеку.

## Functional Requirements
- FR-01: `VReaderWidget` — WidgetKit Widget, поддерживает `.systemSmall` и `.systemMedium`.
- FR-02: `WidgetTimelineProvider` — реализует `TimelineProvider`.
- FR-03: `WidgetEntry` struct: `date: Date`, `bookTitle: String?`, `bookAuthor: String?`, `coverPath: String?`, `progress: Double`, `bookID: UUID?`.
- FR-04: App Group `com.vreader.shared` — shared UserDefaults для передачи данных.
- FR-05: Основное приложение обновляет App Group при изменении `currentBook` в `PlayerState`/`ReaderState`.
- FR-06: Small виджет: только обложка + прогресс bar.
- FR-07: Medium виджет: обложка + название + автор + прогресс + кнопка 'Продолжить'.
- FR-08: Deep link: `Link(destination: URL(string: "vreader://open?bookID=\(id)")!)`.
- FR-09: Timeline обновляется при изменении `currentBook` через `WidgetCenter.shared.reloadAllTimelines()`.
- FR-10: Placeholder если нет текущей книги.
- FR-11: Entitlement `com.apple.security.application-groups` в обоих targets.
- FR-12: Обложка загружается из App Group shared container (копируется при изменении книги).

## Non-Functional Requirements
- NFR-01: Timeline refresh < 1s.
- NFR-02: Виджет не потребляет заметные ресурсы батареи.

## Boundaries (что НЕ входит)
- Не реализовывать large виджет.
- Не реализовывать interactive виджет (iOS 17 interactive widgets — milestone 10).

## Acceptance Criteria
- [ ] Виджет отображается в галерее виджетов.
- [ ] Small и medium размеры работают корректно.
- [ ] Deep link открывает правильную книгу.
- [ ] Данные обновляются при смене книги.
- [ ] Placeholder отображается при отсутствии книги.
- [ ] App Group entitlement настроен в обоих targets.

## Open Questions
- Нужен ли Lock Screen виджет (iOS 16+)?
- Как обрабатывать обложку если файл недоступен из widget extension?