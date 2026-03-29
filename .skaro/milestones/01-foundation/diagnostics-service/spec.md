# Specification: diagnostics-service

## Context
Инвариант #14 запрещает PII в логах. DiagnosticsService — единственный способ логирования в приложении. В Debug режиме полный доступ к логам, в Release — только экспорт последних 100 записей через share sheet. Используется всеми сервисами для диагностики.

## User Scenarios
1. **Разработчик отлаживает проблему:** Видит полные логи в Xcode Console через OSLog.
2. **Пользователь сообщает о баге:** Экспортирует последние 100 записей через DiagnosticsView → share sheet.
3. **Сервис логирует ошибку:** DiagnosticsService.error(code: .network(.timeout), context: "CloudKit sync") — без email, токенов, путей с личными данными.

## Functional Requirements
- FR-01: DiagnosticsService — singleton (shared), actor для thread safety
- FR-02: Уровни логирования: debug, info, warning, error, fault
- FR-03: func debug(_ message: String, category: LogCategory)
- FR-04: func info(_ message: String, category: LogCategory)
- FR-05: func warning(_ message: String, category: LogCategory)
- FR-06: func error(_ error: VReaderError, context: String)
- FR-07: func fault(_ message: String, category: LogCategory)
- FR-08: enum LogCategory: String — library, reader, cloud, ai, sync, storeKit, fileSystem, navigation
- FR-09: Использовать os.Logger с subsystem = bundle identifier, category = LogCategory.rawValue
- FR-10: Хранить кольцевой буфер последних 100 записей в памяти (LogEntry struct)
- FR-11: func exportLogs() -> String — форматированный текст для share sheet
- FR-12: В Debug: все уровни. В Release: только warning, error, fault в буфере
- FR-13: LogEntry содержит: timestamp, level, category, message — БЕЗ PII
- FR-14: Автоматическая фильтрация: не логировать строки содержащие "token", "password", "key", "secret"

## Non-Functional Requirements
- NFR-01: Логирование не должно блокировать вызывающий поток
- NFR-02: Кольцевой буфер не должен превышать разумный объём памяти (< 1MB)

## Boundaries (что НЕ входит)
- Не реализовывать отправку логов на сервер (только локально)
- Не реализовывать аналитику (это AnalyticsEvent)
- Не логировать содержимое книг

## Acceptance Criteria
- [ ] DiagnosticsService.shared существует
- [ ] Все 5 уровней логирования работают
- [ ] LogCategory enum определён
- [ ] Кольцевой буфер 100 записей работает
- [ ] exportLogs() возвращает форматированный текст
- [ ] Автофильтрация PII ключевых слов работает
- [ ] В Release сборке debug логи не попадают в буфер

## Open Questions
- Нужно ли сохранять буфер логов на диск между сессиями?
- Как обрабатывать многострочные сообщения в exportLogs()?