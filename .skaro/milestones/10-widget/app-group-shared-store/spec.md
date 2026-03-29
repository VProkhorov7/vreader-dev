# Specification: app-group-shared-store

## Context
Widget расширение не имеет доступа к SwiftData основного приложения. AppGroupSharedStore использует UserDefaults(suiteName: "group.com.vreader.shared") для передачи минимального набора данных: последняя книга, прогресс, путь к обложке.

## User Scenarios
1. **Пользователь открывает книгу:** Основное приложение обновляет AppGroupSharedStore.currentBook.
2. **Widget запрашивает данные:** WidgetTimelineProvider читает из AppGroupSharedStore.
3. **Прогресс обновился:** AppGroupSharedStore обновляется, WidgetCenter.shared.reloadAllTimelines().

## Functional Requirements
- FR-01: AppGroupSharedStore — struct с static методами
- FR-02: Использует UserDefaults(suiteName: "group.com.vreader.shared")
- FR-03: struct WidgetBookData: Codable — title, author, bookID (String), progress (Double), coverFileName (String?)
- FR-04: static func saveCurrentBook(_ data: WidgetBookData) — сохранение
- FR-05: static func loadCurrentBook() -> WidgetBookData? — загрузка
- FR-06: static func saveCoverToSharedContainer(bookID: UUID, imageData: Data) — копирование обложки в App Group container
- FR-07: При обновлении currentBook: WidgetCenter.shared.reloadAllTimelines()
- FR-08: Обложка сжимается до < 100KB перед сохранением в shared container
- FR-09: Интеграция с ReaderState: при изменении currentPosition → обновить AppGroupSharedStore

## Non-Functional Requirements
- NFR-01: Запись в shared store < 50ms
- NFR-02: Shared container не превышает разумный размер (< 5MB)

## Boundaries (что НЕ входит)
- Не хранить credentials в App Group container
- Не хранить полные данные книги

## Acceptance Criteria
- [ ] AppGroupSharedStore реализован
- [ ] WidgetBookData сохраняется и загружается
- [ ] Обложка копируется в shared container
- [ ] WidgetCenter.reloadAllTimelines() вызывается при обновлении
- [ ] Обложка < 100KB
- [ ] Нет credentials в shared container

## Open Questions
- Нужно ли хранить историю последних N книг для виджета?
- Как обрабатывать удаление книги — очищать shared store?