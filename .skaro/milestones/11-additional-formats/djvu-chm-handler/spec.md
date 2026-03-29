# Specification: djvu-chm-handler

## Context
DJVU и CHM форматы требуют C библиотек: libdjvu и libchm. Интеграция через Swift bridging header. DJVUHandler рендерит страницы в изображения. CHMHandler извлекает HTML контент.

## User Scenarios
1. **Пользователь открывает DJVU файл:** DJVUHandler рендерит первую страницу через libdjvu.
2. **Открытие CHM справки:** CHMHandler извлекает HTML страницы через libchm.

## Functional Requirements
- FR-01: DJVUHandler реализует FileFormatHandler
- FR-02: Использует libdjvu через C bridging
- FR-03: Рендеринг страниц DJVU в UIImage
- FR-04: CHMHandler реализует FileFormatHandler
- FR-05: Использует libchm через C bridging
- FR-06: Извлечение HTML страниц из CHM
- FR-07: Навигация по оглавлению CHM
- FR-08: Ошибки через VReaderError с ErrorCode.parsing
- FR-09: Обновление VReader-Bridging-Header.h

## Non-Functional Requirements
- NFR-01: Рендеринг DJVU страницы < 2 секунды
- NFR-02: C библиотеки не вызывают memory leaks

## Boundaries (что НЕ входит)
- Не реализовывать редактирование DJVU
- Не реализовывать поиск по CHM на этом этапе

## Acceptance Criteria
- [ ] DJVUHandler рендерит страницы
- [ ] CHMHandler извлекает HTML
- [ ] C библиотеки интегрированы через bridging header
- [ ] Нет memory leaks
- [ ] Ошибки типизированы

## Open Questions
- Какую версию libdjvu использовать?
- Как обрабатывать многотомные DJVU файлы?