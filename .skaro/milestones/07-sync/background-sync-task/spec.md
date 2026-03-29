# Specification: background-sync-task

## Context
BackgroundSyncTask использует BGAppRefreshTask (com.vreader.sync) для фоновой синхронизации. Минимальный интервал 15 минут. При восстановлении сети обрабатывает PendingChangesQueue. CKSubscription обеспечивает мгновенную синхронизацию при push.

## User Scenarios
1. **Приложение в фоне 20 минут:** BackgroundSyncTask запускается, синхронизирует аннотации.
2. **Сеть восстановилась:** PendingChangesQueue обрабатывается немедленно.
3. **Push от CKSubscription:** Приложение получает push, синхронизирует изменения.

## Functional Requirements
- FR-01: Регистрация BGAppRefreshTask с identifier "com.vreader.sync" в VreaderApp
- FR-02: BackgroundSyncTask: func scheduleNextSync() — планирование следующего запуска (минимум 15 минут)
- FR-03: func performSync(context: ModelContext) async — основная логика: CloudKitSyncManager.processPendingChanges() + syncAnnotations()
- FR-04: Обработчик восстановления сети: NetworkMonitor → при isOnline = true → processPendingChanges()
- FR-05: Обработка CKSubscription push: UNUserNotificationCenter + CloudKit push → немедленная синхронизация
- FR-06: Ограничение времени выполнения BGTask (expirationHandler)
- FR-07: Логирование через DiagnosticsService
- FR-08: Регистрация background modes в Info.plist: fetch, remote-notification

## Non-Functional Requirements
- NFR-01: Фоновая задача завершается до истечения системного лимита
- NFR-02: Не синхронизировать при isExpensive == true (cellular) без настройки

## Boundaries (что НЕ входит)
- Не реализовывать фоновую загрузку файлов книг
- Не реализовывать синхронизацию настроек (это iCloudSettingsStore)

## Acceptance Criteria
- [ ] BGAppRefreshTask зарегистрирован
- [ ] scheduleNextSync() планирует задачу
- [ ] performSync() выполняет синхронизацию
- [ ] При восстановлении сети PendingChangesQueue обрабатывается
- [ ] expirationHandler реализован
- [ ] Background modes в Info.plist

## Open Questions
- Нужна ли синхронизация при каждом foreground переходе или только по расписанию?
- Как обрабатывать конфликты обнаруженные в фоне (userPrompt недоступен)?