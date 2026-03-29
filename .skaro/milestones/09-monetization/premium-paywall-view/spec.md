# Specification: premium-paywall-view

## Context
PremiumPaywallView показывается при попытке использовать Premium функцию или из Settings. Отображает два продукта (monthly, lifetime), список Premium функций и кнопки покупки. Дизайн соответствует текущей теме.

## User Scenarios
1. **Free пользователь нажимает на Premium тему:** PremiumPaywallView открывается как sheet.
2. **Пользователь выбирает lifetime:** StoreKitManager.purchase("com.vreader.premium.lifetime") → успех → paywall закрывается.
3. **Пользователь восстанавливает покупки:** StoreKitManager.restorePurchases() → если найдено → isPremium = true.

## Functional Requirements
- FR-01: Sheet presentation с dismiss кнопкой
- FR-02: Заголовок и подзаголовок из L10n.Premium
- FR-03: Список Premium функций: темы, полный перевод, Gemini TTS, все облачные провайдеры, безлимитные загрузки, AI Summary/X-Ray/Dictionary
- FR-04: Два варианта покупки: monthly ($9.99) и lifetime ($49.99) с выделением лучшего варианта
- FR-05: Цены загружаются из StoreKitManager.availableProducts (реальные цены из App Store)
- FR-06: Кнопка "Купить" для каждого варианта
- FR-07: Кнопка "Восстановить покупки"
- FR-08: Индикатор загрузки во время покупки
- FR-09: Обработка ошибок покупки с понятным сообщением
- FR-10: Ссылки на Privacy Policy и Terms of Service
- FR-11: Все строки через L10n.Premium.*
- FR-12: Дизайн через @Environment(\.appTheme)

## Non-Functional Requirements
- NFR-01: Цены отображаются в локальной валюте пользователя
- NFR-02: Paywall открывается < 500ms

## Boundaries (что НЕ входит)
- Не реализовывать A/B тестирование paywall
- Не реализовывать промо-коды UI

## Acceptance Criteria
- [ ] PremiumPaywallView отображается как sheet
- [ ] Реальные цены из App Store показываются
- [ ] Покупка работает
- [ ] Восстановление работает
- [ ] Ошибки обрабатываются
- [ ] Все строки через L10n
- [ ] Дизайн через appTheme

## Open Questions
- Нужна ли анимация при успешной покупке?
- Как обрабатывать pending транзакции (Ask to Buy для детских аккаунтов)?