# Constitution: VReader - Digiteka

## Stack
- Language: Swift 6
- UI Framework: SwiftUI
- Data: SwiftData
- Minimum target: iOS 17.0, iPadOS 17.0
- Mac Catalyst: macOS 14+
- Xcode: 16+
- Formats: PDF, EPUB, FB2, CBZ, CBR, MOBI, DJVU, TXT, RTF, CHM, MP3, M4B
- Cloud: iCloud Drive, WebDAV, Yandex.Disk, Nextcloud, Google Drive, Dropbox, OneDrive, SMB
- AI: Gemini API (translation, TTS, summaries)
- Purchases: StoreKit 2
- Storage: Keychain for credentials, SwiftData for library

## Coding Standards
- No comments in code
- camelCase for variables, PascalCase for types
- All strings via L10n.*
- Linter: SwiftLint. Formatter: swift-format
- Files published as packages only
- Mandatory check_refs.py before publishing
- Colors and fonts only via DesignTokens.swift

## Testing
- check_refs.py mandatory before every merge
- Minimum coverage: 80% for business logic
- Checks: duplicate types, unresolved references, iOS 17+ compatibility

## Constraints
- iOS 17+ compatibility required everywhere
- UTType for non-standard extensions via optional only, force-unwrap forbidden
- NSUbiquitousKeyValueStore requires entitlement
- Credentials only in Keychain
- StoreKit 2 only for purchases
- OAuth only via ASWebAuthenticationSession, never WKWebView
- Infra: no third-party analytics without user consent

## Security
- All passwords and tokens only in Keychain (KeychainManager.shared)
- No credentials in logs or UserDefaults
- WebDAV Basic Auth only via URLCredential + Keychain
- OAuth tokens only in Keychain
- secrets.yaml must not be committed to Git
- StoreKit receipt verification on every launch
- Authorization via ASWebAuthenticationSession only

## LLM Rules
- No stubs without explicit justification
- Always generate AI_NOTES.md for every stage
- Do not duplicate existing types
- Verify all dependencies exist before writing files
- Code language: English
- UI language: RU + EN via L10n
