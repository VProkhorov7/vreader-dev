# Specification: smb-provider

## Context
SMBProvider использует AMSMB2 для доступа к сетевым папкам. Поддерживает SMB2/SMB3 и SMB1 legacy fallback для старых NAS. NTLM/Guest аутентификация. Kerberos не поддерживается. Только iOS (macOS использует нативный SMBClient).

## User Scenarios
1. **Пользователь подключает домашний NAS:** Вводит IP, имя пользователя, пароль → SMBProvider подключается через SMB2.
2. **Старый NAS поддерживает только SMB1:** SMBProvider автоматически fallback на SMB1.
3. **Guest доступ:** SMBProvider подключается без пароля.

## Functional Requirements
- FR-01: SMBProvider реализует CloudProviderProtocol
- FR-02: Использует AMSMB2 Swift Package
- FR-03: Поддержка SMB2/SMB3 (основной режим)
- FR-04: Fallback на SMB1 при ошибке подключения через SMB2
- FR-05: Аутентификация: NTLM (username/password) и Guest
- FR-06: Credentials в KeychainManager.shared (KeychainKey.smbPassword(host:))
- FR-07: listFiles(): листинг директории SMB share
- FR-08: download(): копирование файла с SMB на локальный диск
- FR-09: Только iOS — на macOS использовать нативный SMBClient
- FR-10: Ошибки через VReaderError с ErrorCode.cloudProvider

## Non-Functional Requirements
- NFR-01: Подключение timeout 15 секунд
- NFR-02: Поддержка Unicode имён файлов

## Boundaries (что НЕ входит)
- Не реализовывать Kerberos аутентификацию
- Не реализовывать запись на SMB (только чтение)
- Не реализовывать macOS версию (нативный SMBClient)

## Acceptance Criteria
- [ ] SMBProvider реализует CloudProviderProtocol
- [ ] SMB2/SMB3 подключение работает
- [ ] SMB1 fallback работает
- [ ] NTLM и Guest аутентификация работают
- [ ] Credentials в Keychain
- [ ] Только iOS (macOS excluded)

## Open Questions
- Как обрабатывать SMB shares с пробелами в именах?
- Нужна ли поддержка SMB over VPN?