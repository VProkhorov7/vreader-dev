# Specification: epub-handler

## Context
EPUB — основной формат электронных книг. Требует нативного парсера (ZIP + OPF + HTML). Существующий `EPUBParser.swift` и `EPUBReaderView.swift` требуют ревизии и интеграции с новым protocol.

## User Scenarios
1. **Пользователь открывает EPUB 3 с CSS:** Текст отображается с правильным форматированием.
2. **EPUB содержит встроенные шрифты:** Шрифты применяются в ридере.
3. **EPUB с RTL текстом (арабский):** Правильное направление текста.

## Functional Requirements
- FR-01: `EPUBHandler` — final class, реализует `FileFormatHandler`.
- FR-02: Распаковывает ZIP в памяти (не на диск).
- FR-03: Парсит `container.xml` → `content.opf` → spine для порядка страниц.
- FR-04: `openPage(_ index: Int)` возвращает `.html(String, baseURL: URL?, pageIndex: Int)` для каждой главы spine.
- FR-05: `extractMetadata()` парсит Dublin Core из OPF: title, author, language, publisher, date, ISBN.
- FR-06: `extractCover()` — из OPF manifest (cover-image) или первого изображения.
- FR-07: Поддержка EPUB 2 и EPUB 3.
- FR-08: `pageCount()` возвращает количество элементов spine.
- FR-09: Обработка relative URL в HTML (images, CSS) через `baseURL`.
- FR-10: Все ошибки через `AppError` с категорией `.parsing`.

## Non-Functional Requirements
- NFR-01: Открытие первой страницы EPUB 50MB < 1s.
- NFR-02: Не распаковывает весь архив при открытии — только нужные файлы.

## Boundaries (что НЕ входит)
- Не реализовывать DRM (Adobe DRM, Readium LCP).
- Не реализовывать UI отображения — только парсинг.

## Acceptance Criteria
- [ ] EPUB 2 и EPUB 3 открываются корректно.
- [ ] Метаданные извлекаются из OPF.
- [ ] Обложка извлекается.
- [ ] Relative URL в HTML корректно разрешаются.
- [ ] Первая страница < 1s.

## Open Questions
- Как обрабатывать EPUB с шифрованием (encryption.xml) без DRM?
- Нужна ли поддержка EPUB Fixed Layout (комиксы в EPUB формате)?