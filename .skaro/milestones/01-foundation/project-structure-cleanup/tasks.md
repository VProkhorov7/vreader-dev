# Tasks: project-structure-cleanup

## Stage 1: Анализ дублей, перемещение файлов, entitlements, pbxproj

- [ ] Выполнить `git log -1 --format="%ai" -- Core/Book.swift` и `git log -1 --format="%ai" -- App/Vreader/Vreader/Book.swift` — зафиксировать результат → документация в commit message
- [ ] Выполнить аналогичное сравнение дат для `ContentSource.swift` → документация в commit message
- [ ] Выполнить аналогичное сравнение дат для `DownloadTask.swift` → документация в commit message
- [ ] Выполнить аналогичное сравнение дат для `ErrorCode.swift` → документация в commit message
- [ ] Если `Core/Book.swift` новее — скопировать содержимое в `App/Vreader/Vreader/Book.swift` перед удалением
- [ ] Если `Core/ContentSource.swift` новее — скопировать содержимое в `App/Vreader/Vreader/ContentSource.swift`
- [ ] Если `Core/DownloadTask.swift` новее — скопировать содержимое в `App/Vreader/Vreader/DownloadTask.swift`
- [ ] Если `Core/ErrorCode.swift` новее — скопировать содержимое в `App/Vreader/Vreader/ErrorCode.swift`
- [ ] Выполнить `git rm -r Core/` для удаления папки Core с сохранением истории → `Core/` удалена
- [ ] Выполнить `git rm App/Vreader/Vreader/Untitled.swift` → `Untitled.swift` удалён
- [ ] Выполнить двухшаговый `git mv` для переименования: `git mv App/Vreader/Vreader/iCLoudSettingsStore.swift App/Vreader/Vreader/iCloudSettingsStoreTmp.swift` затем `git mv App/Vreader/Vreader/iCloudSettingsStoreTmp.swift App/Vreader/Vreader/iCloudSettingsStore.swift` → `App/Vreader/Vreader/iCloudSettingsStore.swift`
- [ ] Добавить TODO-комментарий в `AppState.swift`: `// TODO: Рефакторинг под ADR-009 — разбить на NavigationState, LibraryState, ReaderState, SyncState` → `App/Vreader/Vreader/AppState.swift`
- [ ] Обновить `VReader.entitlements`: добавить `com.apple.developer.ubiquity-kvs-identifier` = `$(TeamIdentifierPrefix)com.vreader.app` → `App/Vreader/Vreader/VReader.entitlements`
- [ ] Обновить `VReader.entitlements`: добавить `com.apple.developer.icloud-services` = `<array><string>CloudKit</string></array>` → `App/Vreader/Vreader/VReader.entitlements`
- [ ] Обновить `VReader.entitlements`: добавить `com.apple.developer.icloud-container-identifiers` = `<array><string>iCloud.com.vreader.app</string></array>` → `App/Vreader/Vreader/VReader.entitlements`
- [ ] Обновить `VReader.entitlements`: добавить `com.apple.security.application-groups` = `<array><string>com.vreader.shared</string></array>` → `App/Vreader/Vreader/VReader.entitlements`
- [ ] Удалить из `project.pbxproj` все строки с ссылками на файлы из `Core/` (PBXFileReference и PBXBuildFile секции) → `App/Vreader/Vreader.xcodeproj/project.pbxproj`
- [ ] Удалить из `project.pbxproj` все строки с ссылкой на `Untitled.swift` → `App/Vreader/Vreader.xcodeproj/project.pbxproj`
- [ ] Удалить из `project.pbxproj` все строки с ссылкой на `iCLoudSettingsStore.swift` → `App/Vreader/Vreader.xcodeproj/project.pbxproj`
- [ ] Добавить в `project.pbxproj` корректную запись PBXFileReference и PBXBuildFile для `iCloudSettingsStore.swift` → `App/Vreader/Vreader.xcodeproj/project.pbxproj`
- [ ] Проверить `git status` — убедиться что все изменения staged и дерево чистое после коммита
- [ ] Выполнить `git log --follow App/Vreader/Vreader/Book.swift` — убедиться что история сохранена