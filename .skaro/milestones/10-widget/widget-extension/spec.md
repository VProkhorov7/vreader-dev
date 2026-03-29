# Specification: widget-extension

## Context
WidgetKit расширение отображает последнюю читаемую книгу с обложкой, прогрессом и кнопкой "Продолжить". Данные передаются через App Group shared container (com.vreader.shared). Deep link vreader://open?bookID= открывает книгу. Entitlement: com.apple.security.application-groups.

## User Scenarios
1. **Пользователь добавляет виджет на домашний экран:** Видит обложку последней книги и прогресс.
2. **Пользователь нажимает "Продолжить":** Приложение открывается на текущей позиции книги.
3. **Книга изменилась:** Timeline provider обновляет виджет.

## Functional Requirements
- FR-01: Отдельный target VReaderWidget в Xcode
- FR-02: Entitlement com.apple.security.application-groups = com.vreader.shared
- FR-03: App Group shared container для передачи данных: последняя книга (title, author, coverPath, progress, bookID)
- FR-04: WidgetTimelineProvider: func getTimeline() → Entry с данными текущей книги
- FR-05: Два размера виджета: small (только обложка + прогресс), medium (обложка + title + author + прогресс + кнопка)
- FR-06: Deep link: Link(destination: URL(string: "vreader://open?bookID=\(bookID)"))
- FR-07: Обновление Timeline при изменении currentBook в основном приложении (через App Group)
- FR-08: Placeholder для виджета без данных
- FR-09: Обложка загружается из shared container (копия из Documents/Covers/)
- FR-10: Прогресс отображается как ProgressView
- FR-11: Все строки через L10n (виджет имеет свой bundle)

## Non-Functional Requirements
- NFR-01: Виджет обновляется при изменении currentBook
- NFR-02: Обложка в shared container < 100KB (сжатая копия)

## Boundaries (что НЕ входит)
- Не реализовывать интерактивный виджет (iOS 17 Interactive Widgets опционально)
- Не реализовывать Lock Screen виджет на этом этапе

## Acceptance Criteria
- [ ] VReaderWidget target создан
- [ ] App Group entitlement настроен
- [ ] Small и medium размеры работают
- [ ] Deep link открывает книгу
- [ ] Timeline обновляется при изменении книги
- [ ] Placeholder отображается
- [ ] Обложка отображается из shared container

## Open Questions
- Нужен ли Lock Screen виджет (circular, rectangular)?
- Как обрабатывать виджет если пользователь не читал ни одной книги?