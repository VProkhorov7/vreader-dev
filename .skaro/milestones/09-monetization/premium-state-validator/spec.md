# Specification: premium-state-validator

## Context
PremiumStateValidator — единственный компонент определяющий isPremium. Источник истины: Transaction.currentEntitlements. Кэш в iCloudSettingsStore с TTL 24ч используется ТОЛЬКО при отсутствии сети. PremiumGate.check() всегда через PremiumStateValidator.

## User Scenarios
1. **Проверка Premium при открытии AI функции:** PremiumGate.check(.translation) → PremiumStateValidator.validate() → true/false.
2. **Устройство оффлайн:** PremiumStateValidator использует кэш из iCloudSettingsStore (если TTL не истёк).
3. **Подписка отменена:** При восстановлении сети PremiumStateValidator обнаруживает отмену, isPremium = false.

## Functional Requirements
- FR-01: PremiumStateValidator — actor
- FR-02: func validate() async -> Bool — основной метод. Transaction.currentEntitlements → isPremium
- FR-03: При успешной валидации: iCloudSettingsStore.setPremiumCache(true)
- FR-04: При отсутствии сети: использовать iCloudSettingsStore.isPremiumCache (если не nil)
- FR-05: При восстановлении сети: немедленная ревалидация
- FR-06: var isPremium: Bool — кэшированное значение для синхронного доступа
- FR-07: PremiumGate — struct: enum Feature: translation, tts, summary, xray, dictionary, premiumThemes, allCloudProviders, unlimitedDownloads
- FR-08: PremiumGate.check(_ feature: Feature) async -> Bool — всегда через PremiumStateValidator
- FR-09: PremiumGate.checkSync(_ feature: Feature) -> Bool — синхронная проверка через кэш (для UI)
- FR-10: Синхронизация isPremium через CloudKit ЗАПРЕЩЕНА

## Non-Functional Requirements
- NFR-01: validate() не блокирует UI
- NFR-02: Кэш TTL 24 часа строго соблюдается

## Boundaries (что НЕ входит)
- Не реализовывать серверную верификацию
- Не синхронизировать через CloudKit

## Acceptance Criteria
- [ ] PremiumStateValidator actor определён
- [ ] validate() использует Transaction.currentEntitlements
- [ ] Кэш используется только при отсутствии сети
- [ ] PremiumGate.check() работает для всех Feature
- [ ] isPremium не синхронизируется через CloudKit
- [ ] TTL 24ч соблюдается

## Open Questions
- Нужна ли немедленная ревалидация при каждом foreground переходе?
- Как обрабатывать grace period при истечении подписки?