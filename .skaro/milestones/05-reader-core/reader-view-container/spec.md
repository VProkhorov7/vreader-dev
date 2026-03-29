# Specification: reader-view-container

## Context
`ReaderView` — контейнер, который выбирает нужный ридер (TextReaderView, ComicReaderView, AudioPlayerView) по формату книги. Auto-hide controls, жесты, frosted glass toolbar. Существующий `ReaderView.swift` требует ревизии.

## User Scenarios
1. **Пользователь открывает EPUB:** ReaderView определяет формат → показывает TextReaderView.
2. **Пользователь тапает на экран:** Controls появляются на 3 секунды, затем скрываются.
3. **Пользователь свайпает влево:** Переход к следующей странице/главе.

## Functional Requirements
- FR-01: `ReaderView` — SwiftUI View, принимает `book: Book`.
- FR-02: Маршрутизация по `book.format`: текстовые форматы → `TextReaderView`, комиксы → `ComicReaderView`, аудио → `AudioPlayerView`.
- FR-03: Auto-hide controls: тап → показать на 3s → скрыть. Таймер сбрасывается при каждом тапе.
- FR-04: `ReaderTopBar` — frosted glass (85% opacity + 20px blur), title книги, кнопки: назад, TOC, настройки, AI.
- FR-05: `ReaderBottomBar` — frosted glass, прогресс slider, номер страницы, кнопки навигации.
- FR-06: Offline banner в `ReaderTopBar` если `!NetworkMonitor.shared.isOnline`.
- FR-07: Жесты: swipe left/right для страниц, pinch для zoom (комиксы), long press для выделения текста.
- FR-08: Сохранение позиции при закрытии через `ReadingStateManager`.
- FR-09: Открытие книги: `FileReferenceResolver.resolve(book:)` → `FileFormatHandlerFactory.handler(for:)` → загрузка первой страницы.
- FR-10: При `book.contentState == .cloudOnly`: запускает `DownloadManager.download(book:)`, показывает прогресс.
- FR-11: `ReaderState.isFullscreen` управляет видимостью TabBar.

## Non-Functional Requirements
- NFR-01: Открытие книги P95 < 1s для первой страницы.
- NFR-02: Анимация переворота страницы 60fps.

## Boundaries (что НЕ входит)
- Не реализовывать конкретные ридеры — только контейнер.
- Не реализовывать AI панели.

## Acceptance Criteria
- [ ] Правильный ридер выбирается по формату.
- [ ] Auto-hide controls работают.
- [ ] Offline banner отображается при отсутствии сети.
- [ ] Позиция сохраняется при закрытии.
- [ ] Открытие книги P95 < 1s.

## Open Questions
- Нужна ли анимация 'page curl' или достаточно slide?
- Как обрабатывать ошибку открытия файла — показывать alert или возвращаться в библиотеку?