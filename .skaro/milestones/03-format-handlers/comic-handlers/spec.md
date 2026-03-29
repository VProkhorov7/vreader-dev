# Specification: comic-handlers

## Context
Комикс-форматы — архивы с изображениями. CBZ (ZIP) — нативный, CBR (RAR) требует UnRAR SDK, CBT (TAR) — нативный, CB7 (7-Zip) требует 7-Zip SDK. Страницы сортируются по имени файла.

## User Scenarios
1. **Пользователь открывает CBZ манга:** Страницы отображаются в правильном порядке с поддержкой RTL листания.
2. **Пользователь открывает CBR:** Файл распаковывается через UnRAR SDK.
3. **Пользователь использует guided view:** Панели комикса автоматически выделяются и масштабируются.

## Functional Requirements
- FR-01: `CBZHandler` — final class, реализует `FileFormatHandler`. Использует нативный ZIP.
- FR-02: `CBRHandler` — final class, реализует `FileFormatHandler`. Использует AMSMB2 или UnRAR SDK через C bridging.
- FR-03: `CBTHandler` — final class, реализует `FileFormatHandler`. TAR парсер.
- FR-04: `CB7Handler` — final class, реализует `FileFormatHandler`. 7-Zip SDK через C bridging.
- FR-05: Все обработчики: `openPage(_ index: Int)` возвращает `.image(UIImage, pageIndex:)`.
- FR-06: Сортировка страниц: натуральная сортировка по имени файла (001.jpg < 002.jpg < 010.jpg).
- FR-07: Поддерживаемые форматы изображений: JPEG, PNG, WebP, GIF (первый кадр).
- FR-08: `extractCover()` — первое изображение архива.
- FR-09: `extractMetadata()` — из ComicInfo.xml если присутствует (ComicRack формат).
- FR-10: Lazy loading: изображения загружаются по запросу, не все сразу.

## Non-Functional Requirements
- NFR-01: Открытие первой страницы CBZ < 500ms.
- NFR-02: Изображение страницы масштабируется до ≤ 50MB в памяти.

## Boundaries (что НЕ входит)
- Не реализовывать guided view алгоритм — только обработчик данных.
- Не поддерживать зашифрованные архивы.

## Acceptance Criteria
- [ ] CBZ открывается и страницы отображаются в правильном порядке.
- [ ] Натуральная сортировка работает корректно.
- [ ] ComicInfo.xml парсится если присутствует.
- [ ] Lazy loading работает — не все изображения в памяти.
- [ ] CBR, CBT, CB7 обработчики компилируются (реализация может быть stub для CBR/CB7 без SDK).

## Open Questions
- Какой UnRAR SDK использовать — открытый unrar или коммерческий?
- Нужна ли поддержка многотомных архивов (001.cbr, 002.cbr)?