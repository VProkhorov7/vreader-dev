# Specification: cover-fetcher

## Context
Архитектурный инвариант #6: обложки хранятся только в `Documents/Covers/{bookID}.jpg`, в SwiftData только `coverPath: String`. Существующий `CoverFetcher.swift` требует ревизии.

## User Scenarios
1. **Книга импортируется:** Обложка извлекается из файла (EPUB, FB2) и сохраняется в Documents/Covers/.
2. **Обложка не найдена в файле:** Генерируется placeholder с первой буквой названия.
3. **Пользователь запрашивает обновление обложки:** Long press на карточке → повторный запрос к MetadataFetcher.

## Functional Requirements
- FR-01: `CoverFetcher` — final class, singleton `shared`.
- FR-02: `extractCover(from book: Book) async throws -> String?` — извлекает обложку из файла, возвращает `coverPath`.
- FR-03: Сохраняет обложку в `Documents/Covers/{bookID}.jpg` (JPEG, качество 0.85).
- FR-04: Максимальный размер обложки: 512x512pt (масштабирует если больше).
- FR-05: `saveCover(_ image: UIImage, for bookID: UUID) async throws -> String` — сохраняет обложку из внешнего источника (MetadataFetcher).
- FR-06: `loadCover(for bookID: UUID) -> URL?` — возвращает URL для AsyncImage.
- FR-07: `deleteCover(for bookID: UUID) async` — удаляет файл обложки.
- FR-08: Placeholder генерируется если обложка не найдена (не сохраняется — генерируется в UI).
- FR-09: Обновляет `book.coverPath` через `LibraryModelActor`.

## Non-Functional Requirements
- NFR-01: Извлечение обложки < 500ms.
- NFR-02: Не хранит `UIImage` в памяти после сохранения.

## Boundaries (что НЕ входит)
- Не реализовывать загрузку обложек из Google Books — это MetadataFetcher.
- Не реализовывать UI отображения обложек.

## Acceptance Criteria
- [ ] Обложки EPUB и FB2 извлекаются корректно.
- [ ] Файлы сохраняются в `Documents/Covers/{bookID}.jpg`.
- [ ] `book.coverPath` обновляется после извлечения.
- [ ] `coverData` нигде не используется.
- [ ] Размер файла обложки < 100KB.

## Open Questions
- Нужен ли кэш в памяти для часто используемых обложек?
- Как обрабатывать WebP обложки из EPUB — конвертировать в JPEG?