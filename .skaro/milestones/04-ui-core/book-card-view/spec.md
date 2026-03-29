# Specification: book-card-view

## Context
Карточка книги — основной UI элемент библиотеки. Соотношение 2:3, source badge, format badge, contentState badge, progress bar. Существующий `BookCardView.swift` требует ревизии согласно дизайн-системе.

## User Scenarios
1. **Пользователь видит cloudOnly книгу:** Отображается иконка облака, нет прогресс бара.
2. **Книга загружается:** Прогресс бар показывает процент загрузки.
3. **Long press на карточке:** Контекстное меню: Читать, Скачать/Удалить, Редактировать метаданные, Поделиться, Удалить.

## Functional Requirements
- FR-01: `BookCardView` — SwiftUI View, принимает `book: Book` и `downloadProgress: Double?`.
- FR-02: Соотношение сторон 2:3 (ширина:высота).
- FR-03: Обложка через `AsyncImage(url: CoverFetcher.shared.loadCover(for: book.id))` с placeholder.
- FR-04: `ContentStateBadge`: `.cloudOnly` → иконка облака, `.previewed` → частичная заливка (50%), `.downloaded` → нет badge.
- FR-05: `FormatBadge`: отображает формат (EPUB, PDF, FB2 и т.д.) в углу карточки.
- FR-06: `SourceBadge`: иконка источника (iCloud, Dropbox, Google Drive и т.д.).
- FR-07: Progress bar внизу карточки: `book.progress` (0.0-1.0) для прочитанного, `downloadProgress` для загрузки.
- FR-08: Контекстное меню через `.contextMenu`: Читать, Скачать (если не downloaded), Удалить файл (если downloaded), Редактировать метаданные, Поделиться, Удалить из библиотеки.
- FR-09: Все цвета и отступы через `DesignTokens` и `@Environment(\.appTheme)`.
- FR-10: VoiceOver: `accessibilityLabel` = "\(title), \(author), \(format), \(progress)%".
- FR-11: Dynamic Type поддержка для всех текстовых элементов.
- FR-12: Анимация прогресса загрузки.

## Non-Functional Requirements
- NFR-01: Рендеринг карточки < 16ms (один кадр).
- NFR-02: AsyncImage не блокирует scroll.

## Boundaries (что НЕ входит)
- Не реализовывать логику действий контекстного меню — только callbacks.
- Не реализовывать LibraryView grid.

## Acceptance Criteria
- [ ] Карточка отображается корректно для всех contentState.
- [ ] Badges отображаются правильно.
- [ ] Progress bar работает для прогресса чтения и загрузки.
- [ ] Контекстное меню содержит все пункты.
- [ ] VoiceOver label корректен.
- [ ] Существующий BookCardView.swift обновлён.

## Open Questions
- Нужна ли анимация при изменении contentState (cloudOnly → downloaded)?
- Как отображать книги без обложки — placeholder с инициалами или иконка формата?