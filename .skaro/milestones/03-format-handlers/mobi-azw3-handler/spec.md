# Specification: mobi-azw3-handler

## Context
MOBI и AZW3 — форматы Kindle. Требуют открытой реализации парсера (нет нативного Apple API). AZW3 — улучшенный MOBI с KF8 форматом.

## User Scenarios
1. **Пользователь переносит книги с Kindle:** MOBI файлы открываются в VReader.
2. **AZW3 с богатым форматированием:** Таблицы, изображения, сноски отображаются корректно.

## Functional Requirements
- FR-01: `MOBIHandler` — final class, реализует `FileFormatHandler`.
- FR-02: `AZW3Handler` — final class, реализует `FileFormatHandler` (наследует или использует MOBIHandler).
- FR-03: Парсинг PalmDB заголовка для MOBI.
- FR-04: Извлечение HTML контента из MOBI records.
- FR-05: `openPage(_ index: Int)` возвращает `.html`.
- FR-06: `extractMetadata()` — из EXTH заголовка: title, author, publisher, ISBN.
- FR-07: `extractCover()` — из EXTH thumbnail record.
- FR-08: Поддержка встроенных изображений.
- FR-09: AZW3: поддержка KF8 (HTML5 + CSS3) контента.
- FR-10: Все ошибки через `AppError` с категорией `.parsing`.

## Non-Functional Requirements
- NFR-01: MOBI 5MB открывается < 2s.

## Boundaries (что НЕ входит)
- Не поддерживать DRM-защищённые Kindle файлы.
- Не поддерживать AZW (старый формат с DRM).

## Acceptance Criteria
- [ ] MOBI без DRM открывается и читается.
- [ ] AZW3 без DRM открывается.
- [ ] Метаданные и обложка извлекаются.
- [ ] Встроенные изображения отображаются.

## Open Questions
- Использовать существующую open-source библиотеку (например, libmobi) или писать с нуля?
- Как обрабатывать MOBI с Huffman/CDIC сжатием?