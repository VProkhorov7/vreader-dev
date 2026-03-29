# Specification: project-cleanup

## Context
В проекте существуют дублирующиеся файлы (Book.swift в App/Vreader/Vreader/ и Core/, ContentSource.swift, DownloadTask.swift, ErrorCode.swift), файл-заглушка Untitled.swift, и несогласованная структура директорий. Необходимо привести проект к единой структуре перед началом разработки.

## User Scenarios
1. **Разработчик открывает проект:** Видит чистую, понятную структуру без дублирования и мусорных файлов.
2. **check_refs.py запускается:** Не находит дублирующихся типов и неразрешённых ссылок.

## Functional Requirements
- FR-01: Удалить файл Untitled.swift
- FR-02: Определить единственное расположение для каждого типа (Book, ContentSource, DownloadTask, ErrorCode) — в App/Vreader/Vreader/
- FR-03: Удалить дублирующиеся файлы из Core/ или перенести их содержимое в App/
- FR-04: Создать структуру групп в Xcode: Models/, Services/, UI/, Cloud/, AI/, Infrastructure/
- FR-05: Убедиться что VReader.entitlements содержит все обязательные entitlements: com.apple.developer.ubiquity-kvs-identifier, com.apple.developer.icloud-services, com.apple.developer.icloud-container-identifiers, com.apple.security.application-groups

## Non-Functional Requirements
- NFR-01: После очистки проект должен компилироваться без ошибок
- NFR-02: check_refs.py не должен находить дублирующихся типов

## Boundaries (что НЕ входит)
- Не переписывать существующую логику файлов
- Не добавлять новую функциональность
- Не менять содержимое .entitlements если entitlements уже корректны

## Acceptance Criteria
- [ ] Файл Untitled.swift удалён
- [ ] Нет дублирующихся определений типов Book, ContentSource, DownloadTask, ErrorCode
- [ ] Проект компилируется без ошибок и предупреждений о дублировании
- [ ] VReader.entitlements содержит все 4 обязательных entitlement
- [ ] check_refs.py проходит без ошибок дублирования

## Open Questions
- Какие файлы из Core/ содержат актуальную реализацию, а какие устарели?
- Нужно ли сохранять группу Core/ как отдельный модуль или всё переносится в App/?