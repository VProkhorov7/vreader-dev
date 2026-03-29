# Specification: accessibility-polish

## Context
Все UI компоненты должны поддерживать VoiceOver и Dynamic Type согласно архитектуре. Минимальный шрифт `.caption2` из DesignTokens.

## User Scenarios
1. **Пользователь с нарушением зрения использует VoiceOver:** Все элементы имеют понятные accessibilityLabel.
2. **Пользователь увеличивает размер шрифта системы:** UI адаптируется без обрезания текста.
3. **Пользователь использует Switch Control:** Все интерактивные элементы доступны.

## Functional Requirements
- FR-01: Все `BookCardView` имеют `accessibilityLabel` с title, author, format, progress.
- FR-02: Все кнопки имеют `accessibilityLabel` и `accessibilityHint`.
- FR-03: Dynamic Type: все текстовые элементы используют `Font` из DesignTokens (не фиксированные размеры).
- FR-04: Минимальный шрифт `.caption2` соблюдается везде.
- FR-05: `accessibilityElement(children: .combine)` для составных компонентов.
- FR-06: Progress bars имеют `accessibilityValue` с процентом.
- FR-07: Изображения (обложки) имеют `accessibilityLabel` с названием книги.
- FR-08: Модальные окна (sheets) имеют `accessibilityViewIsModal = true`.
- FR-09: Анимации уважают `UIAccessibility.isReduceMotionEnabled`.
- FR-10: Цветовой контраст соответствует WCAG AA (4.5:1 для текста).

## Non-Functional Requirements
- NFR-01: VoiceOver навигация по всем экранам без застреваний.
- NFR-02: Dynamic Type XXL не ломает layout.

## Boundaries (что НЕ входит)
- Не реализовывать кастомные accessibility actions для ридера — базовая поддержка.

## Acceptance Criteria
- [ ] VoiceOver читает все элементы корректно.
- [ ] Dynamic Type XXL работает без обрезания.
- [ ] Reduce Motion уважается в анимациях.
- [ ] Цветовой контраст WCAG AA соблюдается.
- [ ] Минимальный шрифт .caption2 везде.

## Open Questions
- Нужна ли поддержка Braille display через VoiceOver?
- Как обрабатывать accessibility для WKWebView контента в TextReaderView?