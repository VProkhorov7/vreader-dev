# Specification: file-reference-resolver

## Context
Инвариант #5 определяет bookmarkData как основной идентификатор файла. filePath — только кэш. При broken path используется FileReferenceResolver.repair(). Security-scoped bookmarks необходимы для доступа к файлам вне sandbox.

## User Scenarios
1. **Пользователь открывает книгу:** FileReferenceResolver.resolve(book:) возвращает актуальный URL через bookmarkData.
2. **Файл перемещён пользователем:** resolve() обнаруживает stale bookmark, repair() сканирует Documents/Books/ и восстанавливает путь.
3. **Файл удалён:** repair() не находит файл, book.contentState = .cloudOnly, пользователь уведомляется.

## Functional Requirements
- FR-01: FileReferenceResolver — actor для thread safety
- FR-02: func resolve(book: Book) async throws -> URL — основной метод. Использует bookmarkData, обновляет filePath если изменился
- FR-03: func createBookmark(url: URL) throws -> Data — создаёт security-scoped bookmark
- FR-04: func repair(book: Book, context: ModelContext) async -> Bool — восстановление broken path. Сканирует Documents/Books/{bookID}/, при неудаче устанавливает contentState = .cloudOnly
- FR-05: func startAccessing(url: URL) -> Bool — startAccessingSecurityScopedResource
- FR-06: func stopAccessing(url: URL) — stopAccessingSecurityScopedResource
- FR-07: Автоматическое обновление book.filePath при успешном resolve через bookmarkData
- FR-08: При stale bookmark (isStale == true): создать новый bookmark и сохранить в book.bookmarkData
- FR-09: Ошибки через VReaderError с ErrorCode.fileSystem
- FR-10: Логирование через DiagnosticsService (без PII путей с личными данными)

## Non-Functional Requirements
- NFR-01: resolve() должен работать < 100ms для кэшированных путей
- NFR-02: Не держать security-scoped resource открытым дольше необходимого

## Boundaries (что НЕ входит)
- Не управлять обложками (это MetadataFetcher)
- Не скачивать файлы из облака (это DownloadManager)
- Не парсить содержимое файлов

## Acceptance Criteria
- [ ] FileReferenceResolver actor определён
- [ ] resolve(), createBookmark(), repair() реализованы
- [ ] startAccessing/stopAccessing работают корректно
- [ ] При stale bookmark создаётся новый
- [ ] repair() устанавливает contentState = .cloudOnly при неудаче
- [ ] Ошибки типизированы через VReaderError

## Open Questions
- Нужно ли кэшировать resolved URLs в памяти для производительности?
- Как обрабатывать файлы в iCloud Drive которые не скачаны локально?