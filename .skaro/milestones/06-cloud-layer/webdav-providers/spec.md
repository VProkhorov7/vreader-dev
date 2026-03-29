# Specification: webdav-providers

## Context
WebDAV провайдеры используют PROPFIND/GET/PUT/DELETE. Basic Auth credentials хранятся в Keychain. Существующие `WebDAVProvider.swift`, `WebDAVXMLParser.swift` требуют ревизии.

## User Scenarios
1. **Пользователь подключает Nextcloud:** Вводит URL, логин, пароль → credentials в Keychain → листинг файлов.
2. **Yandex.Disk недоступен:** Circuit breaker через CloudProviderHealthMonitor.
3. **WebDAV сервер возвращает 401:** Пользователь уведомляется о необходимости повторной авторизации.

## Functional Requirements
- FR-01: `WebDAVProvider` — final class, реализует `CloudProviderProtocol`. Базовый WebDAV.
- FR-02: `listFiles(path:)` — PROPFIND запрос, парсинг через `WebDAVXMLParser`.
- FR-03: `download(file:to:)` — GET запрос с streaming.
- FR-04: `upload(url:path:)` — PUT запрос.
- FR-05: `delete(file:)` — DELETE запрос.
- FR-06: Basic Auth: `URLCredential` из `KeychainManager.shared`.
- FR-07: `WebDAVXMLParser` — SAX парсер для PROPFIND ответов (multistatus/response/prop).
- FR-08: `YandexDiskProvider` — наследует `WebDAVProvider`, baseURL = `webdav.yandex.ru`.
- FR-09: `NextcloudProvider` — наследует `WebDAVProvider`, path prefix = `/remote.php/dav/files/{username}/`.
- FR-10: `MailRuProvider` — наследует `WebDAVProvider`, baseURL = `webdav.cloud.mail.ru`.
- FR-11: Credentials никогда не логируются.
- FR-12: Timeout: 30s для операций.

## Non-Functional Requirements
- NFR-01: PROPFIND для 100 файлов < 3s.
- NFR-02: Streaming загрузка — не буферизует весь файл в памяти.

## Boundaries (что НЕ входит)
- Не реализовывать OAuth для WebDAV провайдеров.
- Не реализовывать WebDAV запись (создание папок) — только чтение и загрузка.

## Acceptance Criteria
- [ ] WebDAV PROPFIND парсируется корректно.
- [ ] Basic Auth работает с credentials из Keychain.
- [ ] Yandex, Nextcloud, MailRu подключаются корректно.
- [ ] Credentials не попадают в логи.
- [ ] Существующие файлы обновлены.

## Open Questions
- Как обрабатывать самоподписанные SSL сертификаты для Nextcloud?
- Нужна ли поддержка WebDAV Digest Auth?