# Specification: app-theme-system

## Context
Архитектура требует передачи темы через `@Environment(\.appTheme)`. Четыре темы: две бесплатные (EditorialDark, CuratorLight) и две Premium (NeuralLink, Typewriter). Хардкод цветов в UI запрещён.

## User Scenarios
1. **Пользователь меняет тему в настройках:** Весь UI мгновенно перекрашивается без перезапуска.
2. **Разработчик создаёт новый компонент:** Использует `@Environment(\.appTheme)` и получает правильные цвета для текущей темы.
3. **Premium пользователь выбирает NeuralLink:** Тема применяется, Free пользователь видит paywall.

## Functional Requirements
- FR-01: `AppTheme` — protocol со свойствами: `surfaceBase`, `surfaceLow`, `surfaceMid`, `surfaceHigh` (Color), `accent` (Color), `inkPrimary`, `inkMuted` (Color), `fontDisplay`, `fontBody` (Font), `cornerRadius` (CGFloat), `usesMonospace` (Bool), `usesRTLHints` (Bool), `id` (String), `isPremium` (Bool).
- FR-02: `EditorialDarkTheme` — фон #1A1A1A, акцент #C8861A, Serif шрифты. `isPremium = false`.
- FR-03: `CuratorLightTheme` — фон #F5F0E8, акцент gold underlines. `isPremium = false`.
- FR-04: `NeuralLinkTheme` — фон #050505, акценты #00FF41 / #00F3FF, гротеск, cornerRadius=4. `isPremium = true`.
- FR-05: `TypewriterTheme` — фон #F4F0E4, акцент #8B2500, American Typewriter / Courier New, cornerRadius=2. `isPremium = true`.
- FR-06: `AppThemeKey` — EnvironmentKey с defaultValue = `EditorialDarkTheme()`.
- FR-07: `EnvironmentValues` расширен свойством `appTheme: any AppTheme`.
- FR-08: `ThemeStore` — @Observable класс, хранит `currentThemeID: String` в `iCloudSettingsStore`, предоставляет `availableThemes: [any AppTheme]`.
- FR-09: `ThemeStore.setTheme(_:isPremiumUser:)` — если тема Premium и пользователь не Premium, бросает ошибку `AppThemeError.premiumRequired`.

## Non-Functional Requirements
- NFR-01: Смена темы применяется за < 16ms (один кадр).
- NFR-02: Все цвета поддерживают Dark Mode через `Color(uiColor:)` или явные light/dark варианты.

## Boundaries (что НЕ входит)
- Не реализовывать paywall — только бросать ошибку.
- Не реализовывать сохранение темы в iCloudSettingsStore (зависит от задачи `icloud-settings-store`).

## Acceptance Criteria
- [ ] `AppTheme` protocol определён со всеми свойствами.
- [ ] Все 4 темы реализованы и компилируются.
- [ ] `@Environment(\.appTheme)` работает в preview.
- [ ] `ThemeStore` корректно блокирует Premium темы для Free пользователей.
- [ ] Нет хардкод Color литералов вне `*Theme.swift` файлов.

## Open Questions
- Нужен ли `AppTheme` как `AnyObject` (class protocol) для идентификации по ссылке?
- Как обрабатывать системный Dark/Light mode — переключать тему автоматически или оставить пользователю?