# Specification: tts-service

## Context
TTS цепочка: Gemini TTS (Premium, онлайн) → AVSpeechSynthesizer Neural (Premium fallback, iOS 17+) → AVSpeechSynthesizer стандартный (Free, до 300 слов, оффлайн). Circuit breaker: 3 ошибки → следующий провайдер. ElevenLabs исключён.

## User Scenarios
1. **Premium пользователь онлайн:** Gemini TTS синтезирует главу с высоким качеством.
2. **Premium пользователь offline:** Fallback на AVSpeechSynthesizer Neural.
3. **Free пользователь:** AVSpeechSynthesizer стандартный, лимит 300 слов.
4. **Gemini TTS недоступен (3 ошибки):** Circuit breaker переключает на Neural fallback.

## Functional Requirements
- FR-01: `TTSProviderProtocol`: `func synthesize(text: String) async throws -> AVPlayerItem`, `var isAvailable: Bool`, `var requiresNetwork: Bool`, `var providerName: String`.
- FR-02: `GeminiTTSProvider` — реализует `TTSProviderProtocol`. Использует Gemini API. Только онлайн. Premium only.
- FR-03: `NeuralSpeechProvider` — `AVSpeechSynthesizer` с Neural voices (iOS 17+). Premium fallback. Работает оффлайн.
- FR-04: `StandardSpeechProvider` — `AVSpeechSynthesizer` стандартный. Free tier. Лимит 300 слов. Оффлайн.
- FR-05: `TTSService` — @Observable final class, singleton `shared`. Управляет цепочкой провайдеров.
- FR-06: `TTSService.speak(text:book:)` — выбирает провайдера по isPremium + isOnline + circuit breaker.
- FR-07: Circuit breaker: 3 последовательные ошибки провайдера → переключение на следующий.
- FR-08: `TTSService.stop()`, `pause()`, `resume()`.
- FR-09: `@Published var isSpeaking: Bool`, `currentWordRange: Range<String.Index>?` (для Immersion Reading).
- FR-10: `AVAudioSession.category = .playback` для фонового воспроизведения.
- FR-11: При offline и Gemini TTS запросе — немедленный fallback без ошибки пользователю.
- FR-12: `StandardSpeechProvider` проверяет лимит 300 слов через `PremiumGate`.

## Non-Functional Requirements
- NFR-01: Начало синтеза < 2s для стандартного провайдера.
- NFR-02: Фоновое воспроизведение TTS без прерываний.

## Boundaries (что НЕ входит)
- Не реализовывать Gemini API интеграцию — заглушка с правильным interface (реализация в milestone AI).
- Не реализовывать Immersion Reading UI.

## Acceptance Criteria
- [ ] `TTSProviderProtocol` определён.
- [ ] Все 3 провайдера реализованы.
- [ ] Circuit breaker переключает провайдеров при ошибках.
- [ ] Free лимит 300 слов соблюдается.
- [ ] Фоновое воспроизведение работает.
- [ ] При offline Gemini TTS — fallback без ошибки.

## Open Questions
- Как разбивать текст главы на чанки для Gemini TTS (лимит токенов)?
- Нужна ли очередь синтеза для предзагрузки следующего абзаца?