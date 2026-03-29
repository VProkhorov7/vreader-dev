# Specification: metadata-fetcher

## Context
После импорта книги MetadataFetcher автоматически обогащает метаданные: сначала из файла (EPUB OPF, FB2 description), затем Google Books API, затем OpenLibrary как fallback. Обложки сохраняются в Documents/Covers/{bookID}.jpg. Google Books API ключ через KeychainManager.

## User Scenarios
1. **Импорт EPUB с метаданными:** MetadataFetcher извлекает title, author, cover из OPF файла.
2. **Импорт TXT без метаданных:** MetadataFetcher запрашивает Google Books по названию файла, получает обложку и описание.
3. **Google Books недоступен:** Fallback на OpenLibrary API.
4. **Long press на карточке книги:** Повторный запрос метаданных из сети.

## Functional Requirements
- FR-01: MetadataFetcher — actor
- FR-02: func fetchMetadata(for book: Book, context: ModelContext) async throws — основной метод. Цепочка: файл → Google Books → OpenLibrary
- FR-03: func fetchFromFile(url: URL, format: BookFormat) async throws -> BookMetadata — извлечение из файла
- FR-04: func fetchFromGoogleBooks(query: String) async throws -> BookMetadata — Google Books API. Ключ из KeychainManager.shared
- FR-05: func fetchFromOpenLibrary(query: String) async throws -> BookMetadata — OpenLibrary fallback
- FR-06: func saveCover(_ data: Data, bookID: UUID) async throws -> String — сохранение в Documents/Covers/{bookID}.jpg, возвращает coverPath
- FR-07: func fetchCover(url: URL) async throws -> Data — загрузка обложки по URL
- FR-08: Обновление book.coverPath, book.title, book.author и т.д. через ModelContext
- FR-09: Требует NetworkMonitor.isOnline для сетевых запросов. При оффлайн — только из файла
- FR-10: Timeout для сетевых запросов: 10 секунд (инвариант #10)
- FR-11: Не перезаписывать метаданные если пользователь вручную редактировал (book.isManuallyEdited флаг)
- FR-12: Логирование через DiagnosticsService без PII

## Non-Functional Requirements
- NFR-01: Не блокировать импорт — MetadataFetcher работает асинхронно после создания Book
- NFR-02: Обложки сжимать до максимум 500KB перед сохранением
- NFR-03: Кэшировать результаты Google Books запросов на 24 часа

## Boundaries (что НЕ входит)
- Не реализовывать UI для редактирования метаданных (это MetadataEditorView)
- Не индексировать в Spotlight (это SpotlightIndexer)
- Не хранить обложки в SwiftData (только coverPath)

## Acceptance Criteria
- [ ] MetadataFetcher actor определён
- [ ] Цепочка файл → Google Books → OpenLibrary работает
- [ ] Обложки сохраняются в Documents/Covers/{bookID}.jpg
- [ ] book.coverPath обновляется в SwiftData
- [ ] При оффлайн работает только извлечение из файла
- [ ] Timeout 10 секунд соблюдается
- [ ] Google Books API ключ берётся из KeychainManager

## Open Questions
- Нужен ли отдельный кэш для Google Books ответов или достаточно обновлённых данных в SwiftData?
- Как обрабатывать книги с одинаковым названием при поиске в Google Books?