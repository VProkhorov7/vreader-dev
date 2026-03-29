# Specification: book-detail-view

## Context
Детальный просмотр книги: обложка, метаданные, прогресс, кнопки действий (Читать, Скачать, Удалить). Редактирование метаданных inline. Существующий `BookDetailView.swift` требует ревизии.

## User Scenarios
1. **Пользователь тапает на книгу:** Открывается детальный просмотр с обложкой и метаданными.
2. **Пользователь редактирует название:** Тапает Edit → изменяет поля → сохраняет.
3. **Пользователь нажимает 'Читать' на cloudOnly книге:** Начинается загрузка, кнопка показывает прогресс.

## Functional Requirements
- FR-01: `BookDetailView` — SwiftUI View, принимает `book: Book`.
- FR-02: Секция метаданных: обложка (большая), title, author, series, genre, description, format, fileSize, addedAt, source.
- FR-03: Кнопка 'Читать': для `.downloaded` — открывает ReaderView. Для `.cloudOnly` — запускает загрузку с прогрессом.
- FR-04: Кнопка 'Скачать' для `.cloudOnly` и `.previewed` книг.
- FR-05: Кнопка 'Удалить файл' для `.downloaded` книг (переводит в `.cloudOnly`).
- FR-06: Progress bar для активной загрузки.
- FR-07: `MetadataEditorView` — sheet для редактирования: title, author, series, seriesIndex, genre, tags, description.
- FR-08: `MetadataEditorView` сохраняет через `LibraryModelActor`.
- FR-09: Кнопка 'Обновить метаданные' — повторный запрос к `MetadataFetcher`.
- FR-10: Секция аннотаций: количество закладок, хайлайтов, заметок.
- FR-11: Все строки через `L10n.*`.

## Non-Functional Requirements
- NFR-01: Открытие детального просмотра < 200ms.

## Boundaries (что НЕ входит)
- Не реализовывать список аннотаций — только счётчики.
- Не реализовывать sharing функциональность.

## Acceptance Criteria
- [ ] Все метаданные отображаются корректно.
- [ ] Кнопка 'Читать' работает для всех contentState.
- [ ] MetadataEditorView сохраняет изменения.
- [ ] Прогресс загрузки отображается.
- [ ] Существующий BookDetailView.swift обновлён.

## Open Questions
- Нужен ли swipe-to-dismiss для детального просмотра?
- Как отображать серию книг — ссылка на другие книги серии в библиотеке?