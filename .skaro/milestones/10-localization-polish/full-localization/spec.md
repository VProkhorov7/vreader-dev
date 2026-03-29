# Specification: full-localization

## Context
Милestone 08 требует полного покрытия RU/EN + AR (RTL layout) + ZH (CJK fonts). Все строки через L10n. AR требует полного RTL layout flip и BiDi text rendering. ZH требует CJK fallback шрифт и GBK encoding.

## User Scenarios
1. **Пользователь с арабским языком системы:** Весь UI отображается RTL, текст читается справа налево.
2. **Пользователь с китайским языком:** CJK шрифты применяются, иероглифы отображаются корректно.
3. **check_refs.py проверяет проект:** 100% строк через L10n, нет хардкода.

## Functional Requirements
- FR-01: `ar.lproj/Localizable.strings` — полное покрытие всех ключей на арабском.
- FR-02: `zh-Hans.lproj/Localizable.strings` — упрощённый китайский.
- FR-03: RTL layout: все SwiftUI View используют `layoutDirection` из environment, не хардкод.
- FR-04: `AppTheme` расширен: `usesRTLHints: Bool` используется в TextReaderView для BiDi.
- FR-05: CJK fallback шрифт в `DesignTokens.Typography` для ZH.
- FR-06: GBK encoding поддержка в `TXTHandler` для китайских TXT файлов.
- FR-07: AR: числа отображаются в арабско-индийской нотации (настройка).
- FR-08: Все `.stringsdict` файлы обновлены для AR и ZH плюрализации.
- FR-09: check_refs.py обновлён для проверки AR и ZH покрытия.

## Non-Functional Requirements
- NFR-01: RTL layout не ломает существующие LTR компоненты.
- NFR-02: CJK шрифты не увеличивают размер бандла > 5MB.

## Boundaries (что НЕ входит)
- ES, FR — milestone 10 (advanced).
- Не реализовывать in-app language switcher.

## Acceptance Criteria
- [ ] AR локализация полная, RTL layout работает корректно.
- [ ] ZH локализация полная, CJK шрифты применяются.
- [ ] check_refs.py проходит для всех 4 языков.
- [ ] Нет хардкод строк в UI.
- [ ] RTL не ломает LTR компоненты.

## Open Questions
- Нужна ли поддержка Traditional Chinese (zh-Hant) отдельно от Simplified?
- Как обрабатывать смешанный RTL/LTR текст в аннотациях?