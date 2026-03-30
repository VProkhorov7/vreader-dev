# Clarifications: app-theme-system

## Question 1
How should ThemeStore persist currentThemeID given that iCloudSettingsStore integration is explicitly out of scope?

*Context:* FR-08 says ThemeStore stores currentThemeID in iCloudSettingsStore, but Boundaries explicitly exclude that implementation — this creates a direct contradiction that blocks ThemeStore implementation.

**Options:**
- A) Use UserDefaults as a temporary stub with a clear TODO comment referencing the icloud-settings-store task
- B) Define a ThemeStorePersistence protocol with a UserDefaults implementation now, swappable later for iCloudSettingsStore
- C) Store only in-memory (no persistence) for this milestone, persistence added in icloud-settings-store task
- D) Inject iCloudSettingsStore as a dependency but leave the concrete implementation as a no-op stub

**Answer:**
Use UserDefaults as a temporary stub with a clear TODO comment referencing the icloud-settings-store task

## Question 2
What is the exact font specification for EditorialDark and CuratorLight 'Serif' fonts — system serif or specific named fonts?

*Context:* FR-02 and FR-03 say 'Serif fonts' without naming them; using a specific font name vs. system .serif affects rendering consistency across iOS versions and Dynamic Type support.

**Options:**
- A) Use Font.system(.body, design: .serif) and Font.system(.title, design: .serif) for both free themes
- B) Use named fonts: New York (fontDisplay) + Georgia (fontBody) with system serif fallback
- C) Use UIFontDescriptor with serif symbolic traits wrapped in Font(UIFont(...))
- D) Leave font selection to DesignTokens.swift constants, define the actual values there

**Answer:**
Use named fonts: New York (fontDisplay) + Georgia (fontBody) with system serif fallback

## Question 3
Should AppTheme be a class-constrained protocol (AnyObject) or a value-type protocol, and does ThemeStore hold 'any AppTheme' or a concrete enum?

*Context:* The open question in the spec directly affects whether themes can be compared by identity, how ThemeStore publishes changes, and whether @Observable triggers correctly on theme switch.

**Options:**
- A) Value-type protocol (struct conformances); ThemeStore holds 'any AppTheme' and reassigns the whole value on change
- B) AnyObject-constrained protocol (class conformances); ThemeStore holds a reference and identity comparison works
- C) Define a ThemeID enum as the stored/compared value; ThemeStore maps ThemeID → any AppTheme instance
- D) Use a concrete AppThemeVariant enum with associated values instead of a protocol

**Answer:**
Define a ThemeID enum as the stored/compared value; ThemeStore maps ThemeID → any AppTheme instance

## Question 4
What error type should AppThemeError.premiumRequired conform to, and how should callers handle it?

*Context:* FR-09 requires throwing AppThemeError.premiumRequired but the spec does not define the error type's conformances or recovery hint, which is required by architectural invariant 19 (all errors typed via ErrorCode).

**Options:**
- A) AppThemeError conforms to Error only; ErrorCode integration deferred to monetization milestone
- B) AppThemeError conforms to Error and includes a localizedDescription via L10n; no ErrorCode yet
- C) AppThemeError is a case of ErrorCode (.storeKit category) with code, description, and recoveryHint as required by invariant 19
- D) AppThemeError is a standalone enum conforming to LocalizedError with an errorDescription from L10n

**Answer:**
AppThemeError conforms to Error and includes a localizedDescription via L10n; no ErrorCode yet

## Question 5
How should the four themes handle iOS system Dark/Light mode — do they respond to the system color scheme at all?

*Context:* NFR-02 requires Dark Mode support via Color(uiColor:) or explicit variants, but the spec does not say whether EditorialDark is forced-dark or adapts, which determines whether Color literals need UIColor dynamic providers.

**Options:**
- A) All themes are fixed/static — they ignore system appearance entirely (user picks the theme, that IS the mode)
- B) Free themes adapt: EditorialDark is the dark variant, CuratorLight is the light variant, and the app auto-switches based on system appearance
- C) Each theme defines explicit Color values for both light and dark system modes using Color(uiColor: UIColor { traitCollection in ... })
- D) Themes are static but surfaceBase/inkPrimary use asset catalog color sets so Xcode handles dark/light variants

**Answer:**
All themes are fixed/static — they ignore system appearance entirely (user picks the theme, that IS the mode)

## Question 6
Should ThemeStore.availableThemes always return all 4 themes (with isPremium flag), or only the themes accessible to the current user?

*Context:* This determines whether the UI layer is responsible for filtering/greying out premium themes or whether ThemeStore filters them, affecting how PremiumPaywallView is triggered.

**Options:**
- A) Always return all 4 themes; UI reads theme.isPremium to show lock/paywall affordance
- B) Return only unlocked themes for the current user; premium themes absent until purchase
- C) Return all 4 themes with an additional 'isUnlocked(for:isPremiumUser:)' method on ThemeStore for UI to query
- D) Return all 4 themes; setTheme enforces the gate and throws — availableThemes is purely informational

**Answer:**
Return all 4 themes with an additional 'isUnlocked(for:isPremiumUser:)' method on ThemeStore for UI to query
