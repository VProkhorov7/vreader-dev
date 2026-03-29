# Constitution: VReader — Digiteka

## Stack
- Language: Swift 6
- UI Framework: SwiftUI
- Data: SwiftData
- Minimum target: iOS 17.0, iPadOS 17.0
- Mac Catalyst: macOS 14+
- Xcode: 16+
- Supported formats: PDF, EPUB, FB2, FB2.ZIP, CBZ, CBR, CBT, CB7,
  MOBI, AZW3, DJVU, TXT, RTF, CHM, MP3, M4A, M4B, AAC
- Cloud: iCloud Drive, WebDAV, Yandex.Disk, Nextcloud, Mail.ru,
  Google Drive (OAuth2), Dropbox (OAuth2), OneDrive (OAuth2), SMB
- AI: Gemini API (translation, TTS, summaries, X-Ray, dictionary)
- Purchases: StoreKit 2 (iOS 15+)
- Metadata: Google Books API, OpenLibrary API
- Sync: CloudKit (annotations, progress), NSUbiquitousKeyValueStore
  (reading position)
- Storage: Keychain для credentials, SwiftData для библиотеки,
  iCloudSettingsStore для настроек

## Coding Standards
- Никаких комментариев в коде
- camelCase для переменных и функций, PascalCase для типов
- Все пользовательские строки только через L10n.*
- Файлы публикуются только пакетами — зависимые файлы всегда вместе
- Перед публикацией обязательна валидация через check_refs.py
- Цвета, шрифты, отступы только через DesignTokens.swift
- Темы только через @Environment(\.appTheme) — никаких хардкод значений

## Testing
- check_refs.py обязателен перед каждым merge
- Проверяет: дублирование типов, неразрешённые ссылки,
  iOS 17+ совместимость, структурную целостность Swift-файлов
- Только проактивная валидация — реактивная отладка запрещена

## Constraints
- iOS 17+ совместимость обязательна везде
- UTType для нестандартных расширений — только optional,
  force-unwrap запрещён
- NSUbiquitousKeyValueStore требует entitlement — не использовать
  без com.apple.developer.ubiquity-kvs-identifier
- CloudKit требует entitlement com.apple.developer.icloud-services
- Credentials только в Keychain
- StoreKit 2 — единственный способ обработки покупок
- Gemini API ключ только в Keychain, не в коде и не в UserDefaults
- OAuth только через нативный браузер (ASWebAuthenticationSession),
  никогда через WKWebView
- Зависимые файлы публиковать только вместе

## Security
- Все пароли, токены и API ключи — только Keychain
  (KeychainManager.shared)
- Никаких credentials в логах, UI-стейте или UserDefaults
- WebDAV Basic Auth только через URLCredential + Keychain
- OAuth tokens (Google, Dropbox, OneDrive) — только Keychain
- secrets.yaml не коммитить в Git
- StoreKit receipt верификация на каждом старте

## LLM Rules
- Никаких заглушек без явного обоснования
- Всегда генерировать AI_NOTES.md на каждый stage
- Не дублировать существующие типы — сначала проверить наличие
- Перед записью убедиться что все зависимости уже существуют
- Язык кода: английский
- Язык UI: RU + EN через L10n (приоритет), AR + ZH (milestone 08)