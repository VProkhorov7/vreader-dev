# Specification: model-actor-context

## Context
Архитектурный инвариант: все SwiftData операции вне main thread через @ModelActor. Прямая запись минуя @ModelContext запрещена. Фоновые сервисы (MetadataFetcher, DownloadManager, BackgroundSyncTask) используют отдельный @ModelActor контекст.

## User Scenarios
1. **MetadataFetcher обновляет метаданные книги:** Выполняется в фоне через @ModelActor без блокировки UI.
2. **DownloadManager завершает загрузку:** Обновляет `book.contentState` через @ModelActor контекст.
3. **BackgroundSyncTask синхронизирует аннотации:** Читает и пишет данные в фоне без race conditions.

## Functional Requirements
- FR-01: `LibraryModelActor` — @ModelActor с `ModelContainer` для фоновых операций.
- FR-02: `LibraryModelActor` предоставляет методы: `fetchBooks(predicate:sort:) async throws -> [Book]`, `updateBook(id:changes:) async throws`, `insertBook(_ book: Book) async throws`, `deleteBook(id:) async throws`.
- FR-03: `LibraryModelActor` предоставляет методы для Annotation: `fetchAnnotations(bookID:) async throws -> [Annotation]`, `insertAnnotation(_ annotation: Annotation) async throws`, `updateAnnotation(id:changes:) async throws`.
- FR-04: `insertAnnotation` автоматически инкрементирует `lamportClock`.
- FR-05: `LibraryModelActor` инициализируется с `ModelContainer` из `VReaderApp`.
- FR-06: `ModelContainerProvider` — singleton, предоставляет единственный `ModelContainer` для всего приложения.
- FR-07: Все изменения через `modelContext.save()` с обработкой ошибок через `AppError`.

## Non-Functional Requirements
- NFR-01: Фоновые операции не блокируют main thread.
- NFR-02: Нет data races (проверяется Swift 6 strict concurrency).

## Boundaries (что НЕ входит)
- Не реализовывать конкретные бизнес-операции — только инфраструктуру доступа к данным.
- Не реализовывать CloudKit синхронизацию.

## Acceptance Criteria
- [ ] `LibraryModelActor` компилируется в Swift 6 strict concurrency mode.
- [ ] `insertAnnotation` инкрементирует `lamportClock`.
- [ ] Фоновые операции не вызывают предупреждений о main thread.
- [ ] `ModelContainerProvider.shared` доступен из всех сервисов.

## Open Questions
- Нужен ли отдельный @ModelActor для каждого сервиса или один общий `LibraryModelActor`?
- Как обрабатывать конфликты при одновременной записи из разных акторов?