# Specification: cloud-provider-protocol

## Context
Все облачные провайдеры реализуют единый `CloudProviderProtocol`. `CloudProviderManager` — реестр провайдеров. `CloudProviderHealthMonitor` — circuit breaker: 3 ошибки → `.degraded`. Существующие файлы требуют ревизии.

## User Scenarios
1. **Пользователь подключает Dropbox:** `CloudProviderManager.activate(provider:)` регистрирует провайдер.
2. **Dropbox недоступен 3 раза подряд:** Circuit breaker переводит в `.degraded`, пользователь уведомляется.
3. **Провайдер восстанавливается через 60s:** Автоматически переходит в `.available`.

## Functional Requirements
- FR-01: `CloudProviderProtocol`: `func listFiles(path: String) async throws -> [CloudFile]`, `func download(file: CloudFile, to url: URL) async throws`, `func upload(url: URL, path: String) async throws`, `func delete(file: CloudFile) async throws`, `var providerID: String`, `var status: CloudProviderStatus`.
- FR-02: `CloudFile` struct: `id: String`, `name: String`, `path: String`, `size: Int64`, `modifiedAt: Date`, `isDirectory: Bool`, `mimeType: String?`.
- FR-03: `CloudProviderStatus` enum: `.available`, `.degraded`, `.disconnected`, `.unauthorized`.
- FR-04: `CloudProviderManager` — @Observable final class, singleton `shared`: `var activeProviders: [any CloudProviderProtocol]`, `func activate(_ provider: any CloudProviderProtocol)`, `func deactivate(providerID: String)`, `func provider(for id: String) -> (any CloudProviderProtocol)?`.
- FR-05: `CloudProviderHealthMonitor` — final class: отслеживает ошибки каждого провайдера, circuit breaker: 3 ошибки → `.degraded` → уведомление → 60s → автовосстановление.
- FR-06: `CloudProviderHealthMonitor.recordError(providerID:error:)` — регистрирует ошибку.
- FR-07: `CloudProviderHealthMonitor.recordSuccess(providerID:)` — сбрасывает счётчик ошибок.
- FR-08: При `.degraded` — `DiagnosticsService.log(.warning, category: .cloud, ...)`.
- FR-09: Все ошибки через `AppError` с категорией `.cloudProvider`.

## Non-Functional Requirements
- NFR-01: Circuit breaker срабатывает синхронно при 3-й ошибке.
- NFR-02: Автовосстановление через ровно 60 секунд.

## Boundaries (что НЕ входит)
- Не реализовывать конкретные провайдеры.
- Не реализовывать UI статуса провайдеров.

## Acceptance Criteria
- [ ] `CloudProviderProtocol` определён со всеми методами.
- [ ] `CloudProviderManager` регистрирует и возвращает провайдеры.
- [ ] Circuit breaker срабатывает при 3 ошибках.
- [ ] Автовосстановление через 60s работает.
- [ ] Существующие файлы обновлены без дублирования.

## Open Questions
- Нужен ли `CloudProviderProtocol` как `AnyObject` для хранения в массиве?
- Как обрабатывать провайдер с частичной деградацией (некоторые операции работают, другие нет)?