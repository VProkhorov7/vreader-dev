# Specification: error-code

## Context
Инвариант #19 требует что все ошибки типизированы через ErrorCode. Использование голого Error без ErrorCode запрещено в публичных API. Каждая ошибка должна содержать код, описание и recovery hint. Существующий ErrorCode.swift нужно проверить и дополнить.

## User Scenarios
1. **Сервис возвращает ошибку:** Ошибка содержит код категории, локализованное описание и подсказку для восстановления.
2. **DiagnosticsService логирует ошибку:** Использует ErrorCode для структурированного логирования без PII.

## Functional Requirements
- FR-01: Определить enum ErrorCode с категориями: fileSystem, network, cloudProvider, aiService, storeKit, sync, parsing, authentication, premiumRequired
- FR-02: Определить struct VReaderError: Error, LocalizedError с полями: code (ErrorCode), message (String), recoveryHint (String?), underlyingError (Error?)
- FR-03: Каждая категория ErrorCode содержит associated values для специфики: fileSystem(FileSystemErrorCode), network(NetworkErrorCode) и т.д.
- FR-04: Определить вложенные enum для каждой категории: FileSystemErrorCode (fileNotFound, permissionDenied, diskFull, bookmarkStale), NetworkErrorCode (offline, timeout, serverError(Int), rateLimited), CloudProviderErrorCode (authFailed, quotaExceeded, fileNotFound, providerDegraded), AIServiceErrorCode (offline, quotaExceeded, timeout, invalidResponse), StoreKitErrorCode (purchaseFailed, verificationFailed, networkUnavailable), SyncErrorCode (conflictDetected, cloudKitUnavailable, pendingChangesOverflow), ParsingErrorCode (unsupportedFormat, corruptedFile, encodingError)
- FR-05: VReaderError реализует LocalizedError: errorDescription возвращает message, recoverySuggestion возвращает recoveryHint
- FR-06: Добавить static factory методы: VReaderError.offline(), VReaderError.fileNotFound(path:), VReaderError.premiumRequired(feature:)

## Non-Functional Requirements
- NFR-01: ErrorCode должен быть Sendable для использования в async контексте
- NFR-02: Никаких строк в ErrorCode — только через L10n

## Boundaries (что НЕ входит)
- Не реализовывать UI для отображения ошибок
- Не реализовывать логирование (это DiagnosticsService)
- Не локализовывать строки ошибок на этом этапе (заглушки допустимы)

## Acceptance Criteria
- [ ] ErrorCode enum определён со всеми 9 категориями
- [ ] VReaderError реализует LocalizedError
- [ ] Вложенные enum для каждой категории определены
- [ ] Factory методы offline(), fileNotFound(path:), premiumRequired(feature:) существуют
- [ ] Тип Sendable
- [ ] Существующий ErrorCode.swift обновлён или заменён без дублирования

## Open Questions
- Нужно ли ErrorCode соответствовать Codable для логирования в DiagnosticsService?
- Как обрабатывать ошибки третьих сторон (AMSMB2, libdjvu) — оборачивать в cloudProvider или fileSystem?