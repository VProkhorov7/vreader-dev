# Specification: file-format-handlers

## Context
FileFormatHandler протокол определяет единый интерфейс для всех форматов книг. Реализации для EPUB (ZIP+OPF+HTML), FB2 (XML), TXT и PDF (PDFKit) — нативные без сторонних зависимостей. Lazy loading и streaming обязательны. Memory budget: 50MB/страница, 3 страницы одновременно.

## User Scenarios
1. **Открытие EPUB:** EPUBHandler парсит OPF, возвращает список глав, открывает первую страницу.
2. **Открытие большого PDF:** PDFHandler открывает первую страницу < 1 секунды, остальные lazy.
3. **Открытие FB2:** FB2Handler парсирует XML, извлекает главы и текст.

## Functional Requirements
- FR-01: Протокол FileFormatHandler: func openPage(_ index: Int) async throws -> PageContent, func pageCount() async throws -> Int, func extractMetadata() async throws -> BookMetadata, func extractCover() async throws -> Data?, func close() async
- FR-02: PageContent struct: text (String?), html (String?), image (Data?), pageIndex (Int), chapterTitle (String?)
- FR-03: EPUBHandler: распаковка ZIP, парсинг OPF, загрузка HTML глав, извлечение обложки из META-INF
- FR-04: FB2Handler: XML парсинг через XMLParser, извлечение секций, base64 обложка
- FR-05: TXTHandler: чтение с определением кодировки (UTF-8, Windows-1251, KOI8-R), разбивка на страницы по ~3000 символов
- FR-06: PDFHandler: PDFKit, PDFDocument, PDFPage, рендеринг в UIImage
- FR-07: Фабричный метод: FileFormatHandlerFactory.handler(for url: URL) throws -> any FileFormatHandler
- FR-08: Lazy loading: загружать только запрошенную страницу + соседние
- FR-09: Memory management: автоматическая выгрузка страниц за пределами окна [current-1, current+1]
- FR-10: Все ошибки через VReaderError с ErrorCode.parsing
- FR-11: Поддержка FB2.ZIP: распаковка перед парсингом

## Non-Functional Requirements
- NFR-01: Открытие первой страницы P95 < 1 секунда
- NFR-02: Максимум 50MB на страницу в памяти
- NFR-03: Максимум 3 страницы одновременно

## Boundaries (что НЕ входит)
- Не реализовывать CBZ/CBR/MOBI/DJVU/CHM на этом этапе
- Не реализовывать TTS
- Не реализовывать поиск по тексту

## Acceptance Criteria
- [ ] FileFormatHandler протокол определён
- [ ] EPUBHandler, FB2Handler, TXTHandler, PDFHandler реализованы
- [ ] FileFormatHandlerFactory работает
- [ ] Открытие первой страницы < 1 секунды
- [ ] Memory budget соблюдается
- [ ] Ошибки типизированы

## Open Questions
- Как обрабатывать EPUB с DRM (Adobe ADEPT)?
- Нужна ли поддержка EPUB3 с JavaScript на этом этапе?