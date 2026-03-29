# Specification: reading-position-sync

## Context
Позиция чтения синхронизируется через NSUbiquitousKeyValueStore (быстро, мгновенная доставка). Стратегия: lastWriteWins по lamportClock. При открытии книги загружается последняя позиция со всех устройств.

## User Scenarios
1. **Пользователь читает на iPhone, открывает iPad:** iPad показывает позицию с iPhone ("Продолжить с страницы 42?").
2. **Оба устройства изменили позицию оффлайн:** lastWriteWins по lamportClock.
3. **Первое открытие книги:** Позиция = 0, lamportClock = 0.

## Functional Requirements
- FR-01: ReadingPositionSync — actor
- FR-02: func savePosition(_ position: ReadingPosition, for bookID: UUID) — сохранение в NSUbiquitousKeyValueStore
- FR-03: func loadPosition(for bookID: UUID) -> ReadingPosition? — загрузка
- FR-04: Ключ в KVStore: "position.\(bookID.uuidString)"
- FR-05: ReadingPosition кодируется в JSON для хранения в KVStore
- FR-06: При загрузке: если remote.lamportClock > local.lamportClock → использовать remote
- FR-07: Подписка на NSUbiquitousKeyValueStore.didChangeExternallyNotification
- FR-08: При получении внешнего изменения → обновить ReaderState.currentPosition
- FR-09: Предложение "Продолжить с страницы X?" если remote позиция отличается от local

## Non-Functional Requirements
- NFR-01: Сохранение позиции < 50ms
- NFR-02: KVStore лимит 1MB — позиции занимают минимум места

## Boundaries (что НЕ входит)
- Не синхронизировать аннотации через KVStore (только CloudKit)
- Не синхронизировать настройки ридера через KVStore (только iCloudSettingsStore)

## Acceptance Criteria
- [ ] ReadingPositionSync actor определён
- [ ] Позиция сохраняется в NSUbiquitousKeyValueStore
- [ ] lastWriteWins по lamportClock работает
- [ ] Внешние изменения обновляют ReaderState
- [ ] Предложение продолжить с другой позиции показывается

## Open Questions
- Нужно ли хранить историю позиций (последние N позиций) или только текущую?
- Как обрабатывать случай когда книга удалена но позиция ещё в KVStore?