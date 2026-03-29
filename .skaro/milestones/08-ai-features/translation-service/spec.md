# Specification: translation-service

## Context
TranslationService реализует перевод текста через GeminiService. Free: до 500 слов на главу. Premium: полная глава. Только онлайн. TranslationPanel показывает offline banner и quota display.

## User Scenarios
1. **Пользователь выделяет текст и нажимает Перевести:** TranslationPanel открывается, перевод появляется через < 10 секунд.
2. **Free пользователь превышает 500 слов:** Показывается PremiumGate.
3. **Нет сети:** TranslationPanel показывает offline banner, кнопка перевода недоступна.

## Functional Requirements
- FR-01: TranslationService — actor
- FR-02: func translate(text: String, targetLanguage: String, isPremium: Bool) async throws -> TranslationResult
- FR-03: Free лимит: 500 слов. Premium: без лимита
- FR-04: TranslationResult struct: originalText, translatedText, detectedLanguage, wordCount
- FR-05: Проверка PremiumGate.check(.translation, wordCount:) перед запросом
- FR-06: Проверка QuotaTracker.checkAvailable() перед запросом
- FR-07: TranslationPanel View: sheet/popover с оригинальным и переведённым текстом
- FR-08: Offline banner в TranslationPanel если NetworkMonitor.isOnline == false
- FR-09: Quota display: "Использовано X из Y слов сегодня"
- FR-10: Индикатор загрузки во время перевода
- FR-11: Кнопка копирования переведённого текста
- FR-12: Все строки через L10n.AI.*

## Non-Functional Requirements
- NFR-01: Перевод появляется < 10 секунд (interactive timeout)
- NFR-02: TranslationPanel не блокирует чтение

## Boundaries (что НЕ входит)
- Не кэшировать переводы
- Не реализовывать оффлайн перевод
- Не реализовывать перевод всей книги

## Acceptance Criteria
- [ ] TranslationService actor определён
- [ ] Free лимит 500 слов соблюдается
- [ ] TranslationPanel показывает перевод
- [ ] Offline banner показывается
- [ ] Quota display работает
- [ ] PremiumGate проверяется
- [ ] Все строки через L10n

## Open Questions
- Нужна ли поддержка автоопределения языка оригинала?
- Как обрабатывать перевод текста с несколькими языками?