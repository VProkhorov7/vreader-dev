# Specification: translation-service

## Context
Перевод через Gemini API. Free: до 500 слов на главу. Premium: полная глава. Только онлайн. TranslationPanel показывает offline banner при отсутствии сети. Quota display в панели.

## User Scenarios
1. **Пользователь выделяет текст и нажимает 'Перевести':** TranslationPanel открывается с переводом.
2. **Free пользователь пытается перевести 600 слов:** Показывается лимит и предложение Premium.
3. **Устройство offline:** TranslationPanel показывает NetworkUnavailableView.

## Functional Requirements
- FR-01: `TranslationService` — final class, singleton `shared`.
- FR-02: `translate(text: String, targetLanguage: String) async throws -> String`.
- FR-03: Free лимит: 500 слов. Premium: без ограничений. Проверка через `PremiumGate`.
- FR-04: При превышении лимита — `AppError(.aiService(.quotaExceeded))`.
- FR-05: `TranslationPanel` — SwiftUI View (sheet): исходный текст, перевод, язык перевода, quota display.
- FR-06: При offline — `NetworkUnavailableView` вместо панели перевода.
- FR-07: Offline banner в панели если `!NetworkMonitor.shared.isOnline`.
- FR-08: `QuotaTracker` отображает использованные/доступные слова.
- FR-09: Поддерживаемые языки: RU, EN, DE, FR, ES, ZH, JA, KO (минимум).
- FR-10: Кэширование перевода в сессии (не между сессиями) для повторных запросов.
- FR-11: Все строки через `L10n.*`.

## Non-Functional Requirements
- NFR-01: Перевод 500 слов < 10s (interactive timeout).

## Boundaries (что НЕ входит)
- Не реализовывать оффлайн перевод.
- Не сохранять переводы в SwiftData.

## Acceptance Criteria
- [ ] Перевод работает для Premium пользователей.
- [ ] Free лимит 500 слов соблюдается.
- [ ] TranslationPanel показывает offline banner.
- [ ] Quota display работает.
- [ ] Timeout 10s соблюдается.

## Open Questions
- Нужна ли поддержка автоопределения языка источника?
- Как обрабатывать перевод текста с кодом или формулами?