# Specification: gemini-service

## Context
ADR-004 определяет Gemini API как единственный AI провайдер. GeminiService — единая точка входа. API ключ только из KeychainManager. Все запросы через AIRequestQueue с приоритетами. RateLimiter обрабатывает 429. QuotaTracker отслеживает использование.

## User Scenarios
1. **Пользователь запрашивает перевод:** GeminiService.translate() → AIRequestQueue.enqueue(.interactive) → RateLimiter → Gemini API.
2. **Gemini API возвращает 429:** RateLimiter применяет exponential backoff 1s → 2s → 4s → 8s → 32s.
3. **Нет сети:** GeminiService немедленно возвращает VReaderError.offline().
4. **3 последовательные ошибки:** Circuit breaker переводит в .degraded, пользователь уведомляется.

## Functional Requirements
- FR-01: GeminiService — actor
- FR-02: API ключ ТОЛЬКО через KeychainManager.shared.load(.geminiAPIKey)
- FR-03: func translate(text: String, targetLanguage: String) async throws -> String
- FR-04: func summarize(text: String) async throws -> String
- FR-05: func xray(text: String) async throws -> XRayResult
- FR-06: func define(word: String, context: String) async throws -> DictionaryEntry
- FR-07: func synthesizeSpeech(text: String, language: String) async throws -> Data
- FR-08: Проверка NetworkMonitor.isOnline перед каждым запросом. Если false → VReaderError.offline()
- FR-09: AIRequestQueue — actor: enum Priority: interactive, background. Максимум 3 одновременных запроса
- FR-10: RateLimiter: exponential backoff при 429. Начало 1s, максимум 32s, попыток 5
- FR-11: QuotaTracker — @Observable: var dailyUsage: Int, var dailyLimit: Int, func recordUsage(wordCount: Int), func checkAvailable(wordCount: Int) -> Bool, сброс ежедневно
- FR-12: Таймауты: interactive 10s, background 30s
- FR-13: Circuit breaker: 3 ошибки → .degraded, автовосстановление 60 секунд
- FR-14: Логирование через DiagnosticsService без содержимого запросов

## Non-Functional Requirements
- NFR-01: Interactive запросы timeout 10s
- NFR-02: Background запросы timeout 30s
- NFR-03: API ключ никогда не логируется

## Boundaries (что НЕ входит)
- Не реализовывать UI для AI функций
- Не кэшировать результаты переводов (опционально в milestone 10)
- ElevenLabs исключён

## Acceptance Criteria
- [ ] GeminiService actor определён
- [ ] API ключ берётся из Keychain
- [ ] Все 5 методов реализованы
- [ ] Проверка isOnline перед запросом
- [ ] AIRequestQueue с приоритетами работает
- [ ] RateLimiter с exponential backoff работает
- [ ] QuotaTracker сбрасывается ежедневно
- [ ] Circuit breaker реализован
- [ ] Таймауты соблюдаются

## Open Questions
- Какую модель Gemini использовать для каждого типа запроса (gemini-pro vs gemini-flash)?
- Нужна ли поддержка streaming ответов для длинных Summary?