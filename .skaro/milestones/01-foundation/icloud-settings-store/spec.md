# Specification: icloud-settings-store

## Context
Архитектура требует хранения настроек в `iCloudSettingsStore` и кэширования `isPremium` с TTL 24 часа. `NSUbiquitousKeyValueStore` требует entitlement `com.apple.developer.ubiquity-kvs-identifier`. Существующий `iCLoudSettingsStore.swift` (опечатка в имени) требует исправления и расширения.

## User Scenarios
1. **Пользователь меняет тему на iPhone:** Тема автоматически применяется на iPad через iCloud.
2. **Устройство offline:** isPremium кэш используется для разблокировки Premium функций (TTL 24ч).
3. **TTL кэша истёк и нет сети:** Приложение деградирует до Free tier с понятным сообщением.

## Functional Requirements
- FR-01: `iCloudSettingsStore` — @Observable final class, singleton `shared`.
- FR-02: Использует `NSUbiquitousKeyValueStore.default` для синхронизации.
- FR-03: Типизированные свойства: `currentThemeID: String`, `defaultFontSize: Double`, `lineSpacing: Double`, `isAutoScrollEnabled: Bool`.
- FR-04: `isPremiumCache: Bool` — кэш с TTL. Хранит значение + timestamp.
- FR-05: `isPremiumCacheValid: Bool` — возвращает true если кэш не старше 24 часов.
- FR-06: `setCachedPremium(_ value: Bool)` — сохраняет значение с текущим timestamp.
- FR-07: Подписка на `NSUbiquitousKeyValueStore.didChangeExternallyNotification` для синхронизации между устройствами.
- FR-08: Graceful degradation если `NSUbiquitousKeyValueStore` недоступен (entitlement отсутствует) — fallback на `UserDefaults` для некритичных настроек.
- FR-09: `isPremium` НИКОГДА не является источником истины — только кэш. Это явно задокументировано в коде.

## Non-Functional Requirements
- NFR-01: Запись в KVStore < 5ms.
- NFR-02: Максимальный размер хранимых данных < 1MB (лимит NSUbiquitousKeyValueStore).

## Boundaries (что НЕ входит)
- Не хранить credentials — только Keychain.
- Не синхронизировать isPremium через CloudKit — запрещено инвариантом.
- Не реализовывать PremiumStateValidator — отдельная задача.

## Acceptance Criteria
- [ ] Опечатка в имени файла исправлена (`iCloudSettingsStore.swift`).
- [ ] Настройки синхронизируются между устройствами через iCloud.
- [ ] `isPremiumCache` корректно инвалидируется через 24 часа.
- [ ] Fallback на UserDefaults работает при отсутствии entitlement.
- [ ] Нет credentials в хранилище.

## Open Questions
- Какие настройки синхронизировать через iCloud, а какие хранить только локально?
- Нужен ли `iCloudSettingsStoreProtocol` для тестируемости?