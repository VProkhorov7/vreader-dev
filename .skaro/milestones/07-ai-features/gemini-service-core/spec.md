# Specification: gemini-service-core

## Context
GeminiService — единственная точка входа для всех AI запросов. API ключ только из Keychain. Требует активного сетевого соединения. Circuit breaker: 3 ошибки → `.degraded`. Rate limiting с exponential backoff при 429.

## User Scenarios
1. **Пользователь запрашивает перевод offline:** Немедленная ошибка `.offline`, UI показывает banner.
2. **API возвращает 429:** RateLimiter применяет exponential backoff 1s → 2s → 4s → 8s → 16s.
3. **3 последовательные ошибки:** Circuit breaker переводит сервис в `.degraded`, пользователь уведомляется.

## Functional Requirements
- FR-01: `GeminiService` — final class, singleton `shared`.
- FR-02: API ключ ТОЛЬКО через `KeychainManager.shared.load(key: .geminiAPIKey)`.
- FR-03: `request(_ prompt: GeminiPrompt, priority: RequestPriority) async throws -> GeminiResponse`.
- FR-04: `GeminiPrompt` struct: `text: String`, `systemInstruction: String?`, `maxTokens: Int`.
- FR-05: `GeminiResponse` struct: `text: String`, `tokenCount: Int`, `finishReason: String`.
- FR-06: `RequestPriority` enum: `.interactive`, `.background`.
- FR-07: При `!NetworkMonitor.shared.isOnline` — немедленно бросает `AppError(.aiService(.offline))`.
- FR-08: `AIRequestQueue` — actor: очередь с приоритетами, максимум 3 одновременных запроса.
- FR-09: `RateLimiter` — actor: exponential backoff при 429. Начало 1s, максимум 32s, 5 попыток.
- FR-10: `QuotaTracker` — @Observable class: отслеживает использование токенов, сброс ежедневно.
- FR-11: `QuotaTracker.checkAvailable(estimatedTokens:) -> Bool`.
- FR-12: Circuit breaker: 3 ошибки → `.degraded` → уведомление → 60s → автовосстановление.
- FR-13: Timeout: `.interactive` = 10s, `.background` = 30s (из `DesignTokens.AI`).
- FR-14: API ключ никогда не логируется.

## Non-Functional Requirements
- NFR-01: Interactive запросы timeout 10s.
- NFR-02: Background запросы timeout 30s.
- NFR-03: Максимум 3 одновременных запроса.

## Boundaries (что НЕ входит)
- Не реализовывать конкретные AI функции (перевод, TTS) — только инфраструктуру.
- Не реализовывать UI quota display.

## Acceptance Criteria
- [ ] API ключ берётся только из Keychain.
- [ ] При offline — немедленная ошибка без сетевого запроса.
- [ ] RateLimiter применяет backoff при 429.
- [ ] Circuit breaker срабатывает при 3 ошибках.
- [ ] QuotaTracker отслеживает использование.
- [ ] API ключ не попадает в логи.

## Open Questions
- Какую модель Gemini использовать — gemini-pro или gemini-1.5-flash?
- Нужна ли поддержка streaming responses для длинных текстов?