# Specification: error-code-system

## Context
Архитектурный инвариант #19 запрещает использование `Error` без `ErrorCode` в публичных API. Каждая ошибка должна содержать код, описание и recovery hint. Существующий `ErrorCode.swift` требует полной замены.

## User Scenarios
1. **Сервис бросает ошибку:** Вызывающий код получает типизированную ошибку с понятным recovery hint для отображения пользователю.
2. **DiagnosticsService логирует ошибку:** Использует `errorCode` для структурированного логирования без PII.

## Functional Requirements
- FR-01: `AppError` — struct, реализует `Error`, содержит: `code: ErrorCode`, `description: String`, `recoveryHint: String`, `underlyingError: Error?`.
- FR-02: `ErrorCode` — enum с категориями: `.fileSystem(FileSystemError)`, `.network(NetworkError)`, `.cloudProvider(CloudProviderError)`, `.aiService(AIServiceError)`, `.storeKit(StoreKitError)`, `.sync(SyncError)`, `.parsing(ParsingError)`, `.auth(AuthError)`.
- FR-03: Каждая вложенная категория — отдельный enum с конкретными кейсами. Минимальный обязательный набор, выведенный из существующих сервисов (WebDAVProvider, GeminiService, StoreKit flows и др.):
  - `FileSystemError`: `.fileNotFound`, `.permissionDenied`, `.bookmarkStale`, `.diskFull`
  - `NetworkError`: `.unavailable`, `.timeout`, `.invalidResponse`, `.sslError`
  - `CloudProviderError`: `.authenticationFailed`, `.quotaExceeded`, `.fileConflict`, `.providerUnavailable`
  - `AIServiceError`: `.apiKeyMissing`, `.rateLimitExceeded`, `.modelUnavailable`, `.responseParsingFailed`
  - `StoreKitError`: `.purchaseFailed`, `.verificationFailed`, `.productNotFound`, `.subscriptionExpired`
  - `SyncError`: `.conflictUnresolved`, `.pendingChangesLost`, `.clockSkewDetected`, `.recordNotFound`
  - `ParsingError`: `.unsupportedFormat`, `.corruptedData`, `.encodingFailed`, `.pageRenderFailed`
  - `AuthError`: `.tokenExpired`, `.oauthFlowCancelled`, `.keychainAccessFailed`, `.credentialsInvalid`
- FR-04: `AppError` реализует `LocalizedError` — `errorDescription` возвращает `description`, `recoverySuggestion` возвращает `recoveryHint`.
- FR-05: Статические фабричные методы для частых ошибок: `AppError.fileNotFound(path:)`, `AppError.networkUnavailable()`, `AppError.premiumRequired(feature:)`, `AppError.timeout(service:)`.
- FR-06: `ErrorCode` реализует `Equatable` и `Hashable`.
- FR-07: `AppError` содержит `var analyticsCode: String` — безопасный для логирования код без PII. Формат строго dot-separated: `"category.caseName"`, например `"fileSystem.fileNotFound"`. Никаких динамических значений, путей к файлам, токенов или пользовательских данных в `analyticsCode`.
- FR-08: `AppError`, `ErrorCode` и все вложенные enum категорий явно реализуют `Sendable` для безопасного использования через границы Swift 6 actor.

## Localization
- NFR-01 (уточнение): `description` и `recoveryHint` используют `private` строковые константы на английском языке. Каждая константа сопровождается комментарием `// TODO: replace with L10n.*`. Исключение из проверки `check_refs.py` задокументировано в `AI_NOTES.md`.

## Non-Functional Requirements
- NFR-01: Все строки описаний и hints — `private` константы на английском с `// TODO: replace with L10n.*` (см. раздел Localization).
- NFR-02: Компилируется в Swift 6 без предупреждений.
- NFR-03: `ErrorCode`, все вложенные enum и `AppError` явно помечены `Sendable`.

## Migration
- Существующий `ErrorCode.swift` полностью удаляется. `AppError` и новый `ErrorCode` вводятся в одном файле `AppError.swift`. Все call sites, использующие старый `ErrorCode`, исправляются в том же коммите. Инкрементальное расширение не допускается.

## Boundaries (что НЕ входит)
- Не реализовывать UI для отображения ошибок.
- Не реализовывать DiagnosticsService.

## Acceptance Criteria
- [ ] `AppError` и `ErrorCode` определены и компилируются в Swift 6 без предупреждений.
- [ ] Все 8 категорий ошибок присутствуют с минимальным набором кейсов согласно FR-03.
- [ ] Фабричные методы из FR-05 работают корректно и возвращают `AppError` с правильным `code`.
- [ ] `analyticsCode` строго соответствует формату `"category.caseName"` — не содержит путей к файлам, токенов, пользовательских данных или любых динамических значений.
- [ ] `AppError`, `ErrorCode` и все вложенные enum явно реализуют `Sendable`.
- [ ] Существующий `ErrorCode.swift` удалён, все call sites обновлены, дублирования типов нет.
- [ ] Каждая строка `description` и `recoveryHint` имеет комментарий `// TODO: replace with L10n.*`.
- [ ] `check_refs.py` проходит без ошибок после замены.
- [ ] `AI_NOTES.md` содержит документацию об исключении L10n для строковых констант.

## Open Questions
*(все вопросы закрыты по результатам Q&A)*