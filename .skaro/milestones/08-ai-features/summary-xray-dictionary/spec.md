# Specification: summary-xray-dictionary

## Context
Summary (краткое содержание), X-Ray (анализ персонажей/мест) и Dictionary (определение слов) — Premium AI функции через Gemini API. Только онлайн. Фоновые запросы с timeout 30 секунд.

## User Scenarios
1. **Premium пользователь запрашивает Summary главы:** SummaryService генерирует краткое содержание за < 30 секунд.
2. **X-Ray:** XRayService анализирует текст, возвращает список персонажей и мест с описаниями.
3. **Пользователь long press на слово:** DictionaryService возвращает определение с контекстом.

## Functional Requirements
- FR-01: SummaryService — actor: func summarize(chapterText: String, bookTitle: String) async throws -> String. Premium only. Background priority.
- FR-02: XRayService — actor: func analyze(text: String) async throws -> XRayResult. XRayResult struct: characters ([XRayEntity]), places ([XRayEntity]), themes ([String]). XRayEntity: name, description, mentions (Int)
- FR-03: DictionaryService — actor: func define(word: String, context: String, language: String) async throws -> DictionaryEntry. DictionaryEntry: word, definition, examples ([String]), partOfSpeech
- FR-04: Все сервисы проверяют PremiumGate.check() перед запросом
- FR-05: Все сервисы проверяют NetworkMonitor.isOnline
- FR-06: Timeout 30 секунд (background priority в AIRequestQueue)
- FR-07: SummaryPanel View: sheet с текстом summary, кнопка копирования
- FR-08: XRayPanel View: список персонажей и мест с описаниями
- FR-09: DictionaryPopover View: popover при long press на слово
- FR-10: Все строки через L10n.AI.*

## Non-Functional Requirements
- NFR-01: Summary timeout 30 секунд
- NFR-02: Dictionary response < 10 секунд (interactive)

## Boundaries (что НЕ входит)
- Не кэшировать результаты X-Ray
- Не реализовывать оффлайн версии

## Acceptance Criteria
- [ ] SummaryService, XRayService, DictionaryService определены
- [ ] Premium gate проверяется
- [ ] Offline проверяется
- [ ] Таймауты соблюдаются
- [ ] UI панели реализованы
- [ ] Все строки через L10n

## Open Questions
- Нужно ли кэшировать X-Ray результаты в SwiftData для повторного использования?
- Как обрабатывать очень длинные главы (> 10000 слов) для Summary?