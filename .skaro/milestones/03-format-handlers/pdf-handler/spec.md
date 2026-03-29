# Specification: pdf-handler

## Context
PDF обрабатывается через нативный PDFKit. Требует поддержки аннотаций (highlight, bookmark) и поиска по тексту.

## User Scenarios
1. **Пользователь открывает PDF учебник:** Страницы отображаются с правильным масштабом.
2. **Пользователь выделяет текст в PDF:** Создаётся аннотация типа `.highlight`.
3. **Пользователь ищет слово в PDF:** Находит все вхождения с навигацией.

## Functional Requirements
- FR-01: `PDFHandler` — final class, реализует `FileFormatHandler`.
- FR-02: Использует `PDFDocument` из PDFKit.
- FR-03: `openPage(_ index: Int)` — рендерит страницу в `UIImage`, возвращает `.image`.
- FR-04: `pageCount()` — `PDFDocument.pageCount`.
- FR-05: `extractMetadata()` — из `PDFDocument.documentAttributes`: title, author, subject.
- FR-06: `extractCover()` — рендер первой страницы как thumbnail.
- FR-07: `searchText(_ query: String) async throws -> [SearchResult]` — поиск через `PDFDocument.findString`.
- FR-08: `SearchResult` struct: `pageIndex: Int`, `bounds: CGRect`, `snippet: String`.
- FR-09: Рендеринг страницы в `UIImage` с разрешением 2x для Retina.
- FR-10: Все ошибки через `AppError` с категорией `.parsing`.

## Non-Functional Requirements
- NFR-01: Рендеринг страницы A4 < 500ms.
- NFR-02: Размер рендеренной страницы ≤ 50MB.

## Boundaries (что НЕ входит)
- Не реализовывать PDF редактирование или заполнение форм.
- Не реализовывать PDF подпись.

## Acceptance Criteria
- [ ] PDF открывается и страницы рендерятся корректно.
- [ ] Метаданные извлекаются из PDF.
- [ ] Поиск по тексту работает.
- [ ] Размер страницы в памяти ≤ 50MB.

## Open Questions
- Как обрабатывать защищённые паролем PDF?
- Нужна ли поддержка PDF с формами (AcroForm)?