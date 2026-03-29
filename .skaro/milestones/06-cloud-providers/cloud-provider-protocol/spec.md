# Specification: cloud-provider-protocol

## Context
CloudProviderProtocol — единый интерфейс для всех облачных провайдеров. CloudProviderManager управляет реестром активных провайдеров. CloudProviderHealthMonitor реализует circuit breaker (3 ошибки → .degraded, автовосстановление через 60 секунд).

## User Scenarios
1. **Пользователь подключает провайдер:** CloudProviderManager.activate(provider:) добавляет в реестр.
2. **Провайдер недоступен:** CloudProviderHealthMonitor переводит в .degraded после 3 ошибок, уведомляет пользователя.
3. **Автовосстановление:** Через 60 секунд провайдер переходит в .halfOpen, делает пробный запрос.

## Functional Requirements
- FR-01: Протокол CloudProviderProtocol: func listFiles(path: String) async throws -> [CloudFile], func download(file: CloudFile, to: URL) async throws, func upload(url: URL, path: String) async throws, func delete(file: CloudFile) async throws, var providerID: String, var status: CloudProviderStatus, var displayName: String
- FR-02: CloudFile struct: id (String), name (String), path (String), size (Int64?), modifiedAt (Date?), isDirectory (Bool), providerID (String)
- FR-03: CloudProviderStatus enum: active, degraded, disconnected, connecting
- FR-04: CloudProviderManager — @Observable singleton: var providers: [any CloudProviderProtocol], func activate(_ provider: any CloudProviderProtocol), func deactivate(providerID: String), func provider(for id: String) -> (any CloudProviderProtocol)?
- FR-05: CloudProviderHealthMonitor — actor: отслеживает ошибки каждого провайдера, circuit breaker логика
- FR-06: Circuit breaker: 3 последовательные ошибки → status = .degraded, уведомление через NotificationCenter
- FR-07: Автовосстановление: через 60 секунд → .halfOpen → пробный listFiles() → если успех → .active, если ошибка → .degraded ещё 60 секунд
- FR-08: Все ошибки через VReaderError с ErrorCode.cloudProvider

## Non-Functional Requirements
- NFR-01: CloudProviderManager thread-safe
- NFR-02: Circuit breaker не персистируется между сессиями (сброс при перезапуске)

## Boundaries (что НЕ входит)
- Не реализовывать конкретные провайдеры
- Не реализовывать UI для провайдеров

## Acceptance Criteria
- [ ] CloudProviderProtocol определён
- [ ] CloudFile и CloudProviderStatus определены
- [ ] CloudProviderManager.shared работает
- [ ] CloudProviderHealthMonitor реализует circuit breaker
- [ ] Автовосстановление через 60 секунд работает
- [ ] Уведомление при деградации отправляется

## Open Questions
- Нужна ли персистентность списка активных провайдеров между сессиями?
- Как обрабатывать провайдер который всегда возвращает ошибки (бесконечный retry)?