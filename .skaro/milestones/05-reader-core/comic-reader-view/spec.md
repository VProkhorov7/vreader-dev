# Specification: comic-reader-view

## Context
Ридер для комиксов и манги. Поддержка zoom, guided view (автоматическое выделение панелей), RTL для манги. Существующий `ComicReaderView.swift` требует ревизии.

## User Scenarios
1. **Пользователь читает комикс:** Страница отображается на весь экран, можно зумить.
2. **Пользователь включает guided view:** Приложение автоматически переходит между панелями.
3. **Пользователь читает мангу:** RTL листание (справа налево).

## Functional Requirements
- FR-01: `ComicReaderView` — SwiftUI View, принимает `book: Book`, `handler: any FileFormatHandler`.
- FR-02: Отображение страниц через `Image` с `resizable().aspectRatio(contentMode: .fit)`.
- FR-03: Pinch-to-zoom: `MagnificationGesture`, минимум 1x, максимум 5x.
- FR-04: Double-tap для zoom in/out (1x ↔ 2x).
- FR-05: Горизонтальное листание страниц (swipe left/right).
- FR-06: RTL режим: swipe right → следующая страница (для манги). Настройка в ReaderSettingsPanel.
- FR-07: Guided view: базовая реализация — переход между страницами без автоматического выделения панелей (полный guided view — milestone 10).
- FR-08: Предзагрузка следующей и предыдущей страницы.
- FR-09: Индикатор страницы внизу (текущая / всего).
- FR-10: Landscape режим: две страницы рядом (spread view).

## Non-Functional Requirements
- NFR-01: Zoom анимация 60fps.
- NFR-02: Загрузка страницы < 300ms.

## Boundaries (что НЕ входит)
- Не реализовывать полный guided view с детекцией панелей — milestone 10.
- Не реализовывать аннотации для комиксов.

## Acceptance Criteria
- [ ] Страницы CBZ отображаются корректно.
- [ ] Pinch-to-zoom работает плавно.
- [ ] RTL режим переключается в настройках.
- [ ] Landscape spread view работает.
- [ ] Существующий ComicReaderView.swift обновлён.

## Open Questions
- Как определять автоматически RTL для манги — по имени файла или настройке?
- Нужна ли поддержка двойных страниц (double page spread) в portrait режиме?