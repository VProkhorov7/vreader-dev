# Specification: reading-state-manager

## Context
Позиция чтения синхронизируется через NSUbiquitousKeyValueStore (не CloudKit). Отделена от статистики. Conflict resolution: `.lastWriteWins` по `lamportClock`.

## User Scenarios
1. **Пользователь читает на iPhone, открывает на iPad:** Позиция синхронизируется через iCloud KVStore.
2. **Пользователь закрывает книгу:** Позиция сохраняется немедленно.
3. **Конфликт позиций:** Побеждает более поздняя по lamportClock.

## Functional Requirements
- FR-01: `ReadingStateManager` — final class, singleton `shared`.
- FR-02: `savePosition(_ position: ReadingPosition, for bookID: UUID)` — сохраняет в NSUbiquitousKeyValueStore.
- FR-03: `loadPosition(for bookID: UUID) -> ReadingPosition?` — загружает из KVStore.
- FR-04: Ключ KVStore: `"reading.position.\(bookID.uuidString)"`.
- FR-05: `ReadingPosition` кодируется в JSON для хранения в KVStore.
- FR-06: Conflict resolution: при получении внешнего изменения (KVStore notification) — сравнивает `lamportClock`, побеждает большее значение.
- FR-07: `updateProgress(_ progress: Double, for bookID: UUID)` — обновляет `book.progress` через `LibraryModelActor`.
- FR-08: `ReadingStatsRecord` создаётся при начале сессии чтения, обновляется при закрытии.
- FR-09: Подписка на `NSUbiquitousKeyValueStore.didChangeExternallyNotification`.

## Non-Functional Requirements
- NFR-01: Сохранение позиции < 10ms.
- NFR-02: Синхронизация между устройствами < 30s.

## Boundaries (что НЕ входит)
- Не реализовывать CloudKit синхронизацию позиции — только KVStore.
- Не реализовывать детальную статистику чтения.

## Acceptance Criteria
- [ ] Позиция сохраняется и восстанавливается корректно.
- [ ] Синхронизация между устройствами работает.
- [ ] Conflict resolution по lamportClock работает.
- [ ] ReadingStatsRecord создаётся при сессии чтения.

## Open Questions
- Как обрабатывать позицию для аудиокниг (TimeInterval vs pageIndex)?
- Нужно ли хранить историю позиций (для 'вернуться к предыдущей позиции')?