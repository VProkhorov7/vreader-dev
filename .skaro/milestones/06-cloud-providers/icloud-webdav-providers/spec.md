# Specification: icloud-webdav-providers

## Context
iCloud Drive использует NSMetadataQuery для обнаружения файлов. WebDAV провайдеры (Yandex, Nextcloud, MailRu) используют PROPFIND для листинга и GET для скачивания. Basic Auth credentials хранятся в Keychain.

## User Scenarios
1. **Пользователь подключает iCloud Drive:** ICloudProvider сканирует iCloud Documents, показывает книги.
2. **Пользователь вводит WebDAV URL и пароль:** Credentials сохраняются в Keychain, WebDAVProvider подключается.
3. **Yandex.Disk:** YandexDiskProvider использует WebDAV endpoint webdav.yandex.ru.

## Functional Requirements
- FR-01: ICloudProvider: NSMetadataQuery для поиска книг в iCloud Drive, NSMetadataUbiquitousItemIsDownloadedKey для статуса
- FR-02: WebDAVProvider: PROPFIND запрос для listFiles(), GET для download(), PUT для upload(), DELETE для delete()
- FR-03: WebDAV Basic Auth через URLCredential, пароль в KeychainManager
- FR-04: WebDAVXMLParser: парсинг PROPFIND XML ответа (multistatus/response/href, getcontentlength, getlastmodified)
- FR-05: YandexDiskProvider: наследует WebDAVProvider с baseURL = "https://webdav.yandex.ru"
- FR-06: NextcloudProvider: baseURL = "{host}/remote.php/dav/files/{username}/"
- FR-07: MailRuProvider: baseURL = "https://webdav.cloud.mail.ru"
- FR-08: Все credentials через KeychainManager.shared
- FR-09: Timeout: 30 секунд для фоновых операций
- FR-10: Ошибки через VReaderError с ErrorCode.cloudProvider

## Non-Functional Requirements
- NFR-01: PROPFIND не загружает рекурсивно все поддиректории
- NFR-02: Поддержка HTTPS только (HTTP запрещён)

## Boundaries (что НЕ входит)
- Не реализовывать OAuth провайдеры
- Не реализовывать SMB
- Не реализовывать UI для подключения

## Acceptance Criteria
- [ ] ICloudProvider реализует CloudProviderProtocol
- [ ] WebDAVProvider реализует PROPFIND/GET/PUT/DELETE
- [ ] WebDAVXMLParser парсит PROPFIND ответ
- [ ] YandexDisk, Nextcloud, MailRu провайдеры работают
- [ ] Credentials хранятся в Keychain
- [ ] Ошибки типизированы

## Open Questions
- Как обрабатывать самоподписанные SSL сертификаты для Nextcloud?
- Нужна ли поддержка WebDAV Digest Auth?