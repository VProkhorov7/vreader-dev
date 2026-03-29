# Specification: gemini-tts-provider

## Context
Gemini TTS — основной провайдер для Premium пользователей. Только онлайн. Синтезирует чанки текста через Gemini API, воспроизводит через AVPlayer. Circuit breaker: 3 ошибки → fallback на NeuralSpeechProvider.

## User Scenarios
1. **Premium пользователь запускает TTS:** Gemini TTS синтезирует главу с высоким качеством голоса.
2. **Gemini TTS недоступен:** Circuit breaker переключает на AVSpeechSynthesizer Neural.
3. **Пользователь offline:** Немедленный fallback на Neural/Standard провайдер.

## Functional Requirements
- FR-01: `GeminiTTSProvider` — final class, реализует `TTSProviderProtocol`.
- FR-02: `requiresNetwork = true`, `isAvailable` = Premium + online.
- FR-03: `synthesize(text:)` — отправляет текст в Gemini TTS API, получает аудио данные.
- FR-04: Разбивка текста на чанки ≤ 1000 слов для API лимитов.
- FR-05: Возвращает `AVPlayerItem` из аудио данных.
- FR-06: Поддержка выбора голоса (мужской/женский) через настройки.
- FR-07: При ошибке — сообщает `TTSService` для circuit breaker.
- FR-08: API ключ через `KeychainManager.shared`.
- FR-09: Timeout 30s на чанк.

## Non-Functional Requirements
- NFR-01: Первый чанк начинает воспроизводиться < 3s.
- NFR-02: Streaming — следующий чанк синтезируется пока воспроизводится текущий.

## Boundaries (что НЕ входит)
- Не реализовывать Immersion Reading синхронизацию — milestone 10.
- ElevenLabs исключён полностью.

## Acceptance Criteria
- [ ] GeminiTTSProvider синтезирует речь корректно.
- [ ] Разбивка на чанки работает.
- [ ] Circuit breaker переключает на fallback при 3 ошибках.
- [ ] API ключ не логируется.
- [ ] Streaming воспроизведение работает.

## Open Questions
- Какой формат аудио возвращает Gemini TTS API — MP3 или WAV?
- Нужна ли поддержка SSML для управления интонацией?