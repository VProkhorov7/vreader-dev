# Specification: comic-reader-view

## Context
ComicReaderView предназначен для чтения комиксов (CBZ). Основные функции: zoom pinch-to-zoom, guided view (автоматическое перемещение по панелям), горизонтальная навигация. CBZHandler реализует FileFormatHandler для ZIP с изображениями.

## User Scenarios
1. **Пользователь открывает CBZ:** Видит первую страницу комикса, может листать горизонтально.
2. **Pinch-to-zoom:** Увеличивает страницу для чтения мелкого текста.
3. **Double tap:** Zoom to fit или zoom to 100%.

## Functional Requirements
- FR-01: CBZHandler: распаковка ZIP, сортировка изображений по имени, загрузка как Data
- FR-02: Горизонтальная навигация между страницами (TabView с PageTabViewStyle)
- FR-03: Pinch-to-zoom через MagnificationGesture
- FR-04: Double tap: toggle между fit и 100%
- FR-05: Pan gesture при zoom > 1x
- FR-06: Предзагрузка следующей страницы
- FR-07: Поддержка landscape (две страницы рядом как разворот)
- FR-08: Индикатор страницы
- FR-09: Интеграция с ReaderView (те же панели управления)

## Non-Functional Requirements
- NFR-01: Zoom анимация 60fps
- NFR-02: Изображения загружаются lazy

## Boundaries (что НЕ входит)
- Не реализовывать CBR (RAR архив) на этом этапе
- Не реализовывать guided view автоматически (только ручная навигация)

## Acceptance Criteria
- [ ] CBZHandler реализован
- [ ] Горизонтальная навигация работает
- [ ] Pinch-to-zoom работает
- [ ] Double tap zoom работает
- [ ] Landscape режим показывает разворот
- [ ] Предзагрузка работает

## Open Questions
- Нужна ли поддержка WebP изображений в CBZ?
- Как определять правильный порядок страниц при нестандартных именах файлов?