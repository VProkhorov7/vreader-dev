# Specification: app-theme-system

## Context
Архитектура требует передачи темы через `@Environment(\.appTheme)`. Четыре темы: две бесплатные (EditorialDark, CuratorLight) и две Premium (NeuralLink, Typewriter). Хардкод цветов в UI запрещён. Все темы статичны и не реагируют на системный Dark/Light mode — пользователь сам выбирает тему, которая и является режимом отображения.

## User Scenarios
1. **Пользователь меняет тему в настройках:** Весь UI мгновенно перекрашивается без перезапуска.
2. **Разработчик создаёт новый компонент:** Использует `@Environment(\.appTheme)` и получает правильные цвета для текущей темы.
3. **Premium пользователь выбирает NeuralLink:** Тема применяется, Free пользователь видит paywall.
4. **Free пользователь открывает список тем:** Видит все 4 темы; Premium-темы визуально помечены как заблокированные через `ThemeStore.isUnlocked(for:isPremiumUser:)`.

## Functional Requirements

### Protocol & Environment
- FR-01: `AppTheme` — value-type protocol (не `AnyObject`) со свойствами: `surfaceBase`, `surfaceLow`, `surfaceMid`, `surfaceHigh` (Color), `accent` (Color), `inkPrimary`, `inkMuted` (Color), `fontDisplay`, `fontBody` (Font), `cornerRadius` (CGFloat), `usesMonospace` (Bool), `usesRTLHints` (Bool), `id: ThemeID`, `isPremium` (Bool).
- FR-06: `AppThemeKey` — EnvironmentKey с `defaultValue = EditorialDarkTheme()`.
- FR-07: `EnvironmentValues` расширен свойством `appTheme: any AppTheme`.

### ThemeID
- FR-10: `ThemeID` — `enum` со случаями `editorialDark`, `curatorLight`, `neuralLink`, `typewriter`. Конформирует `String`, `CaseIterable`, `Codable`, `Sendable`. Используется как хранимое и сравниваемое значение вместо прямого сравнения экземпляров `any AppTheme`.

### Theme Implementations
- FR-02: `EditorialDarkTheme` — фон `#1A1A1A`, акцент `#C8861A`, `fontDisplay = Font.custom("NewYork", size: 28)` с fallback на system serif, `fontBody = Font.custom("Georgia", size: 17)` с fallback на system serif. `isPremium = false`. Все цвета статичны, не адаптируются к системной схеме.
- FR-03: `CuratorLightTheme` — фон `#F5F0E8`, акцент gold underlines, `fontDisplay = Font.custom("NewYork", size: 28)` с fallback на system serif, `fontBody = Font.custom("Georgia", size: 17)` с fallback на system serif. `isPremium = false`. Все цвета статичны.
- FR-04: `NeuralLinkTheme` — фон `#050505`, акценты `#00FF41` / `#00F3FF`, гротеск (system), `cornerRadius = 4`. `isPremium = true`. Все цвета статичны.
- FR-05: `TypewriterTheme` — фон `#F4F0E4`, акцент `#8B2500`, `fontDisplay = Font.custom("AmericanTypewriter", size: 28)` с fallback `Font.custom("CourierNew", size: 28)`, `fontBody = Font.custom("AmericanTypewriter", size: 17)` с fallback `Font.custom("CourierNew", size: 17)`. `cornerRadius = 2`. `isPremium = true`. Все цвета статичны.

### ThemeStore
- FR-08: `ThemeStore` — `@Observable` класс. Хранит `currentThemeID: ThemeID` в `UserDefaults` под ключом `"currentThemeID"`. Предоставляет `availableThemes: [any AppTheme]`, всегда возвращающий все 4 темы независимо от статуса пользователя. Содержит метод `isUnlocked(for themeID: ThemeID, isPremiumUser: Bool) -> Bool` для использования в UI при отображении состояния блокировки.

  > **TODO:** Заменить `UserDefaults` на `iCloudSettingsStore` после реализации задачи `icloud-settings-store`.

- FR-09: `ThemeStore.setTheme(_ themeID: ThemeID, isPremiumUser: Bool) throws` — если тема Premium и пользователь не Premium, бросает `AppThemeError.premiumRequired`. При успехе сохраняет `themeID` в `UserDefaults` и обновляет `currentThemeID`.
- FR-11: `ThemeStore` предоставляет вычисляемое свойство `currentTheme: any AppTheme`, возвращающее экземпляр темы, соответствующий `currentThemeID`. Маппинг `ThemeID → any AppTheme` инкапсулирован внутри `ThemeStore`.

### Error Handling
- FR-12: `AppThemeError` — `enum`, конформирует `Error`. Единственный случай: `premiumRequired`. Реализует `var localizedDescription: String` через `L10n.AppTheme.premiumRequired`. Не требует `ErrorCode` на данном этапе.

## Non-Functional Requirements
- NFR-01: Смена темы применяется за < 16ms (один кадр). Достигается тем, что `ThemeStore` является `@Observable` и SwiftUI автоматически инвалидирует зависимые вью.
- NFR-02: Все цвета в реализациях тем задаются статически через `Color(red:green:blue:)` или `Color(hex:)` хелпер. Адаптация к системному Dark/Light mode не требуется и не реализуется.
- NFR-03: Хардкод `Color` литералов допустим только внутри файлов `*Theme.swift`. Во всех остальных файлах — исключительно через `@Environment(\.appTheme)`.

## Boundaries (что НЕ входит)
- Не реализовывать paywall — только бросать `AppThemeError.premiumRequired`.
- Не реализовывать сохранение темы в `iCloudSettingsStore` (зависит от задачи `icloud-settings-store`); использовать `UserDefaults` как временный stub.
- Не адаптировать темы к системному Dark/Light mode — темы полностью статичны.

## Acceptance Criteria
- [ ] `ThemeID` enum определён с 4 случаями, конформирует `String`, `CaseIterable`, `Codable`, `Sendable`.
- [ ] `AppTheme` protocol определён со всеми свойствами, включая `id: ThemeID` вместо `id: String`.
- [ ] Все 4 темы реализованы, компилируются и используют статичные цвета без адаптации к системной схеме.
- [ ] `EditorialDarkTheme` и `CuratorLightTheme` используют New York (fontDisplay) и Georgia (fontBody) с system serif fallback.
- [ ] `TypewriterTheme` использует American Typewriter с Courier New fallback.
- [ ] `@Environment(\.appTheme)` работает в Preview с дефолтным значением `EditorialDarkTheme()`.
- [ ] `ThemeStore` хранит `currentThemeID` в `UserDefaults` с TODO-комментарием на `icloud-settings-store`.
- [ ] `ThemeStore.availableThemes` возвращает все 4 темы всегда.
- [ ] `ThemeStore.isUnlocked(for:isPremiumUser:)` корректно возвращает `false` для Premium тем при `isPremiumUser = false`.
- [ ] `ThemeStore.setTheme(_:isPremiumUser:)` бросает `AppThemeError.premiumRequired` для Premium тем при `isPremiumUser = false`.
- [ ] `AppThemeError.premiumRequired` имеет `localizedDescription` через `L10n`.
- [ ] Нет хардкод `Color` литералов вне `*Theme.swift` файлов.
- [ ] `ThemeStore.currentTheme` возвращает корректный экземпляр для каждого `ThemeID`.

## Open Questions
*(Все вопросы разрешены в текущей версии спецификации.)*