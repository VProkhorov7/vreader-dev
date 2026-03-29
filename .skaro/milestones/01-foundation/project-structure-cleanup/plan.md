## plan.md

---

## Stage 1: Анализ дублей и подготовка канонических версий

**Цель:** Определить, какая версия каждого дублирующегося файла является канонической (по дате изменения), зафиксировать выбор в commit message, подготовить рабочее окружение для безопасного перемещения.

**Depends on:** нет

**Inputs:**
- `Core/Book.swift`
- `Core/ContentSource.swift`
- `Core/DownloadTask.swift`
- `Core/ErrorCode.swift`
- `App/Vreader/Vreader/Book.swift`
- `App/Vreader/Vreader/ContentSource.swift`
- `App/Vreader/Vreader/DownloadTask.swift`
- `App/Vreader/Vreader/ErrorCode.swift`
- `App/Vreader/Vreader/Untitled.swift`
- `App/Vreader/Vreader/iCLoudSettingsStore.swift`
- `App/Vreader/Vreader/AppState.swift`
- `App/Vreader/Vreader/VReader.entitlements`

**Outputs:**
- `App/Vreader/Vreader/Book.swift` — каноническая версия (более новая из двух)
- `App/Vreader/Vreader/ContentSource.swift` — каноническая версия
- `App/Vreader/Vreader/DownloadTask.swift` — каноническая версия
- `App/Vreader/Vreader/ErrorCode.swift` — каноническая версия
- `App/Vreader/Vreader/iCloudSettingsStore.swift` — переименован из `iCLoudSettingsStore.swift`
- `App/Vreader/Vreader/AppState.swift` — добавлен TODO-комментарий
- `App/Vreader/Vreader/VReader.entitlements` — обновлён со всеми 4 entitlements
- `App/Vreader/Vreader.xcodeproj/project.pbxproj` — обновлён: удалены ссылки на `Core/`, `Untitled.swift`, `iCLoudSettingsStore.swift`; добавлена ссылка на `iCloudSettingsStore.swift`

**DoD:**
- [ ] Выполнена команда `git log -1 --format="%ai" -- Core/Book.swift` и аналогичные для всех 4 дублей — результаты задокументированы
- [ ] Каноническая версия каждого файла размещена в `App/Vreader/Vreader/` (более новая по дате)
- [ ] `Core/` удалена через `git rm -r Core/`
- [ ] `Untitled.swift` удалён через `git rm`
- [ ] `iCLoudSettingsStore.swift` переименован в `iCloudSettingsStore.swift` через `git mv`
- [ ] В `AppState.swift` присутствует TODO-комментарий об ADR-009
- [ ] `VReader.entitlements` содержит все 4 обязательных entitlement с корректными значениями
- [ ] `project.pbxproj` не содержит ссылок на `Core/`, `Untitled.swift`, `iCLoudSettingsStore.swift`
- [ ] `project.pbxproj` содержит корректную ссылку на `iCloudSettingsStore.swift`
- [ ] `git status` показывает чистое дерево после коммита
- [ ] `git log --follow App/Vreader/Vreader/Book.swift` показывает историю

**Risks:**
- `project.pbxproj` — бинарно-сложный формат; ручное редактирование может сломать UUID-ссылки. Необходимо точно удалить строки с fileRef на удалённые файлы и не трогать остальные секции.
- Если `Core/`-версия файла окажется новее — нужно скопировать её содержимое в `App/Vreader/Vreader/` перед `git rm Core/`, иначе содержимое потеряется.
- `git mv` для переименования с изменением регистра на macOS (case-insensitive FS) требует двухшагового переименования: сначала во временное имя, затем в целевое.

---

## Verify

```yaml
- name: Проверка отсутствия папки Core
  command: test ! -d Core && echo "OK: Core удалена" || echo "FAIL: Core существует"

- name: Проверка отсутствия Untitled.swift
  command: test ! -f App/Vreader/Vreader/Untitled.swift && echo "OK" || echo "FAIL: Untitled.swift существует"

- name: Проверка отсутствия iCLoudSettingsStore.swift (с опечаткой)
  command: test ! -f "App/Vreader/Vreader/iCLoudSettingsStore.swift" && echo "OK" || echo "FAIL: старый файл существует"

- name: Проверка наличия iCloudSettingsStore.swift (исправленное имя)
  command: test -f App/Vreader/Vreader/iCloudSettingsStore.swift && echo "OK" || echo "FAIL: файл не найден"

- name: Проверка TODO в AppState.swift
  command: grep -c "TODO.*ADR-009" App/Vreader/Vreader/AppState.swift

- name: Проверка entitlement ubiquity-kvs-identifier
  command: grep -c "ubiquity-kvs-identifier" App/Vreader/Vreader/VReader.entitlements

- name: Проверка entitlement icloud-services
  command: grep -c "icloud-services" App/Vreader/Vreader/VReader.entitlements

- name: Проверка entitlement icloud-container-identifiers
  command: grep -c "icloud-container-identifiers" App/Vreader/Vreader/VReader.entitlements

- name: Проверка entitlement application-groups
  command: grep -c "application-groups" App/Vreader/Vreader/VReader.entitlements

- name: Проверка значения com.vreader.shared в entitlements
  command: grep -c "com.vreader.shared" App/Vreader/Vreader/VReader.entitlements

- name: Проверка значения iCloud.com.vreader.app в entitlements
  command: grep -c "iCloud.com.vreader.app" App/Vreader/Vreader/VReader.entitlements

- name: Проверка отсутствия Core в pbxproj
  command: grep -c "Core/" App/Vreader/Vreader.xcodeproj/project.pbxproj || echo "OK: Core не найдена в pbxproj"

- name: Проверка отсутствия Untitled.swift в pbxproj
  command: grep -c "Untitled.swift" App/Vreader/Vreader.xcodeproj/project.pbxproj || echo "OK: Untitled.swift не найден в pbxproj"

- name: Проверка отсутствия iCLoudSettingsStore в pbxproj
  command: grep -c "iCLoudSettingsStore" App/Vreader/Vreader.xcodeproj/project.pbxproj || echo "OK: старое имя не найдено в pbxproj"

- name: Проверка наличия iCloudSettingsStore в pbxproj
  command: grep -c "iCloudSettingsStore.swift" App/Vreader/Vreader.xcodeproj/project.pbxproj

- name: Проверка git-истории Book.swift
  command: git log --follow --oneline App/Vreader/Vreader/Book.swift | head -5

- name: Сборка проекта xcodebuild
  command: xcodebuild -project App/Vreader/Vreader.xcodeproj -scheme Vreader -destination "generic/platform=iOS Simulator" clean build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```