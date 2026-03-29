# Specification: storekit-manager

## Context
StoreKit 2 — единственный способ обработки покупок. `Transaction.currentEntitlements` — источник истины для isPremium. Верификация на каждом старте приложения.

## User Scenarios
1. **Пользователь покупает Premium:** StoreKitManager обрабатывает транзакцию, PremiumStateValidator обновляет статус.
2. **Пользователь восстанавливает покупки:** `restorePurchases()` проверяет currentEntitlements.
3. **Приложение запускается:** Верификация транзакций на старте, кэш обновляется.

## Functional Requirements
- FR-01: `StoreKitManager` — @Observable final class, singleton `shared`.
- FR-02: `loadProducts() async throws -> [Product]` — загружает продукты из App Store.
- FR-03: Продукты: `com.vreader.premium.monthly` ($9.99/мес), `com.vreader.premium.lifetime` ($49.99).
- FR-04: `purchase(_ product: Product) async throws -> Transaction`.
- FR-05: `restorePurchases() async throws`.
- FR-06: `verifyEntitlements() async` — проверяет `Transaction.currentEntitlements` на старте.
- FR-07: Транзакции верифицируются через `Transaction.verify(_:)`.
- FR-08: Неверифицированные транзакции игнорируются с логированием через DiagnosticsService.
- FR-09: `StoreKitManager` реализует `StoreKitManaging` protocol.
- FR-10: Все ошибки через `AppError` с категорией `.storeKit`.
- FR-11: `listenForTransactions()` — Task для обработки транзакций в реальном времени.

## Non-Functional Requirements
- NFR-01: Верификация на старте < 2s.
- NFR-02: Покупка завершается < 30s (зависит от App Store).

## Boundaries (что НЕ входит)
- Не реализовывать receipt верификацию на сервере — только client-side StoreKit 2.
- Не реализовывать UI paywall.

## Acceptance Criteria
- [ ] Продукты загружаются из App Store.
- [ ] Покупка обрабатывается корректно.
- [ ] Восстановление покупок работает.
- [ ] Верификация на старте выполняется.
- [ ] Неверифицированные транзакции игнорируются.

## Open Questions
- Нужна ли поддержка Family Sharing для lifetime покупки?
- Как обрабатывать refund — автоматически деактивировать Premium?