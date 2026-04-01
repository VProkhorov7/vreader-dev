# Specification: l10n-foundation

## Context
Инвариант #4 запрещает хардкод строк в UI. Все пользовательские строки только через L10n.*. Существующие Localizable.strings для RU и EN нужно структурировать. L10n.swift обеспечивает типобезопасный доступ к строкам.

## User Scenarios
1. **Разработчик добавляет новую строку:** Добавляет ключ в L10n.swift и соответствующие переводы в .strings файлы.
2. **check_refs.py проверяет строки:** Находит все использования L10n.* и проверяет наличие ключей в .strings файлах.

## Functional Requirements
- FR-01: Определить enum L10n с вложенными namespace: Library, Reader, Settings, Cloud, AI, Premium, Common, Errors, Onboarding
- FR-02: Каждый ключ — статическая вычисляемая переменная String, использующая NSLocalizedString с dot-notation ключами, соответствующими иерархии namespace. Примеры: `NSLocalizedString("library.title", comment: "")`, `NSLocalizedString("reader.chapter", comment: "")`, `NSLocalizedString("common.ok", comment: "")`
- FR-03: Library namespace: title, searchPlaceholder, emptyState, addBook, sortBy, filterBy, collections, favorites, allBooks, recentlyRead
- FR-04: Reader namespace: continueReading, chapter, page, of, translate, tts, notes, bookmarks, toc, settings, share, close, nextChapter, prevChapter
- FR-05: Settings namespace: title, theme, font, fontSize, lineSpacing, language, cloud, premium, diagnostics, about, version, resetSettings
- FR-06: Cloud namespace: title, connect, disconnect, sync, lastSync, providers, icloud, webdav, yandex, nextcloud, mailru, google, dropbox, onedrive, smb, downloading, downloaded, cloudOnly, previewed
- FR-07: AI namespace: translate, summary, xray, dictionary, tts, quota, quotaUsed, offline, premiumRequired, translating, generating
- FR-08: Premium namespace: title, subtitle, monthly, lifetime, restore, features, unlockThemes, unlockCloud, unlockAI, unlockTTS
- FR-09: Common namespace: ok, cancel, delete, edit, save, close, retry, loading, error, success, warning, unknown
- FR-10: Errors namespace: fileNotFound, networkOffline, cloudProviderError, aiServiceError, premiumRequired, syncFailed, parsingFailed
- FR-11: Поддержка строк с параметрами через static func: `L10n.Reader.pageOf(current: Int, total: Int) -> String`. Реализация: `String(format: NSLocalizedString("reader.pageOf", comment: ""), current, total)`. Формат в .strings: `"reader.pageOf" = "%d of %d";` (EN) / `"reader.pageOf" = "%d из %d";` (RU). Паттерн применяется ко всем будущим параметризованным функциям.
- FR-12: Обновить ru.lproj/Localizable.strings и en.lproj/Localizable.strings со всеми ключами
- FR-13: Pluralization пропускается в данном milestone. Использовать нейтральные формулировки без склонений. Примеры: «книг: 5» вместо «5 книг», «аннотаций: 1» вместо «1 аннотация». Pluralization будет реализован в milestone 09.
- FR-14: L10n.swift размещается исключительно в `App/Vreader/Vreader/L10n.swift` — активный target проекта. Файл в корневом `Vreader/` не создаётся и не изменяется.
- FR-15: Localizable.strings размещаются в `App/Vreader/Vreader/ru.lproj/Localizable.strings` и `App/Vreader/Vreader/en.lproj/Localizable.strings`

## Non-Functional Requirements
- NFR-01: L10n.swift не должен содержать хардкод строк — только NSLocalizedString вызовы
- NFR-02: Все ключи в .strings файлах должны соответствовать ключам в L10n.swift
- NFR-03: Все ключи в .strings файлах используют dot-notation, совпадающую с иерархией namespace в L10n.swift. Плоские snake_case ключи запрещены.
- NFR-04: check_refs.py выдаёт предупреждение (non-blocking) при обнаружении хардкод строк в существующих UI файлах. Завершается с ошибкой (blocking, exit code 1) только при обнаружении неразрешённых L10n.* ключей — то есть ключей, используемых в коде, но отсутствующих в .strings файлах.

## File Placement
- `App/Vreader/Vreader/L10n.swift` — единственный файл с определением enum L10n
- `App/Vreader/Vreader/en.lproj/Localizable.strings` — английские переводы
- `App/Vreader/Vreader/ru.lproj/Localizable.strings` — русские переводы

## Boundaries (что НЕ входит)
- Не добавлять AR и ZH локализации (milestone 09)
- Не реализовывать RTL layout (milestone 09)
- Не переводить все строки профессионально — достаточно рабочих переводов
- Не реализовывать pluralization в данном milestone (milestone 09)
- Не создавать и не изменять файлы в корневом `Vreader/` — только `App/Vreader/Vreader/`

## Acceptance Criteria
- [ ] L10n.swift определён со всеми namespace в `App/Vreader/Vreader/L10n.swift`
- [ ] ru.lproj/Localizable.strings содержит все ключи с русскими переводами
- [ ] en.lproj/Localizable.strings содержит все ключи с английскими переводами
- [ ] Все ключи в .strings файлах используют dot-notation (например `library.title`, `common.ok`)
- [ ] Нет хардкод строк в существующих UI файлах (или они помечены TODO)
- [ ] Параметризованные функции используют `String(format: NSLocalizedString(...), ...)` с printf-style форматом
- [ ] `L10n.Reader.pageOf(current:total:)` работает корректно для EN и RU
- [ ] check_refs.py завершается с exit code 1 при неразрешённых L10n.* ключах
- [ ] check_refs.py выдаёт предупреждение (не ошибку) для хардкод строк в существующих файлах
- [ ] Нет упоминаний pluralization — используются нейтральные формулировки
- [ ] Файлы не созданы и не изменены в корневом `Vreader/`

## Open Questions
*(все вопросы разрешены)*