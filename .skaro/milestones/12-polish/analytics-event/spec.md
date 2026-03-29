# Specification: analytics-event

## Context
AnalyticsEvent определяет все события аналитики. Сбор только с явного согласия пользователя (GDPR). Никаких PII в событиях. DiagnosticsService используется для локального логирования, аналитика — для агрегированных метрик.

## User Scenarios
1. **Пользователь даёт согласие на аналитику:** AnalyticsService начинает отправку событий.
2. **Пользователь открывает книгу:** bookOpened(format:source:contentState:) отправляется.
3. **Пользователь отзывает согласие:** Все события прекращаются, локальные данные удаляются.

## Functional Requirements
- FR-01: enum AnalyticsEvent: bookOpened(format: BookFormat, source: ContentSource, contentState: BookContentState), cloudConnected(provider: String), premiumPurchased(productID: String), aiTranslationUsed(wordCount: Int, isOnline: Bool), syncCompleted(recordCount: Int, duration: TimeInterval), errorOccurred(code: String), offlineModeEntered(), previewDownloaded(format: BookFormat), bookDownloaded(format: BookFormat, source: ContentSource)
- FR-02: AnalyticsService — actor: func track(_ event: AnalyticsEvent), var isEnabled: Bool
- FR-03: Согласие пользователя: onboarding экран с явным opt-in
- FR-04: Согласие хранится в iCloudSettingsStore
- FR-05: При isEnabled == false: все track() вызовы игнорируются
- FR-06: Никаких PII в событиях: нет email, имён файлов с личными данными, токенов
- FR-07: Локальное логирование событий через DiagnosticsService

## Non-Functional Requirements
- NFR-01: track() не блокирует вызывающий поток
- NFR-02: GDPR compliant: право на удаление данных

## Boundaries (что НЕ входит)
- Не реализовывать отправку на сервер аналитики (только локально на этом этапе)
- Не реализовывать A/B тестирование

## Acceptance Criteria
- [ ] AnalyticsEvent enum определён со всеми событиями
- [ ] AnalyticsService.shared работает
- [ ] Согласие пользователя проверяется
- [ ] При isEnabled == false события не логируются
- [ ] Нет PII в событиях

## Open Questions
- Какой аналитический сервис использовать (Firebase Analytics, Mixpanel, собственный)?
- Нужен ли onboarding экран согласия или достаточно Settings toggle?