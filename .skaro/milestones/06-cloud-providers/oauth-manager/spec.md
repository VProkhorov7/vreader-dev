# Specification: oauth-manager

## Context
ADR-005 требует OAuth только через ASWebAuthenticationSession. OAuthManager управляет PKCE flow для Google Drive, Dropbox и OneDrive. Токены хранятся только в Keychain. WKWebView для OAuth запрещён.

## User Scenarios
1. **Пользователь подключает Google Drive:** OAuthManager открывает ASWebAuthenticationSession, получает code, обменивает на tokens, сохраняет в Keychain.
2. **Access token истёк:** OAuthManager автоматически обновляет через refresh token.
3. **Пользователь отключает провайдер:** OAuthManager удаляет tokens из Keychain.

## Functional Requirements
- FR-01: OAuthManager — actor
- FR-02: func authorize(provider: OAuthProvider, presentationContext: ASWebAuthenticationPresentationContextProviding) async throws — PKCE flow
- FR-03: PKCE: генерация code_verifier (43-128 символов), code_challenge = SHA256(code_verifier) base64url
- FR-04: ASWebAuthenticationSession с callbackURLScheme = "vreader"
- FR-05: func refreshToken(for provider: OAuthProvider) async throws — обновление access token
- FR-06: func revokeToken(for provider: OAuthProvider) async throws — отзыв и удаление из Keychain
- FR-07: OAuthProvider enum: googleDrive, dropbox, oneDrive с соответствующими endpoints
- FR-08: Автоматический refresh при 401 ответе от провайдера
- FR-09: Tokens хранятся через KeychainManager.shared (KeychainKey.googleDriveAccessToken и т.д.)
- FR-10: Никогда WKWebView — проверяется code review
- FR-11: State parameter для защиты от CSRF

## Non-Functional Requirements
- NFR-01: PKCE code_verifier генерируется криптографически безопасно (SecRandomCopyBytes)
- NFR-02: Tokens не логируются

## Boundaries (что НЕ входит)
- Не реализовывать конкретные API провайдеров (только OAuth)
- Не реализовывать UI для авторизации (только ASWebAuthenticationSession)

## Acceptance Criteria
- [ ] OAuthManager actor определён
- [ ] PKCE flow реализован корректно
- [ ] ASWebAuthenticationSession используется (не WKWebView)
- [ ] Tokens хранятся в Keychain
- [ ] Автоматический refresh при 401 работает
- [ ] State parameter для CSRF защиты
- [ ] Tokens не попадают в логи

## Open Questions
- Нужна ли поддержка OAuth на Mac Catalyst (другой presentationContext)?
- Как обрабатывать случай когда пользователь закрывает окно авторизации?