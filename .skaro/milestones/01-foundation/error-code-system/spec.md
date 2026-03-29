# Specification: error-code-system

## Context
Архитектурный инвариант #19 запрещает использование `Error` без `ErrorCode` в публичных API. Каждая ошибка должна содержать код, описание и recovery hint. Существующий `ErrorCode.swift` требует ревизии и расширения.

## User Scenarios
1. **Сервис бросает ошибку:** Вызывающий код получает типизированную ошибку с понятным recovery hint для отображения пользователю.
2. **DiagnosticsService логирует ошибку:** Использует `errorCode` для структурированного логирования без PII.

## Functional Requirements
- FR-01: `AppError` — struct, реализует `Error`, содержит: `code: ErrorCode`, `description: String`, `recoveryHint: String`, `underlyingError: Error?`.
- FR-02: `ErrorCode` — enum с категориями: `.fileSystem(FileSystemError)`, `.network(NetworkError)`, `.cloudProvider(CloudProviderError)`, `.aiService(AIServiceError)`, `.storeKit(StoreKitError)`, `.sync(SyncError)`, `.parsing(ParsingError)`, `.auth(AuthError)`.
- FR-03: Каждая вложенная категория — отдельный enum с конкретными кейсами (например, `FileSystemError`: `.fileNotFound`, `.permissionDenied`, `.bookmarkStale`, `.diskFull`).
- FR-04: `AppError` реализует `LocalizedError` — `errorDescription` возвращает `description`, `recoverySuggestion` возвращает `recoveryHint`.
- FR-05: Статические фабричные методы для частых ошибок: `AppError.fileNotFound(path:)`, `AppError.networkUnavailable()`, `AppError.premiumRequired(feature:)`, `AppError.timeout(service:)`.
- FR-06: `ErrorCode` реализует `Equatable` и `Hashable`.
- FR-07: `AppError` содержит `var analyticsCode: String` — безопасный для логирования код без PII.

## Non-Functional Requirements
- NFR-01: Все строки описаний и hints через `L10n.*` (или константы, заменяемые на L10n в milestone локализации).
- NFR-02: Компилируется в Swift 6 без предупреждений.

## Boundaries (что НЕ входит)
- Не реализовывать UI для отображения ошибок.
- Не реализовывать DiagnosticsService.

## Acceptance Criteria
- [ ] `AppError` и `ErrorCode` определены и компилируются.
- [ ] Все 8 категорий ошибок присутствуют.
- [ ] Фабричные методы работают корректно.
- [ ] `analyticsCode` не содержит путей к файлам или токенов.
- [ ] Существующий `ErrorCode.swift` заменён или обновлён без дублирования типов.

## Open Questions
- Нужен ли `ErrorCode` как `Sendable` для использования в async контексте?
- Как обрабатывать цепочки ошибок (error chaining) — через `underlyingError` достаточно?