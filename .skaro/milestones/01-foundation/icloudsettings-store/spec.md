# Specification: icloudsettings-store

## Context
Настройки пользователя (тема, шрифт, язык) должны синхронизироваться между устройствами. iCloudSettingsStore использует NSUbiquitousKeyValueStore. Кэш isPremium хранится здесь с TTL 24ч и используется ТОЛЬКО при отсутствии сети. Существующий iCLoudSettingsStore.swift нужно проверить и дополнить.

## User Scenarios
1. **Пользователь меняет тему на iPhone:** Тема синхронизируется на iPad через iCloud.
2. **Устройство оффлайн, пользователь открывает Premium фичу:** iCloudSettingsStore.isPremiumCache используется как fallback (если TTL не истёк).
3. **TTL кэша истёк:** isPremiumCache возвращает nil, PremiumStateValidator требует StoreKit проверку.

## Functional Requirements
- FR-01: iCloudSettingsStore — @Observable singleton (shared), @MainActor
- FR-02: Требует entitlement com.apple.developer.ubiquity-kvs-identifier
- FR-03: var selectedThemeID: ThemeID — синхронизируется через iCloud
- FR-04: var selectedFontSize: CGFloat — синхронизируется
- FR-05: var selectedLineSpacing: CGFloat — синхронизируется
- FR-06: var preferredLanguage: String — синхронизируется
- FR-07: var isPremiumCache: Bool? — кэш с TTL 24ч. nil если TTL истёк или не установлен
- FR-08: func setPremiumCache(_ value: Bool) — устанавливает кэш с текущим timestamp
- FR-09: func clearPremiumCache() — сбрасывает кэш
- FR-10: Подписка на NSUbiquitousKeyValueStore.didChangeExternallyNotification для получения изменений с других устройств
- FR-11: Graceful degradation если iCloud недоступен — использовать UserDefaults как fallback для настроек (НЕ для isPremiumCache)
- FR-12: isPremiumCache НИКОГДА не синхронизируется через CloudKit

## Non-Functional Requirements
- NFR-01: NSUbiquitousKeyValueStore лимит 1MB — хранить только лёгкие настройки
- NFR-02: TTL проверка через Date comparison, не через Timer

## Boundaries (что НЕ входит)
- Не хранить credentials (только KeychainManager)
- Не хранить данные книг или аннотаций
- Не реализовывать CloudKit синхронизацию isPremium

## Acceptance Criteria
- [ ] iCloudSettingsStore.shared существует
- [ ] Все настройки синхронизируются через NSUbiquitousKeyValueStore
- [ ] isPremiumCache возвращает nil после 24 часов
- [ ] Подписка на внешние изменения работает
- [ ] Graceful degradation при недоступном iCloud
- [ ] isPremiumCache не попадает в CloudKit

## Open Questions
- Нужно ли шифровать isPremiumCache в NSUbiquitousKeyValueStore?
- Как тестировать TTL логику без ожидания 24 часов?