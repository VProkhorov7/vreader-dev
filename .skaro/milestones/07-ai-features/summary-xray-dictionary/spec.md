# Specification: summary-xray-dictionary

## Context
Premium-only AI функции: Summary (краткое содержание главы), X-Ray (персонажи, места, термины), Dictionary (определение слова с контекстом). Только онлайн. Background timeout 30s.

## User Scenarios
1. **Premium пользователь запрашивает Summary главы:** Получает краткое содержание за < 30s.
2. **Пользователь нажимает на незнакомое слово:** DictionaryService возвращает определение с примерами.
3. **X-Ray для книги:** Список персонажей с описаниями и номерами страниц первого появления.

## Functional Requirements
- FR-01: `SummaryService` — final class, singleton `shared`. Premium only.
- FR-02: `summarize(chapter: String, bookTitle: String) async throws -> String`.
- FR-03: Использует `GeminiService.request` с `.background` приоритетом.
- FR-04: `XRayService` — final class, singleton `shared`. Premium only.
- FR-05: `analyzeBook(chapters: [String]) async throws -> XRayData`.
- FR-06: `XRayData` struct: `characters: [XRayEntity]`, `locations: [XRayEntity]`, `terms: [XRayEntity]`.
- FR-07: `XRayEntity` struct: `name: String`, `description: String`, `firstAppearancePage: Int`.
- FR-08: `DictionaryService` — final class, singleton `shared`. Premium only.
- FR-09: `define(word: String, context: String, language: String) async throws -> DictionaryEntry`.
- FR-10: `DictionaryEntry` struct: `word: String`, `definition: String`, `examples: [String]`, `partOfSpeech: String`.
- FR-11: Все сервисы проверяют `PremiumGate.check(.aiFeatures)` перед запросом.
- FR-12: При offline — немедленная ошибка через `GeminiService`.
- FR-13: Background timeout 30s.

## Non-Functional Requirements
- NFR-01: Summary главы < 30s.
- NFR-02: Dictionary lookup < 10s (interactive).

## Boundaries (что НЕ входит)
- Не реализовывать UI для X-Ray и Summary — только сервисы.
- Не кэшировать результаты между сессиями.

## Acceptance Criteria
- [ ] SummaryService работает для Premium пользователей.
- [ ] XRayService возвращает структурированные данные.
- [ ] DictionaryService возвращает определение с контекстом.
- [ ] Free пользователи получают ошибку `premiumRequired`.
- [ ] Timeout 30s соблюдается.

## Open Questions
- Как обрабатывать X-Ray для очень длинных книг (лимит токенов Gemini)?
- Нужно ли кэшировать X-Ray данные в SwiftData для повторного использования?