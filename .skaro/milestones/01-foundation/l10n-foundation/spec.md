# Specification: l10n-foundation

## Context
Инвариант #4 запрещает хардкод строк в UI. Все пользовательские строки только через L10n.*. Существующие Localizable.strings для RU и EN нужно структурировать. L10n.swift обеспечивает типобезопасный доступ к строкам.

## User Scenarios
1. **Разработчик добавляет новую строку:** Добавляет ключ в L10n.swift и соответствующие переводы в .strings файлы.
2. **check_refs.py проверяет строки:** Находит все использования L10n.* и проверяет наличие ключей в .strings файлах.

## Functional Requirements
- FR-01: Определить enum L10n с вложенными namespace: Library, Reader, Settings, Cloud, AI, Premium, Common, Errors, Onboarding
- FR-02: Каждый ключ — статическая вычисляемая переменная String, использующая NSLocalizedString
- FR-03: Library namespace: title, searchPlaceholder, emptyState, addBook, sortBy, filterBy, collections, favorites, allBooks, recentlyRead
- FR-04: Reader namespace: continueReading, chapter, page, of, translate, tts, notes, bookmarks, toc, settings, share, close, nextChapter, prevChapter
- FR-05: Settings namespace: title, theme, font, fontSize, lineSpacing, language, cloud, premium, diagnostics, about, version, resetSettings
- FR-06: Cloud namespace: title, connect, disconnect, sync, lastSync, providers, icloud, webdav, yandex, nextcloud, mailru, google, dropbox, onedrive, smb, downloading, downloaded, cloudOnly, previewed
- FR-07: AI namespace: translate, summary, xray, dictionary, tts, quota, quotaUsed, offline, premiumRequired, translating, generating
- FR-08: Premium namespace: title, subtitle, monthly, lifetime, restore, features, unlockThemes, unlockCloud, unlockAI, unlockTTS
- FR-09: Common namespace: ok, cancel, delete, edit, save, close, retry, loading, error, success, warning, unknown
- FR-10: Errors namespace: fileNotFound, networkOffline, cloudProviderError, aiServiceError, premiumRequired, syncFailed, parsingFailed
- FR-11: Поддержка строк с параметрами через static func: L10n.Reader.pageOf(current: Int, total: Int) -> String
- FR-12: Обновить ru.lproj/Localizable.strings и en.lproj/Localizable.strings со всеми ключами

## Non-Functional Requirements
- NFR-01: L10n.swift не должен содержать хардкод строк — только NSLocalizedString вызовы
- NFR-02: Все ключи в .strings файлах должны соответствовать ключам в L10n.swift

## Boundaries (что НЕ входит)
- Не добавлять AR и ZH локализации (milestone 09)
- Не реализовывать RTL layout (milestone 09)
- Не переводить все строки профессионально — достаточно рабочих переводов

## Acceptance Criteria
- [ ] L10n.swift определён со всеми namespace
- [ ] ru.lproj/Localizable.strings содержит все ключи с русскими переводами
- [ ] en.lproj/Localizable.strings содержит все ключи с английскими переводами
- [ ] Нет хардкод строк в существующих UI файлах (или они помечены TODO)
- [ ] Параметризованные функции работают корректно
- [ ] check_refs.py не находит неразрешённых L10n ключей

## Open Questions
- Использовать ли SwiftGen для автогенерации L10n или ручную реализацию?
- Как обрабатывать pluralization (1 книга / 2 книги / 5 книг)?