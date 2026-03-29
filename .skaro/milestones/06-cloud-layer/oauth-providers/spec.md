# Specification: oauth-providers

## Context
OAuth2 через ASWebAuthenticationSession (никогда WKWebView). PKCE flow. Tokens только в Keychain. Автоматический refresh. Существующий код требует реализации.

## User Scenarios
1. **Пользователь подключает Google Drive:** Открывается Safari для авторизации → callback → token в Keychain.
2. **Token истекает:** Автоматический refresh без участия пользователя.
3. **Пользователь отзывает доступ:** Tokens удаляются из Keychain, провайдер деактивируется.

## Functional Requirements
- FR-01: `OAuthManager` — final class, singleton `shared`.
- FR-02: `authenticate(provider:) async throws -> OAuthTokens` — PKCE flow через `ASWebAuthenticationSession`.
- FR-03: PKCE: генерация `code_verifier`, `code_challenge` (SHA256).
- FR-04: `OAuthTokens` struct: `accessToken: String`, `refreshToken: String?`, `expiresAt: Date`.
- FR-05: Tokens сохраняются в `KeychainManager.shared` (никогда UserDefaults).
- FR-06: `refreshTokenIfNeeded(providerID:) async throws` — автоматический refresh при истечении.
- FR-07: `GoogleDriveProvider` — реализует `CloudProviderProtocol`, использует Google Drive REST API v3.
- FR-08: `DropboxProvider` — реализует `CloudProviderProtocol`, использует Dropbox API v2.
- FR-09: `OneDriveProvider` — реализует `CloudProviderProtocol`, использует Microsoft Graph API.
- FR-10: Redirect URI: `vreader://oauth/callback`.
- FR-11: `ASWebAuthenticationSession` — `prefersEphemeralWebBrowserSession = true`.
- FR-12: Никогда WKWebView для OAuth.

## Non-Functional Requirements
- NFR-01: OAuth flow завершается < 30s (включая пользовательский ввод).
- NFR-02: Token refresh прозрачен для пользователя.

## Boundaries (что НЕ входит)
- Не реализовывать UI подключения провайдеров (CloudConnectorView).
- Не реализовывать полный Google Drive/Dropbox/OneDrive API — только операции из CloudProviderProtocol.

## Acceptance Criteria
- [ ] OAuth flow через ASWebAuthenticationSession работает.
- [ ] PKCE реализован корректно.
- [ ] Tokens хранятся только в Keychain.
- [ ] Автоматический refresh работает.
- [ ] WKWebView нигде не используется для OAuth.

## Open Questions
- Как обрабатывать отмену OAuth пользователем (закрытие Safari)?
- Нужна ли поддержка Google Drive Shared Drives (Team Drives)?