# Specification: project-cleanup

## Context
В проекте существуют дублирующиеся файлы (Book.swift в App/Vreader/Vreader/ и Core/, ContentSource.swift, DownloadTask.swift, ErrorCode.swift), файл-заглушка Untitled.swift, и несогласованная структура директорий. Необходимо привести проект к единой структуре перед началом разработки.

**Canonical source of truth:** `App/Vreader/Vreader/` — содержит более полную реализацию (AppTheme, DesignTokens, DiagnosticsService, themes, readers) и является единственным каноническим расположением всех файлов проекта.

## User Scenarios
1. **Разработчик открывает проект:** Видит чистую, понятную структуру без дублирования и мусорных файлов. Открывает только `App/Vreader/Vreader.xcodeproj`.
2. **check_refs.py запускается:** Не находит дублирующихся типов и неразрешённых ссылок.

## Functional Requirements

### Удаление файлов и директорий
- FR-01: Удалить файл `Untitled.swift` (где бы он ни находился)
- FR-02: Удалить корневую директорию `Vreader/` целиком (включая `Vreader.xcodeproj` в корне) — единственным рабочим проектом остаётся `App/Vreader/Vreader.xcodeproj`
- FR-03: Удалить файл `Vreader/Localizable.strings 00-14-05-840.strings` (случайный backup, удаляется безусловно) — если он не был удалён вместе с корневой директорией в FR-02, удалить явно
- FR-04: Удалить из корневого `Vreader/` файлы `StorageView.swift`, `StoragesView.swift`, `ReadingSessionView.swift` как устаревшие, замещённые эквивалентами в `App/` — если они не были удалены вместе с корневой директорией в FR-02, удалить явно

### Миграция файлов
- FR-05: Скопировать `ErrorCode.swift` из корневого `Vreader/` в `App/Vreader/Vreader/` если файл отсутствует или менее полон в `App/` — `ErrorCode` является архитектурно обязательным типом (инвариант 19)
- FR-06: После копирования убедиться, что в проекте существует ровно одно определение каждого из типов: `Book`, `ContentSource`, `DownloadTask`, `ErrorCode`

### Entitlements
- FR-07: Прочитать оба файла entitlements — `Vreader/VReader.entitlements` (корневой) и `App/Vreader/Vreader/VReader.entitlements` — и смержить их в `App/Vreader/Vreader/VReader.entitlements`, взяв объединение всех ключей
- FR-08: Убедиться, что итоговый `App/Vreader/Vreader/VReader.entitlements` содержит все четыре обязательных entitlement:
  - `com.apple.developer.ubiquity-kvs-identifier`
  - `com.apple.developer.icloud-services`
  - `com.apple.developer.icloud-container-identifiers`
  - `com.apple.security.application-groups`
- FR-09: Корневой `Vreader/VReader.entitlements` удаляется вместе с корневой директорией (FR-02)

### Структура групп Xcode
- FR-10: Создание групп Xcode (Models/, Services/, UI/, Cloud/, AI/, Infrastructure/) **не входит** в данный этап — плоская структура допустима; группы будут добавлены в отдельном milestone

## Non-Functional Requirements
- NFR-01: После очистки проект должен компилироваться без ошибок
- NFR-02: `check_refs.py` не должен находить дублирующихся типов
- NFR-03: В проекте остаётся ровно один `.xcodeproj` файл — `App/Vreader/Vreader.xcodeproj`
- NFR-04: Файловая система не содержит orphan-файлов (файлов на диске, не добавленных в `.xcodeproj`, и наоборот)

## Boundaries (что НЕ входит)
- Не переписывать существующую логику файлов
- Не добавлять новую функциональность
- Не менять содержимое `.entitlements` сверх объединения существующих ключей и добавления четырёх обязательных
- Не создавать группы Xcode на данном этапе (отложено)
- Не мигрировать `StorageView.swift`, `StoragesView.swift`, `ReadingSessionView.swift` — они отброшены как устаревшие
- Не мигрировать `iCLoudSettingsStore.swift` (с опечаткой в имени) из корневого `Vreader/` — он отброшен; каноническая версия находится в `App/`

## Acceptance Criteria
- [ ] Файл `Untitled.swift` удалён
- [ ] Корневая директория `Vreader/` и корневой `Vreader.xcodeproj` удалены полностью
- [ ] Файл `Vreader/Localizable.strings 00-14-05-840.strings` удалён
- [ ] `StorageView.swift`, `StoragesView.swift`, `ReadingSessionView.swift` из корневого `Vreader/` удалены (не мигрированы)
- [ ] `ErrorCode.swift` присутствует в `App/Vreader/Vreader/` и содержит актуальное определение типа
- [ ] Нет дублирующихся определений типов `Book`, `ContentSource`, `DownloadTask`, `ErrorCode` — каждый тип определён ровно один раз
- [ ] `App/Vreader/Vreader/VReader.entitlements` содержит все четыре обязательных entitlement (см. FR-08)
- [ ] В проекте ровно один `.xcodeproj` — `App/Vreader/Vreader.xcodeproj`
- [ ] Проект компилируется без ошибок и предупреждений о дублировании
- [ ] `check_refs.py` проходит без ошибок дублирования

## Open Questions
*(все вопросы закрыты по результатам Q&A)*