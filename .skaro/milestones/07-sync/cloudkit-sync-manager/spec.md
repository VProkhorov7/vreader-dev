# Specification: cloudkit-sync-manager

## Context
ADR-002 определяет CloudKit для синхронизации аннотаций. CloudKitSyncManager управляет CKRecord операциями, push-уведомлениями через CKSubscription и retry с exponential backoff. Требует entitlement com.apple.developer.icloud-services.

## User Scenarios
1. **Пользователь добавляет аннотацию на iPhone:** CloudKitSyncManager сохраняет CKRecord, iPad получает push через CKSubscription.
2. **Устройство оффлайн:** Изменения накапливаются в PendingChangesQueue, синхронизируются при восстановлении сети.
3. **Конфликт аннотаций:** ConflictResolver определяет стратегию разрешения.

## Functional Requirements
- FR-01: CloudKitSyncManager — actor
- FR-02: func syncAnnotations(for bookID: UUID, context: ModelContext) async throws — загрузка аннотаций из CloudKit
- FR-03: func saveAnnotation(_ annotation: Annotation) async throws — сохранение CKRecord
- FR-04: func deleteAnnotation(id: UUID) async throws — удаление CKRecord
- FR-05: CKSubscription для получения push-уведомлений об изменениях
- FR-06: func processPendingChanges(context: ModelContext) async — обработка PendingChangesQueue
- FR-07: Retry: exponential backoff 1s → 2s → 4s → 8s → 16s, максимум 5 попыток
- FR-08: После 5 попыток — запись остаётся в PendingChangesQueue
- FR-09: Все CKRecord операции идемпотентны
- FR-10: Ошибки через VReaderError с ErrorCode.sync
- FR-11: isPremium НЕ синхронизируется через CloudKit (инвариант)

## Non-Functional Requirements
- NFR-01: Синхронизация не блокирует UI
- NFR-02: CKRecord операции идемпотентны

## Boundaries (что НЕ входит)
- Не синхронизировать isPremium
- Не синхронизировать файлы книг (только метаданные и аннотации)
- Не реализовывать conflict resolution (это ConflictResolver)

## Acceptance Criteria
- [ ] CloudKitSyncManager actor определён
- [ ] Аннотации сохраняются в CloudKit
- [ ] CKSubscription получает push-уведомления
- [ ] PendingChangesQueue обрабатывается
- [ ] Exponential backoff реализован
- [ ] isPremium не синхронизируется

## Open Questions
- Нужна ли поддержка CKShare для совместного доступа к аннотациям?
- Как обрабатывать квоты CloudKit при большом количестве аннотаций?