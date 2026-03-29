# Specification: notes-toc-panels

## Context
Панели ридера для навигации по оглавлению и управления аннотациями. Открываются как sheets из ReaderTopBar.

## User Scenarios
1. **Пользователь открывает TOC:** Видит список глав, тапает → переходит к главе.
2. **Пользователь открывает Notes:** Видит все закладки, хайлайты, заметки. Тапает → переходит к позиции.
3. **Пользователь удаляет аннотацию:** Swipe-to-delete в NotesPanel.

## Functional Requirements
- FR-01: `TOCPanel` — SwiftUI View (sheet), принимает `handler: any FileFormatHandler`, `onNavigate: (Int) -> Void`.
- FR-02: `TOCPanel` отображает список глав из `handler.tableOfContents()` (новый метод protocol).
- FR-03: Текущая глава выделена в списке.
- FR-04: `NotesPanel` — SwiftUI View (sheet), принимает `bookID: UUID`.
- FR-05: `NotesPanel` загружает аннотации через `@Query` с фильтром по `bookID`.
- FR-06: Три секции: Закладки, Хайлайты, Заметки.
- FR-07: Каждая аннотация: текст (snippet), глава, дата, цвет (для хайлайтов).
- FR-08: Тап на аннотацию → `onNavigate(pageIndex)` callback.
- FR-09: Swipe-to-delete удаляет аннотацию через `LibraryModelActor`.
- FR-10: Все строки через `L10n.*`.

## Non-Functional Requirements
- NFR-01: Открытие панели < 200ms.

## Boundaries (что НЕ входит)
- Не реализовывать редактирование аннотаций — только просмотр и удаление.
- Не реализовывать экспорт аннотаций.

## Acceptance Criteria
- [ ] TOCPanel отображает главы и навигирует корректно.
- [ ] NotesPanel отображает все типы аннотаций.
- [ ] Удаление аннотации работает.
- [ ] Текущая глава выделена в TOC.

## Open Questions
- Нужна ли поддержка вложенных глав (subchapters) в TOC?
- Как отображать аннотации для PDF (по номеру страницы, не главе)?