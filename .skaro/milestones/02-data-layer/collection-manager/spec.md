# Specification: collection-manager

## Context
Папки в облачных провайдерах автоматически становятся коллекциями (/Books/Fantasy/ → коллекция "Fantasy"). При удалении папки коллекция переходит в .orphaned статус, книги остаются с isLocalCopy = true. CollectionManager следит за изменениями структуры папок.

## User Scenarios
1. **Пользователь подключает Google Drive с папкой /Books/SciFi/:** CollectionManager создаёт коллекцию "SciFi" автоматически.
2. **Пользователь удаляет папку в облаке:** Коллекция → .orphaned, книги → isLocalCopy = true, уведомление пользователю.
3. **Пользователь создаёт коллекцию вручную:** CollectionManager.createCollection(name:) создаёт Collection с isAutomatic = false.

## Functional Requirements
- FR-01: CollectionManager — actor
- FR-02: func syncCollections(from files: [CloudFile], providerID: String, context: ModelContext) async — синхронизация коллекций из списка файлов провайдера
- FR-03: func createCollection(name: String, context: ModelContext) async throws -> Collection — ручное создание
- FR-04: func deleteCollection(_ collection: Collection, context: ModelContext) async throws — удаление. Книги НЕ удаляются, только коллекция
- FR-05: func markOrphaned(_ collection: Collection, context: ModelContext) async — перевод в .orphaned, все книги коллекции → isLocalCopy = true
- FR-06: func updateCollections(after import: Book, context: ModelContext) async — обновление коллекций после импорта
- FR-07: Автоматическое определение коллекции по пути файла: /Books/Fantasy/book.epub → коллекция "Fantasy"
- FR-08: Уведомление пользователя при orphaned через NotificationCenter или callback
- FR-09: Сортировка коллекций по sortOrder

## Non-Functional Requirements
- NFR-01: syncCollections не должен создавать дубликаты коллекций
- NFR-02: Операции идемпотентны

## Boundaries (что НЕ входит)
- Не реализовывать UI коллекций
- Не управлять файлами книг напрямую
- Не синхронизировать коллекции через CloudKit

## Acceptance Criteria
- [ ] CollectionManager actor определён
- [ ] syncCollections создаёт коллекции из структуры папок
- [ ] markOrphaned переводит книги в isLocalCopy = true
- [ ] Дубликаты коллекций не создаются
- [ ] Ручное создание коллекций работает
- [ ] Уведомление при orphaned отправляется

## Open Questions
- Как обрабатывать вложенные папки (/Books/Fantasy/Subgenre/)?
- Нужна ли поддержка смарт-коллекций (по жанру, автору) на этом этапе?