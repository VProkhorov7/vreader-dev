# Specification: cloudkit-sync

## Context
Аннотации и прогресс синхронизируются через CloudKit (CKRecord). Conflict resolution: autoMerge (delta < 5 мин) или userPrompt. PendingChangesQueue для оффлайн-изменений. BackgroundSyncTask через BGAppRefreshTask.

## User Scenarios
1. **Пользователь добавляет аннотацию offline:** Сохраняется в PendingChangesQueue → синхронизируется при восстановлении сети.
2. **Два устройства изменяют одну аннотацию:** ConflictResolver определяет стратегию по delta времени.
3. **Приложение в фоне:** BackgroundSyncTask синхронизирует изменения каждые 15 минут.

## Functional Requirements
- FR-01: `CloudKitSyncManager` — final class, singleton `shared`.
- FR-02: `syncAnnotations() async throws` — загружает и отправляет аннотации через CKRecord.
- FR-03: CKRecord тип `"Annotation"` с полями из `Annotation` модели.
- FR-04: `ConflictResolver` — final class: `resolve(local: Annotation, remote: Annotation) -> ConflictResolution`.
- FR-05: `ConflictResolution` enum: `.useLocal`, `.useRemote`, `.autoMerge(Annotation)`, `.userPrompt(local: Annotation, remote: Annotation)`.
- FR-06: autoMerge: delta < 5 минут → merge комментариев с разделителем `"\n---\n"`, побеждает больший `lamportClock`.
- FR-07: userPrompt: delta > 5 минут или удаление vs изменение → публикует `ConflictResolutionRequest` через NotificationCenter.
- FR-08: `PendingChangesQueue` обработка: при восстановлении сети → `processPendingChanges() async`.
- FR-09: Retry: exponential backoff `DesignTokens.Sync.backoffIntervals`, максимум `DesignTokens.Sync.maxRetries`.
- FR-10: `BackgroundSyncTask` — BGAppRefreshTask identifier `"com.vreader.sync"`, минимальный интервал 15 минут.
- FR-11: CKSubscription для push notifications при изменениях на другом устройстве.
- FR-12: Все CKRecord операции идемпотентны.
- FR-13: isPremium НИКОГДА не синхронизируется через CloudKit.

## Non-Functional Requirements
- NFR-01: Синхронизация 100 аннотаций < 10s.
- NFR-02: Retry с exponential backoff не превышает 5 попыток.

## Boundaries (что НЕ входит)
- Не синхронизировать isPremium через CloudKit — запрещено инвариантом.
- Не синхронизировать позицию чтения через CloudKit — только KVStore.

## Acceptance Criteria
- [ ] Аннотации синхронизируются между устройствами.
- [ ] ConflictResolver корректно применяет стратегии.
- [ ] PendingChangesQueue обрабатывается при восстановлении сети.
- [ ] BackgroundSyncTask регистрируется и выполняется.
- [ ] isPremium не синхронизируется через CloudKit.
- [ ] Retry с exponential backoff работает.

## Open Questions
- Нужна ли шифрование CKRecord данных (end-to-end encryption)?
- Как обрабатывать удаление аккаунта iCloud — удалять все CKRecord?