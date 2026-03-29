# Specification: network-monitor

## Context
Многие сервисы (GeminiService, CloudProviders, MetadataFetcher) требуют сети. При отсутствии сети они должны немедленно возвращать .offline ошибку, а UI должен показывать offline banner. NetworkMonitor — единственный источник истины о состоянии сети.

## User Scenarios
1. **Устройство уходит в оффлайн:** NetworkMonitor.isOnline становится false, TranslationPanel показывает offline banner.
2. **Сеть восстанавливается:** isOnline становится true, PendingChangesQueue начинает синхронизацию.
3. **GeminiService вызывается без сети:** Проверяет NetworkMonitor.shared.isOnline, немедленно возвращает VReaderError.offline().

## Functional Requirements
- FR-01: NetworkMonitor — @Observable singleton (shared), @MainActor
- FR-02: var isOnline: Bool — текущее состояние сети
- FR-03: var connectionType: ConnectionType — enum: wifi, cellular, wiredEthernet, unknown
- FR-04: Использовать NWPathMonitor для отслеживания изменений
- FR-05: Обновления публиковать на main thread
- FR-06: func startMonitoring() и func stopMonitoring() для управления жизненным циклом
- FR-07: Автоматический старт при инициализации
- FR-08: var isExpensive: Bool — true если cellular соединение (для ограничения фоновых загрузок)
- FR-09: Зарегистрировать в VreaderApp через .environment()

## Non-Functional Requirements
- NFR-01: Минимальная задержка обнаружения изменений сети (< 1 секунда)
- NFR-02: Не создавать утечек памяти при многократном start/stop

## Boundaries (что НЕ входит)
- Не реализовывать логику retry при восстановлении сети (это BackgroundSyncTask)
- Не показывать UI баннеры (это задача View компонентов)
- Не тестировать конкретные endpoints (только системный статус сети)

## Acceptance Criteria
- [ ] NetworkMonitor.shared существует
- [ ] isOnline корректно отражает состояние сети
- [ ] connectionType и isExpensive определены
- [ ] Обновления приходят на main thread
- [ ] Нет утечек памяти (NWPathMonitor корректно останавливается)
- [ ] Зарегистрирован в VreaderApp

## Open Questions
- Нужно ли сохранять историю изменений состояния сети для DiagnosticsService?
- Как симулировать offline в тестах без реального отключения сети?