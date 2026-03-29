# Specification: text-handlers

## Context
TXT и RTF — простые текстовые форматы. TXT требует автодетекта кодировки. RTF обрабатывается через NSAttributedString. Разбивка на страницы — по количеству символов или абзацев.

## User Scenarios
1. **Пользователь открывает TXT в Windows-1251:** Кодировка автоматически определяется, текст читается корректно.
2. **Пользователь открывает RTF с форматированием:** Жирный, курсив, заголовки сохраняются.
3. **TXT файл 10MB:** Разбивается на страницы без загрузки всего файла в память.

## Functional Requirements
- FR-01: `TXTHandler` — final class, реализует `FileFormatHandler`.
- FR-02: `RTFHandler` — final class, реализует `FileFormatHandler`.
- FR-03: `TXTHandler`: автодетект кодировки (UTF-8, UTF-16, Windows-1251, KOI8-R, ISO-8859-1).
- FR-04: `TXTHandler`: разбивка на страницы по `\n\n` (абзацы), максимум 3000 слов на страницу.
- FR-05: `TXTHandler.openPage(_ index: Int)` возвращает `.text(AttributedString, pageIndex:)`.
- FR-06: `RTFHandler`: использует `NSAttributedString(data:options:documentAttributes:)` с `.rtf` тип.
- FR-07: `RTFHandler.openPage(_ index: Int)` возвращает `.html` или `.text` с форматированием.
- FR-08: `pageCount()` для TXT — вычисляется при первом открытии, кэшируется.
- FR-09: Streaming для больших TXT файлов — не загружает весь файл в память.
- FR-10: `extractMetadata()` — для TXT: первая строка как title. Для RTF: из document attributes.

## Non-Functional Requirements
- NFR-01: TXT 10MB открывается < 1s (только первая страница).
- NFR-02: Streaming — максимум 1MB в памяти одновременно.

## Boundaries (что НЕ входит)
- Не поддерживать DOCX или ODT.
- Не реализовывать редактирование TXT.

## Acceptance Criteria
- [ ] TXT в UTF-8 и Windows-1251 открывается корректно.
- [ ] RTF с базовым форматированием отображается.
- [ ] Разбивка на страницы работает для больших файлов.
- [ ] Streaming не загружает весь файл в память.

## Open Questions
- Как определять границы страниц для TXT с reflow при изменении размера шрифта?
- Нужна ли поддержка TXT с Markdown разметкой?