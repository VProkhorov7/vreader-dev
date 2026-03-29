# Specification: tts-service-basic

## Context
TTSService реализует цепочку провайдеров. На этом этапе только AVSpeechSynthesizer (Free tier, до 300 слов, работает оффлайн). Gemini TTS добавляется в milestone 06. TTSProviderProtocol обеспечивает расширяемость.

## User Scenarios
1. **Free пользователь нажимает TTS:** AVSpeechSynthesizer читает до 300 слов текущей страницы.
2. **Превышен лимит 300 слов:** Показывается PremiumGate с предложением Premium.
3. **Устройство оффлайн:** TTS работает через AVSpeechSynthesizer без сети.

## Functional Requirements
- FR-01: Протокол TTSProviderProtocol: func synthesize(text: String) async throws -> AVPlayerItem, var isAvailable: Bool, var requiresNetwork: Bool, var providerName: String
- FR-02: AVSpeechSynthesizerProvider реализует TTSProviderProtocol: requiresNetwork = false
- FR-03: TTSService — @Observable singleton: func speak(text: String, language: String) async throws, func stop(), func pause(), func resume(), var isPlaying: Bool, var currentProvider: String
- FR-04: Free tier лимит: 300 слов. При превышении → VReaderError с ErrorCode.premiumRequired
- FR-05: Определение языка текста для выбора голоса AVSpeechSynthesizer
- FR-06: Интеграция с AVAudioSession для фонового воспроизведения
- FR-07: Circuit breaker: при 3 ошибках → переключение на следующий провайдер в цепочке
- FR-08: Логирование через DiagnosticsService

## Non-Functional Requirements
- NFR-01: Начало воспроизведения < 500ms
- NFR-02: Работает оффлайн

## Boundaries (что НЕ входит)
- Не реализовывать Gemini TTS (milestone 06)
- Не реализовывать Neural voices (milestone 06)
- Не реализовывать Immersion Reading (milestone 10)

## Acceptance Criteria
- [ ] TTSProviderProtocol определён
- [ ] AVSpeechSynthesizerProvider реализован
- [ ] TTSService.shared работает
- [ ] Лимит 300 слов для Free tier соблюдается
- [ ] Работает оффлайн
- [ ] Circuit breaker реализован

## Open Questions
- Какой язык использовать по умолчанию если язык текста не определён?
- Нужна ли поддержка нескольких голосов на выбор пользователя?