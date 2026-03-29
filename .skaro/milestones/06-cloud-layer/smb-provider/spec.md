# Specification: smb-provider

## Context
SMB провайдер для домашних NAS. AMSMB2 для SMB2/SMB3. SMB1 legacy fallback для старых устройств. NTLM/Guest auth. Kerberos не поддерживается. Только iOS.

## User Scenarios
1. **Пользователь подключает Synology NAS:** Вводит IP, share, логин, пароль → подключение через SMB3.
2. **Старый NAS поддерживает только SMB1:** Автоматический fallback на SMB1 legacy mode.
3. **NAS недоступен:** Circuit breaker через CloudProviderHealthMonitor.

## Functional Requirements
- FR-01: `SMBProvider` — final class, реализует `CloudProviderProtocol`. `providerID = "smb"`.
- FR-02: Использует AMSMB2 (Swift Package) для SMB2/SMB3.
- FR-03: SMB1 legacy fallback: при ошибке подключения SMB2 → попытка SMB1.
- FR-04: Auth: NTLM (username/password из Keychain), Guest (анонимный).
- FR-05: Kerberos не поддерживается — явная ошибка если запрошен.
- FR-06: `listFiles(path:)` — листинг share.
- FR-07: `download(file:to:)` — streaming загрузка.
- FR-08: `upload(url:path:)` — загрузка на NAS.
- FR-09: `delete(file:)` — удаление файла.
- FR-10: Credentials в Keychain: `KeychainManager.Keys.smbCredentials(host:)`.
- FR-11: Только iOS — на macOS используется нативный SMBClient.

## Non-Functional Requirements
- NFR-01: Подключение к NAS < 5s.
- NFR-02: Streaming загрузка без буферизации всего файла.

## Boundaries (что НЕ входит)
- Не реализовывать macOS SMB — только iOS.
- Не поддерживать Kerberos.

## Acceptance Criteria
- [ ] SMB2/SMB3 подключение работает через AMSMB2.
- [ ] SMB1 fallback срабатывает при ошибке SMB2.
- [ ] NTLM auth работает с credentials из Keychain.
- [ ] Credentials не логируются.

## Open Questions
- Как определять версию SMB автоматически — пробовать SMB3 → SMB2 → SMB1?
- Нужна ли поддержка SMB over VPN?