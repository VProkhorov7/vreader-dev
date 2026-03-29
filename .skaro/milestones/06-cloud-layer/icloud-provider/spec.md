# Specification: icloud-provider

## Context
iCloud Drive — единственный облачный провайдер для Free tier. Использует NSMetadataQuery для листинга файлов и NSFileManager для операций. Существующий `iCloudProvider.swift` требует ревизии.

## User Scenarios
1. **Пользователь добавляет книгу в iCloud Drive:** Приложение обнаруживает файл через NSMetadataQuery.
2. **Файл evicted из локального хранилища:** `contentState` обновляется до `.cloudOnly`.
3. **Пользователь скачивает книгу:** `NSFileManager.startDownloadingUbiquitousItem` запускает загрузку.

## Functional Requirements
- FR-01: `ICloudProvider` — final class, реализует `CloudProviderProtocol`. `providerID = "icloud"`.
- FR-02: `listFiles(path:)` — использует `NSMetadataQuery` с `NSMetadataQueryUbiquitousDocumentsScope`.
- FR-03: Отслеживает `NSMetadataUbiquitousItemDownloadingStatusKey` для определения contentState.
- FR-04: `download(file:to:)` — `NSFileManager.startDownloadingUbiquitousItem(at:)` + ожидание завершения.
- FR-05: `upload(url:path:)` — копирование в iCloud Documents через `NSFileManager`.
- FR-06: `delete(file:)` — `NSFileManager.removeItem(at:)`.
- FR-07: Автоматически обнаруживает новые файлы через NSMetadataQuery notifications.
- FR-08: Сообщает `CloudProviderHealthMonitor` об ошибках.

## Non-Functional Requirements
- NFR-01: `listFiles` < 2s для 100 файлов.

## Boundaries (что НЕ входит)
- Не реализовывать CloudKit синхронизацию — это отдельная задача.
- Не реализовывать UI браузера файлов.

## Acceptance Criteria
- [ ] Файлы из iCloud Drive обнаруживаются корректно.
- [ ] Загрузка файла работает.
- [ ] Evicted файлы определяются как `.cloudOnly`.
- [ ] Существующий iCloudProvider.swift обновлён.

## Open Questions
- Как обрабатывать конфликты версий файлов в iCloud?
- Нужна ли поддержка iCloud Drive shared folders?