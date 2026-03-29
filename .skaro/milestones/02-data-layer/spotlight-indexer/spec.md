# Specification: spotlight-indexer

## Context
Пользователи должны находить книги через системный поиск Spotlight. Индексируются: title, author, genre, series, tags. Содержимое книг НЕ индексируется (производительность). Deep link vreader://open?bookID= обрабатывается в root view.

## User Scenarios
1. **Пользователь ищет "Дюна" в Spotlight:** Находит книгу, тапает → приложение открывается на этой книге.
2. **Книга импортирована:** SpotlightIndexer.index(book:) вызывается автоматически.
3. **Книга удалена:** SpotlightIndexer.deindex(bookID:) удаляет запись из Spotlight.

## Functional Requirements
- FR-01: SpotlightIndexer — actor
- FR-02: func index(book: Book) async — индексация одной книги. Атрибуты: title, author, genre, seriesName, tags, contentDescription (первые 200 символов описания)
- FR-03: func deindex(bookID: UUID) async — удаление из индекса
- FR-04: func reindexAll(books: [Book]) async — полная переиндексация
- FR-05: CSSearchableItem с uniqueIdentifier = "vreader.book.\(bookID)"
- FR-06: CSSearchableItemAttributeSet: title, author (creator), genre (subject), thumbnail (обложка если доступна)
- FR-07: userInfo для deep link: ["bookID": bookID.uuidString]
- FR-08: Обработка deep link в VreaderApp: onOpenURL { url in } → NavigationState.openBook(id:)
- FR-09: URL scheme регистрация в Info.plist: vreader://
- FR-10: Не индексировать содержимое книг — только метаданные

## Non-Functional Requirements
- NFR-01: Индексация не блокирует UI
- NFR-02: Пакетная индексация через CSSearchableIndex.indexSearchableItems (до 100 за раз)

## Boundaries (что НЕ входит)
- Не реализовывать поиск внутри приложения (это LibraryView)
- Не индексировать аннотации
- Не реализовывать Siri Shortcuts

## Acceptance Criteria
- [ ] SpotlightIndexer actor определён
- [ ] index() создаёт CSSearchableItem с корректными атрибутами
- [ ] deindex() удаляет запись
- [ ] Deep link vreader://open?bookID= обрабатывается
- [ ] URL scheme зарегистрирован в Info.plist
- [ ] Содержимое книг НЕ индексируется

## Open Questions
- Нужно ли обновлять Spotlight индекс при изменении метаданных книги?
- Как обрабатывать deep link если приложение не запущено?