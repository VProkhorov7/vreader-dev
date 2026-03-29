# Specification: app-theme

## Context
Приложение поддерживает 4 темы оформления. Темы передаются через @Environment(\(.appTheme)) — никаких хардкод значений в компонентах. NeuralLink и Typewriter — Premium only. Темы влияют на все визуальные аспекты ридера и библиотеки.

## User Scenarios
1. **Пользователь выбирает тему в настройках:** Весь UI мгновенно перекрашивается без перезапуска.
2. **Free пользователь видит Premium тему:** Тема заблокирована, показывается PremiumGate.
3. **Компонент читает тему:** Использует @Environment(\.appTheme).accent, не хардкод цвет.

## Functional Requirements
- FR-01: Определить протокол AppTheme со свойствами: surfaceBase, surfaceLow, surfaceMid, surfaceHigh (Color), accent (Color), inkPrimary, inkMuted (Color), fontDisplay, fontBody (Font), cornerRadius (CGFloat), usesMonospace (Bool), usesRTLHints (Bool), id (String), isPremium (Bool)
- FR-02: Реализовать EditorialDarkTheme: фон #1a1a1a, акцент gold #C8861A, Serif шрифт. Free.
- FR-03: Реализовать CuratorLightTheme: фон #F5F0E8, gold underlines, Serif шрифт. Free.
- FR-04: Реализовать NeuralLinkTheme: фон #050505, акцент #00FF41/#00F3FF, гротеск, cornerRadius=4. Premium only.
- FR-05: Реализовать TypewriterTheme: фон #F4F0E4, акцент #8B2500, American Typewriter/Courier New, cornerRadius=2. Premium only.
- FR-06: Определить EnvironmentKey AppThemeKey с defaultValue = EditorialDarkTheme()
- FR-07: Добавить extension EnvironmentValues { var appTheme: any AppTheme }
- FR-08: Определить enum ThemeID: String, CaseIterable для идентификации тем
- FR-09: Добавить View modifier .appTheme(_ theme: any AppTheme)

## Non-Functional Requirements
- NFR-01: Смена темы не должна вызывать полную перестройку view hierarchy — только перерисовку
- NFR-02: AppTheme протокол должен быть совместим с Swift 6 (Sendable где необходимо)

## Boundaries (что НЕ входит)
- Не реализовывать логику проверки Premium (это PremiumGate)
- Не сохранять выбранную тему (это iCloudSettingsStore)
- Не реализовывать анимацию перехода между темами

## Acceptance Criteria
- [ ] Протокол AppTheme определён со всеми свойствами
- [ ] Все 4 темы реализованы и компилируются
- [ ] EnvironmentKey зарегистрирован
- [ ] EditorialDarkTheme является default темой
- [ ] NeuralLinkTheme.isPremium == true, EditorialDarkTheme.isPremium == false
- [ ] Нет хардкод цветов в реализациях тем (все через DesignTokens или прямые hex)

## Open Questions
- Нужно ли AppTheme соответствовать Equatable для оптимизации перерисовок?
- Как обрабатывать системный Dark Mode — переключаться на EditorialDark автоматически?