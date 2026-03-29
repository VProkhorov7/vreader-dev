# Specification: conflict-resolver

## Context
ADR-007 определяет Lamport Clock для conflict resolution. ConflictResolver реализует три стратегии: autoMerge (delta < 5 минут), userPrompt (delta > 5 минут или удаление vs изменение), lastWriteWins (позиция чтения). Сравнение по lamportClock, не wall clock.

## User Scenarios
1. **Оба устройства изменили аннотацию с разницей 2 минуты:** autoMerge объединяет комментарии с разделителем.
2. **Одно устройство удалило, другое изменило:** userPrompt показывает диалог пользователю.
3. **Позиция чтения конфликтует:** lastWriteWins по lamportClock.

## Functional Requirements
- FR-01: ConflictResolver — actor
- FR-02: enum ConflictResolutionStrategy: lastWriteWins(lamportClock: Int), autoMerge, userPrompt
- FR-03: func resolve(local: Annotation, remote: Annotation, context: ModelContext) async throws -> ConflictResolution
- FR-04: ConflictResolution enum: merged(Annotation), keepLocal, keepRemote, needsUserInput(local: Annotation, remote: Annotation)
- FR-05: Логика: delta < 5 минут → autoMerge (объединение comment через " | ", выбор большего lamportClock)
- FR-06: delta > 5 минут → userPrompt
- FR-07: Один удалён, другой изменён → userPrompt
- FR-08: Позиция чтения (ReadingPosition) → lastWriteWins по lamportClock
- FR-09: func resolveReadingPosition(local: ReadingPosition, remote: ReadingPosition) -> ReadingPosition
- FR-10: Сравнение по lamportClock, НЕ по Date

## Non-Functional Requirements
- NFR-01: Conflict resolution не блокирует UI
- NFR-02: autoMerge детерминирован (одинаковый результат на обоих устройствах)

## Boundaries (что НЕ входит)
- Не реализовывать UI для userPrompt (только callback/notification)
- Не реализовывать OT или CRDT

## Acceptance Criteria
- [ ] ConflictResolver actor определён
- [ ] autoMerge работает для delta < 5 минут
- [ ] userPrompt возвращается для delta > 5 минут
- [ ] lastWriteWins для ReadingPosition
- [ ] Сравнение по lamportClock (не Date)
- [ ] autoMerge детерминирован

## Open Questions
- Порог 5 минут — нужна ли настройка пользователем?
- Как обрабатывать конфликт если lamportClock одинаковый на обоих устройствах?