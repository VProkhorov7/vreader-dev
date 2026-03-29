# Specification: accessibility

## Context
Все UI компоненты должны поддерживать VoiceOver и Dynamic Type. Минимальный шрифт .caption2 (DesignTokens). Это требование архитектуры, не опциональная функция.

## User Scenarios
1. **Пользователь с нарушением зрения использует VoiceOver:** Все элементы имеют корректные accessibilityLabel и accessibilityHint.
2. **Пользователь увеличивает размер шрифта в настройках iOS:** UI адаптируется без обрезания текста.
3. **Пользователь использует Switch Control:** Все интерактивные элементы доступны.

## Functional Requirements
- FR-01: Все кнопки имеют accessibilityLabel (не только иконки)
- FR-02: BookCardView: accessibilityLabel = "\(title), \(author), \(format), прогресс \(progress)%"
- FR-03: Все изображения имеют accessibilityLabel или accessibilityHidden(true) для декоративных
- FR-04: Dynamic Type: все текстовые элементы используют .font(.body) и т.д. (не фиксированные размеры)
- FR-05: Минимальный шрифт .caption2 (DesignTokens.Typography)
- FR-06: Контрастность: все текстовые элементы соответствуют WCAG AA (4.5:1)
- FR-07: Минимальный размер тапабельной области: 44×44pt
- FR-08: ReaderView: accessibilityActions для навигации по главам
- FR-09: Тестирование с VoiceOver включённым

## Non-Functional Requirements
- NFR-01: Все интерактивные элементы доступны через VoiceOver
- NFR-02: Dynamic Type работает до xxxLarge без обрезания

## Boundaries (что НЕ входит)
- Не реализовывать RTL layout (milestone 09 локализация)
- Не реализовывать специальные жесты для VoiceOver

## Acceptance Criteria
- [ ] Все кнопки имеют accessibilityLabel
- [ ] BookCardView имеет корректный accessibilityLabel
- [ ] Dynamic Type работает для всех текстовых элементов
- [ ] Минимальный размер тапабельной области 44×44pt
- [ ] Контрастность WCAG AA соблюдается
- [ ] VoiceOver навигация работает в ReaderView

## Open Questions
- Нужна ли поддержка Reduce Motion для анимаций?
- Как обрабатывать VoiceOver в ComicReaderView (изображения без текста)?