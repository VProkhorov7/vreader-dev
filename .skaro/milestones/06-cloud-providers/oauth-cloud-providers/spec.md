# Specification: oauth-cloud-providers

## Context
Google Drive, Dropbox и OneDrive используют OAuth2 для аутентификации и REST API для операций с файлами. Все три реализуют CloudProviderProtocol. Tokens получаются через OAuthManager.

## User Scenarios
1. **Пользователь подключает Google Drive:** GoogleDriveProvider.connect() → OAuthManager.authorize() → listFiles() показывает книги.
2. **Скачивание книги с Dropbox:** DropboxProvider.download() использует Dropbox API v2.
3. **OneDrive:** OneDriveProvider использует Microsoft Graph API.

## Functional Requirements
- FR-01: GoogleDriveProvider: Google Drive API v3. listFiles() через files.list с mimeType фильтром для книжных форматов. download() через files.get с alt=media
- FR-02: DropboxProvider: Dropbox API v2. listFiles() через files/list_folder. download() через files/download
- FR-03: OneDriveProvider: Microsoft Graph API. listFiles() через /me/drive/items/{id}/children. download() через /me/drive/items/{id}/content
- FR-04: Все провайдеры используют OAuthManager для получения актуального access token
- FR-05: Автоматический retry при 401 (refresh token через OAuthManager)
- FR-06: Поддержка пагинации для listFiles() (nextPageToken / cursor)
- FR-07: Фильтрация по расширениям файлов (только книжные форматы)
- FR-08: Ошибки через VReaderError с ErrorCode.cloudProvider
- FR-09: Интеграция с CloudProviderHealthMonitor

## Non-Functional Requirements
- NFR-01: listFiles() timeout 30 секунд
- NFR-02: download() поддерживает возобновление (Range header)

## Boundaries (что НЕ входит)
- Не реализовывать upload для книг (только скачивание)
- Не реализовывать поиск по содержимому в облаке

## Acceptance Criteria
- [ ] Все 3 провайдера реализуют CloudProviderProtocol
- [ ] listFiles() возвращает список книг
- [ ] download() скачивает файл
- [ ] Автоматический refresh при 401
- [ ] Пагинация работает
- [ ] Ошибки типизированы

## Open Questions
- Нужна ли поддержка Google Shared Drives?
- Как обрабатывать файлы Google Docs (не скачиваемые напрямую)?