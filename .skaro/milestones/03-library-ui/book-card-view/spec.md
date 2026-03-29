# Specification: book-card-view

## Context
BookCardView — основной визуальный элемент библиотеки. Карточка отображает состояние книги через badges: cloudOnly (облачко), previewed (частичная заливка), downloaded (нет badge). Использует AsyncImage для lazy loading обложки. Все значения через DesignTokens и @Environment(\.appTheme).

## User Scenarios
1. **Пользователь видит библиотеку:** Карточки отображают обложки, прогресс чтения, источник и формат.
2. **Книга в состоянии cloudOnly:** Показывается иконка облака, нет прогресс бара.
3. **Книга загружается:** Показывается прогресс загрузки на карточке.
4. **Книга прочитана на 60%:** Прогресс бар заполнен на 60%.

## Functional Requirements
- FR-01: BookCardView принимает book: Book и опциональный downloadProgress: Double?
- FR-02: Соотношение сторон 2:3 (ширина:высота)
- FR-03: Обложка через AsyncImage(url: URL(fileURLWithPath: book.coverPath)) с placeholder
- FR-04: ContentState badge: cloudOnly → SF Symbol "icloud" в углу, previewed → частичная заливка снизу (30%), downloaded → нет badge
- FR-05: Source badge: маленький цветной badge с иконкой провайдера (iCloud, Google Drive, etc.)
- FR-06: Format badge: маленький текстовый badge с форматом (PDF, EPUB, FB2)
- FR-07: Progress bar внизу карточки: высота 3px, цвет accent из темы
- FR-08: При downloadProgress != nil: показывать прогресс загрузки поверх карточки
- FR-09: Скругление углов через DesignTokens.Radius.card
- FR-10: Тень/elevation через фоновый сдвиг (не 1px border согласно дизайн-правилам)
- FR-11: Поддержка VoiceOver: accessibilityLabel = "\(title) by \(author), \(format), \(contentState)"
- FR-12: Поддержка Dynamic Type для badge текстов
- FR-13: Все цвета через @Environment(\.appTheme)

## Non-Functional Requirements
- NFR-01: Рендеринг карточки < 16ms (60fps)
- NFR-02: AsyncImage не блокирует scroll

## Boundaries (что НЕ входит)
- Не реализовывать контекстное меню (это LibraryView)
- Не реализовывать анимацию загрузки обложки (только fade-in)
- Не реализовывать drag & drop

## Acceptance Criteria
- [ ] BookCardView отображает обложку через AsyncImage
- [ ] Все три contentState badge реализованы
- [ ] Progress bar отображается корректно
- [ ] Все цвета через appTheme
- [ ] VoiceOver label корректен
- [ ] Нет хардкод числовых значений (только DesignTokens)
- [ ] Карточка корректно отображается в обеих темах (EditorialDark, CuratorLight)

## Open Questions
- Нужна ли анимация при изменении contentState (cloudOnly → downloaded)?
- Как отображать карточку для аудиокниг (MP3/M4B) — другой placeholder?