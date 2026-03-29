# Specification: fb2-handler

## Context
FB2 — популярный формат в русскоязычном сегменте. Требует XML парсера. FB2.ZIP — сжатый FB2. Поддержка кириллицы критична для целевой аудитории.

## User Scenarios
1. **Пользователь открывает FB2 с кириллицей:** Текст отображается корректно в UTF-8 и Windows-1251.
2. **FB2.ZIP файл:** Автоматически распаковывается и обрабатывается.
3. **FB2 с встроенными изображениями (base64):** Изображения отображаются в тексте.

## Functional Requirements
- FR-01: `FB2Handler` — final class, реализует `FileFormatHandler`.
- FR-02: Парсит FB2 XML через `XMLParser` (SAX, не DOM для экономии памяти).
- FR-03: FB2.ZIP: распаковывает в памяти, затем парсит XML.
- FR-04: `openPage(_ index: Int)` — разбивает на главы по `<section>` тегам, возвращает `.html`.
- FR-05: `extractMetadata()` — из `<title-info>`: book-title, author, genre, annotation, date, lang.
- FR-06: `extractCover()` — из `<coverpage>` → base64 изображение.
- FR-07: Поддержка кодировок: UTF-8, Windows-1251 (автодетект через XML declaration).
- FR-08: Встроенные изображения (base64 в `<binary>`) — декодируются при запросе страницы.
- FR-09: `pageCount()` — количество `<section>` верхнего уровня.
- FR-10: Все ошибки через `AppError` с категорией `.parsing`.

## Non-Functional Requirements
- NFR-01: SAX парсинг — не загружает весь XML в память.
- NFR-02: FB2 файл 5MB парсируется < 2s.

## Boundaries (что НЕ входит)
- Не реализовывать FB2 запись/экспорт.
- Не поддерживать FB2 v1.0 (только v2.0+).

## Acceptance Criteria
- [ ] FB2 с кириллицей (UTF-8 и Windows-1251) открывается корректно.
- [ ] FB2.ZIP распаковывается и читается.
- [ ] Метаданные и обложка извлекаются.
- [ ] Встроенные изображения отображаются.
- [ ] SAX парсинг не загружает весь файл в память.

## Open Questions
- Как обрабатывать FB2 с несколькими книгами в одном файле (anthology)?
- Нужна ли поддержка FictionBook 1.0?