# Specification: premium-paywall-view

## Context
Paywall отображается при попытке использовать Premium функцию. Показывает список функций, цены, кнопки покупки и восстановления. Дизайн соответствует EditorialDark теме.

## User Scenarios
1. **Free пользователь нажимает 'Перевести главу':** Открывается PremiumPaywallView с описанием Premium.
2. **Пользователь выбирает месячную подписку:** StoreKitManager обрабатывает покупку, paywall закрывается.
3. **Пользователь восстанавливает покупки:** Нажимает 'Восстановить' → проверка entitlements.

## Functional Requirements
- FR-01: `PremiumPaywallView` — SwiftUI View (sheet или fullscreen).
- FR-02: Заголовок с названием приложения и tagline.
- FR-03: Список Premium функций с иконками (перевод, TTS, Summary, X-Ray, Dictionary, облака, темы).
- FR-04: Два варианта: месячная ($9.99) и lifetime ($49.99). Цены из `StoreKitManager.products`.
- FR-05: Кнопка 'Подписаться' для месячной, 'Купить навсегда' для lifetime.
- FR-06: Кнопка 'Восстановить покупки'.
- FR-07: Индикатор загрузки во время покупки.
- FR-08: Ссылки на Terms of Service и Privacy Policy.
- FR-09: При успешной покупке — закрытие paywall + разблокировка функции.
- FR-10: При ошибке покупки — alert с описанием ошибки.
- FR-11: Все строки через `L10n.*`.
- FR-12: Тема через `@Environment(\.appTheme)`.

## Non-Functional Requirements
- NFR-01: Цены загружаются из App Store (не хардкод).
- NFR-02: Открытие paywall < 300ms.

## Boundaries (что НЕ входит)
- Не реализовывать A/B тестирование paywall.
- Не реализовывать промокоды.

## Acceptance Criteria
- [ ] Цены отображаются из App Store.
- [ ] Покупка обрабатывается корректно.
- [ ] Восстановление покупок работает.
- [ ] Paywall закрывается после успешной покупки.
- [ ] Все строки через L10n.

## Open Questions
- Нужен ли free trial период (например, 7 дней)?
- Как отображать paywall для пользователей с активной подпиской (например, для upgrade на lifetime)?