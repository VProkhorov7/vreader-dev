# Specification: gemini-tts-provider

## Context
GeminiTTSProvider — Premium TTS провайдер через Gemini API. Работает только онлайн. При деградации Gemini TTS автоматически fallback на AVSpeechSynthesizer Neural voices (Premium) или стандартный AVSpeechSynthesizer (Free). Circuit breaker: 3 ошибки → переключение на следующий провайдер.

## User Scenarios
1. **Premium пользователь нажимает TTS:** GeminiTTSProvider синтезирует речь, воспроизводит через AVPlayer.
2. **Gemini TTS недоступен:** Автоматический fallback на AVSpeechSynthesizer Neural voices.
3. **Нет сети:** Немедленный fallback на AVSpeechSynthesizer.

## Functional Requirements
- FR-01: GeminiTTSProvider реализует TTSProviderProtocol: requiresNetwork = true
- FR-02: synthesize(text:) → вызывает GeminiService.synthesizeSpeech() → возвращает AVPlayerItem
- FR-03: Аудио данные воспроизводятся через AVPlayer (чанки)
- FR-04: TTSService цепочка: GeminiTTS (Premium, online) → AVSpeechSynthesizer Neural (Premium fallback, iOS 17+) → AVSpeechSynthesizer стандартный (Free, offline)
- FR-05: Circuit breaker в TTSService: 3 ошибки GeminiTTS → переключение на Neural voices
- FR-06: AVSpeechSynthesizer Neural voices: AVSpeechSynthesisVoice с quality = .enhanced (iOS 17+)
- FR-07: Интеграция с AVAudioSession для фонового воспроизведения
- FR-08: Обновление Now Playing Info при TTS воспроизведении
- FR-09: Premium проверка через PremiumGate.check(.tts)

## Non-Functional Requirements
- NFR-01: Начало воспроизведения < 2 секунды
- NFR-02: Плавное воспроизведение без пауз между чанками

## Boundaries (что НЕ входит)
- ElevenLabs исключён
- Не реализовывать Immersion Reading (milestone 10)
- Не реализовывать кастомные голоса

## Acceptance Criteria
- [ ] GeminiTTSProvider реализует TTSProviderProtocol
- [ ] Цепочка провайдеров работает
- [ ] Fallback при деградации Gemini TTS
- [ ] Neural voices используются для Premium fallback
- [ ] Фоновое воспроизведение работает
- [ ] Premium проверка работает

## Open Questions
- Какой формат аудио возвращает Gemini TTS API (MP3, WAV, OGG)?
- Нужна ли буферизация аудио чанков для плавного воспроизведения?