# Specification: premium-state-validator

## Context
`PremiumStateValidator` — единственный компонент, определяющий isPremium. Источник истины: `Transaction.currentEntitlements`. `iCloudSettingsStore.isPremiumCache` — только кэш TTL 24ч. `PremiumGate.check()` всегда через `PremiumStateValidator`. Синхронизация через CloudKit запрещена.

## User Scenarios
1. **Пользователь покупает Premium:** `PremiumStateValidator.validate()` → isPremium = true → кэш обновляется.
2. **Устройство offline:** Кэш (TTL 24ч) используется для разблокировки Premium.
3. **TTL истёк offline:** Деградация до Free tier с понятным сообщением.
4. **Пользователь пытается использовать Premium функцию без подписки:** `PremiumGate.check()` бросает ошибку.

## Functional Requirements
- FR-01: `PremiumStateValidator` — final class, singleton `shared`.
- FR-02: `validate() async -> Bool` — проверяет `Transaction.currentEntitlements`, обновляет кэш.
- FR-03: `isPremium: Bool` — вычисляемое свойство: если online → `validate()`, если offline → `iCloudSettingsStore.isPremiumCacheValid ? cache : false`.
- FR-04: При восстановлении сети — немедленная ревалидация.
- FR-05: `PremiumGate` — enum (namespace) со статическими методами.
- FR-06: `PremiumGate.check(_ feature: PremiumFeature) throws` — бросает `AppError(.storeKit(.premiumRequired))` если не Premium.
- FR-07: `PremiumFeature` enum: `.translation`, `.fullTTS`, `.aiSummary`, `.xRay`, `.dictionary`, `.allCloudProviders`, `.unlimitedDownloads`, `.premiumThemes`.
- FR-08: `PremiumGate.checkWordLimit(_ count: Int) throws` — для Free перевода (500 слов).
- FR-09: `PremiumGate.checkDownloadLimit() throws` — для Free загрузок (3 книги).
- FR-10: isPremium НИКОГДА не синхронизируется через CloudKit.

## Non-Functional Requirements
- NFR-01: `PremiumGate.check()` < 1ms (синхронная проверка кэша).

## Boundaries (что НЕ входит)
- Не реализовывать UI paywall — только логику проверки.
- Не синхронизировать isPremium через CloudKit.

## Acceptance Criteria
- [ ] `PremiumStateValidator.validate()` использует только StoreKit 2.
- [ ] Кэш TTL 24ч работает корректно.
- [ ] При offline с истёкшим кэшем — Free tier.
- [ ] `PremiumGate.check()` бросает ошибку для Free пользователей.
- [ ] isPremium не синхронизируется через CloudKit.

## Open Questions
- Как обрабатывать grace period при проблемах с оплатой подписки?
- Нужен ли `PremiumStateValidator` как @Observable для реактивного UI?