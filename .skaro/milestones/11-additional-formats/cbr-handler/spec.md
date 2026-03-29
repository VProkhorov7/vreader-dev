# Specification: cbr-handler

## Context
CBR файлы — это RAR архивы с изображениями комиксов. Требуется UnRAR SDK или открытая реализация для распаковки. CBRHandler реализует FileFormatHandler и интегрируется с ComicReaderView.

## User Scenarios
1. **Пользователь открывает CBR файл:** CBRHandler распаковывает RAR, показывает первую страницу.
2. **Листание страниц:** Lazy loading изображений из RAR архива.

## Functional Requirements
- FR-01: CBRHandler реализует FileFormatHandler
- FR-02: Распаковка RAR через UnRAR SDK (C библиотека через Swift bridging) или открытую реализацию
- FR-03: Сортировка изображений по имени файла
- FR-04: Lazy loading: распаковывать только запрошенную страницу
- FR-05: Поддержка RAR4 и RAR5 форматов
- FR-06: Интеграция с ComicReaderView
- FR-07: Ошибки через VReaderError с ErrorCode.parsing

## Non-Functional Requirements
- NFR-01: Открытие первой страницы < 1 секунда
- NFR-02: Не распаковывать весь архив в память

## Boundaries (что НЕ входит)
- Не реализовывать CBT (TAR) и CB7 (7-Zip) на этом этапе

## Acceptance Criteria
- [ ] CBRHandler реализует FileFormatHandler
- [ ] RAR4 и RAR5 поддерживаются
- [ ] Lazy loading работает
- [ ] Интеграция с ComicReaderView

## Open Questions
- Какую UnRAR библиотеку использовать (лицензионные ограничения)?
- Нужна ли поддержка зашифрованных RAR архивов?