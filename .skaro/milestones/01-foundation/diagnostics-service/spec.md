# Specification: diagnostics-service

## Context
Инвариант #14 запрещает PII в логах. DiagnosticsService — единственный способ логирования в приложении. В Debug режиме полный доступ к логам, в Release — только экспорт последних 100 записей через share sheet. Используется всеми сервисами для диагностики.

## User Scenarios
1. **Разработчик отлаживает проблему:** Видит полные логи в Xcode Console через OSLog.
2. **Пользователь сообщает о баге:** Экспортирует последние 100 записей через DiagnosticsView → share sheet.
3. **Сервис логирует ошибку:** DiagnosticsService.error(code: .network(.timeout), context: "CloudKit sync") — без email, токенов, путей с личными данными.

## User Scenarios (extended)
4. **Сессия завершается:** Кольцевой буфер сохраняется в Caches directory, перезаписывая файл предыдущей сессии.
5. **Сообщение содержит чувствительные данные:** Слово "password" в сообщении заменяется на "[REDACTED]", санированное сообщение логируется без потери записи.

## Functional Requirements
- FR-01: DiagnosticsService — singleton (shared), `final class` conforming to `@unchecked Sendable`; `NSLock` protects only the ring buffer; OSLog calls are unsynchronised (safe by design)
- FR-02: Уровни логирования: debug, info, warning, error, fault
- FR-03: `func debug(_ message: String, category: LogCategory)`
- FR-04: `func info(_ message: String, category: LogCategory)`
- FR-05: `func warning(_ message: String, category: LogCategory)`
- FR-06: `func error(_ error: AppError, context: String)` — references `AppError` from `App/Vreader/Vreader/AppError.swift`
- FR-07: `func fault(_ message: String, category: LogCategory)`
- FR-08: `enum LogCategory: String` — `library`, `reader`, `cloud`, `ai`, `sync`, `storeKit`, `fileSystem`, `navigation`
- FR-09: Использовать `os.Logger` с `subsystem` = bundle identifier, `category` = `LogCategory.rawValue`
- FR-10: Хранить кольцевой буфер последних 100 записей в памяти (`LogEntry` struct)
- FR-11: `func exportLogs() -> String` — plain text, one entry per line: `[ISO8601] [LEVEL] [CATEGORY] message`; newlines inside a message escaped as `\n`
- FR-12: В Debug: все уровни попадают в буфер. В Release: только `warning`, `error`, `fault` попадают в буфер
- FR-13: `LogEntry` содержит: `timestamp: Date`, `level: LogLevel`, `category: LogCategory`, `message: String` — БЕЗ PII
- FR-14: PII-фильтрация: case-insensitive whole-word boundary match (regex `\b<keyword>\b`) по словам `token`, `password`, `key`, `secret`; совпавшее слово заменяется на `[REDACTED]`; санированное сообщение логируется (запись не отбрасывается)
- FR-15: Кольцевой буфер сохраняется в один файл в `Caches` directory приложения (не `Documents`, не iCloud) при каждом завершении сессии; файл перезаписывается целиком; при следующем запуске буфер не восстанавливается из файла (файл предназначен только для экспорта)

## Non-Functional Requirements
- NFR-01: Логирование не должно блокировать вызывающий поток; `NSLock` scope ограничен только мутацией кольцевого буфера
- NFR-02: Кольцевой буфер не должен превышать разумный объём памяти (< 1MB); при 100 записях по ~200 байт = ~20KB — хорошо в пределах лимита

## Boundaries (что НЕ входит)
- Не реализовывать отправку логов на сервер (только локально)
- Не реализовывать аналитику (это `AnalyticsEvent`)
- Не логировать содержимое книг
- Не восстанавливать буфер из файла при запуске (файл в Caches — только для экспорта текущей сессии)

## Acceptance Criteria
- [ ] `DiagnosticsService.shared` существует и является `final class` с `@unchecked Sendable`
- [ ] Все 5 уровней логирования (`debug`, `info`, `warning`, `error`, `fault`) работают и вызывают соответствующий `os.Logger` метод
- [ ] `LogCategory` enum определён с восемью кейсами
- [ ] Кольцевой буфер хранит не более 100 записей; при добавлении 101-й самая старая вытесняется
- [ ] `exportLogs()` возвращает plain text, одна запись на строку в формате `[ISO8601] [LEVEL] [CATEGORY] message`; многострочные сообщения экранируют внутренние переносы как `\n`
- [ ] PII-фильтрация: сообщение `"token=abc123"` логируется как `"[REDACTED]=abc123"` (whole-word match); сообщение `"storeKit"` не редактируется (нет совпадения по границе слова для `key`)
- [ ] В Release сборке (`#if !DEBUG`) `debug` и `info` записи не попадают в кольцевой буфер
- [ ] `func error(_ error: AppError, context: String)` компилируется с типом `AppError` из `App/Vreader/Vreader/AppError.swift`
- [ ] При вызове `persistLogsToCache()` файл создаётся в `FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)` и перезаписывается при повторном вызове
- [ ] `NSLock` защищает только операции чтения/записи кольцевого буфера; OSLog вызовы выполняются вне lock
- [ ] Тест: 200 последовательных записей → буфер содержит ровно 100 самых новых
- [ ] Тест: сообщение с `"password"` → `LogEntry.message` содержит `"[REDACTED]"`, запись присутствует в буфере
- [ ] Тест: сообщение `"keystroke"` → не редактируется (whole-word boundary защищает от ложных срабатываний)

## Open Questions
*(все вопросы разрешены)*