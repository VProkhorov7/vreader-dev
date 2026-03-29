# Specification: storekit-manager

## Context
ADR-003 определяет StoreKit 2 как единственный источник истины для isPremium. StoreKitManager управляет покупками и верификацией. PremiumStateValidator — единственный компонент определяющий isPremium. Верификация на каждом старте.

## User Scenarios
1. **Пользователь покупает Premium:** StoreKitManager.purchase() → Transaction.currentEntitlements → PremiumStateValidator.validate() → isPremium = true.
2. **Приложение запускается:** Верификация Transaction.currentEntitlements на старте.
3. **Пользователь восстанавливает покупки:** StoreKitManager.restorePurchases() → верификация.

## Functional Requirements
- FR-01: StoreKitManager — @Observable singleton (shared), @MainActor
- FR-02: func purchase(productID: String) async throws — покупка продукта
- FR-03: func restorePurchases() async throws — восстановление
- FR-04: func verifyEntitlements() async — верификация Transaction.currentEntitlements. Вызывается на каждом старте
- FR-05: var availableProducts: [Product] — список продуктов из App Store
- FR-06: Product IDs: com.vreader.premium.monthly, com.vreader.premium.lifetime
- FR-07: Transaction.updates listener для обработки внешних изменений (отмена подписки)
- FR-08: Ошибки через VReaderError с ErrorCode.storeKit
- FR-09: Логирование через DiagnosticsService (только productID, без личных данных)

## Non-Functional Requirements
- NFR-01: Верификация на старте не блокирует UI
- NFR-02: Transaction.updates listener активен всё время жизни приложения

## Boundaries (что НЕ входит)
- Не реализовывать серверную верификацию чеков
- Не синхронизировать isPremium через CloudKit

## Acceptance Criteria
- [ ] StoreKitManager.shared существует
- [ ] purchase() и restorePurchases() работают
- [ ] verifyEntitlements() вызывается на старте
- [ ] Transaction.updates listener активен
- [ ] Ошибки типизированы
- [ ] isPremium не синхронизируется через CloudKit

## Open Questions
- Нужна ли поддержка промо-кодов?
- Как обрабатывать Family Sharing для lifetime покупки?