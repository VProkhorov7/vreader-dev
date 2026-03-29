# Specification: file-format-handler-protocol

## Context
Все форматы книг обрабатываются через единый `FileFormatHandler` protocol. Инварианты: lazy loading, максимум 50MB на страницу, максимум 3 страницы в памяти, P95 < 1s для первой страницы.

## User Scenarios
1. **Ридер открывает EPUB:** Запрашивает страницу 1 через `openPage(0)`, получает `PageContent` за < 1s.
2. **Пользователь листает страницы:** Следующая страница предзагружается в фоне.
3. **Память превышает бюджет:** Дальние страницы автоматически выгружаются.

## Functional Requirements
- FR-01: `FileFormatHandler` — protocol: `func openPage(_ index: Int) async throws -> PageContent`, `func pageCount() async throws -> Int`, `func extractMetadata() async throws -> BookMetadata`, `func extractCover() async throws -> Data?`, `func close() async`.
- FR-02: `PageContent` — enum: `.text(AttributedString, pageIndex: Int)`, `.image(UIImage, pageIndex: Int)`, `.html(String, baseURL: URL?, pageIndex: Int)`, `.audio(AVPlayerItem, duration: TimeInterval)`.
- FR-03: `FileFormatHandlerFactory.handler(for book: Book) throws -> any FileFormatHandler` — фабрика по `BookFormat`.
- FR-04: `PageCache` — actor, хранит максимум `DesignTokens.Memory.maxPagesInMemory` страниц, LRU eviction.
- FR-05: `PageCache.store(_ content: PageContent, for index: Int)` / `get(index:) -> PageContent?`.
- FR-06: Каждый обработчик проверяет размер страницы: если > `DesignTokens.Memory.maxPageSizeMB` MB — бросает `AppError(.parsing(.pageTooLarge))`.
- FR-07: `FileFormatHandler` реализует `Sendable` для использования в async контексте.
- FR-08: `BookMetadata` struct (переиспользуется из MetadataFetcher).

## Non-Functional Requirements
- NFR-01: Первая страница P95 < 1s.
- NFR-02: Максимум 3 страницы в PageCache одновременно.
- NFR-03: Размер страницы в памяти ≤ 50MB.

## Boundaries (что НЕ входит)
- Не реализовывать конкретные форматы — только protocol и инфраструктуру.
- Не реализовывать UI ридера.

## Acceptance Criteria
- [ ] `FileFormatHandler` protocol определён со всеми методами.
- [ ] `FileFormatHandlerFactory` корректно возвращает обработчик по формату.
- [ ] `PageCache` ограничивает количество страниц в памяти.
- [ ] `PageContent` покрывает все типы контента.

## Open Questions
- Нужен ли `preloadPage(_ index: Int) async` метод в protocol для предзагрузки?
- Как обрабатывать форматы с переменным числом страниц (TXT с reflow)?