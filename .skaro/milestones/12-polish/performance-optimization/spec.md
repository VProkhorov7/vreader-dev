# Specification: performance-optimization

## Context
Инварианты #7, #8, #9 определяют конкретные SLA. Необходимо измерить и оптимизировать: загрузку библиотеки, открытие книги и memory budget ридера. Используются Instruments для профилирования.

## User Scenarios
1. **Библиотека с 1000 книг:** Открытие LibraryView < 300ms P95.
2. **Открытие большого PDF:** Первая страница < 1 секунда P95.
3. **Чтение длинной книги:** Memory usage ридера не превышает 150MB (3 страницы × 50MB).

## Functional Requirements
- FR-01: Измерение P95 загрузки LibraryView с 1000 книг через XCTest Performance
- FR-02: Если P95 > 300ms: оптимизировать @Query предикаты, добавить индексы в SwiftData
- FR-03: Измерение P95 открытия книги для каждого формата
- FR-04: Если P95 > 1s: оптимизировать FileFormatHandler.openPage(0)
- FR-05: Измерение memory usage ридера при чтении
- FR-06: Если memory > 150MB: проверить и исправить memory management в FileFormatHandler
- FR-07: Пагинация в LibraryView при > 500 книг (fetchLimit + fetchOffset)
- FR-08: Lazy loading обложек через AsyncImage (уже реализовано, проверить)
- FR-09: Профилирование через Instruments: Time Profiler, Allocations, Leaks

## Non-Functional Requirements
- NFR-01: P95 < 300ms для LibraryView с 1000 книг
- NFR-02: P95 < 1s для открытия первой страницы
- NFR-03: Memory budget ридера: 50MB/страница, 3 страницы макс

## Boundaries (что НЕ входит)
- Не реализовывать новые функции
- Не оптимизировать сетевые запросы (отдельная задача)

## Acceptance Criteria
- [ ] LibraryView с 1000 книг загружается P95 < 300ms
- [ ] Открытие книги P95 < 1s для EPUB, PDF, FB2
- [ ] Memory usage ридера < 150MB
- [ ] Нет memory leaks (Instruments Leaks)
- [ ] Пагинация работает при > 500 книг

## Open Questions
- Нужна ли виртуализация списка для > 5000 книг?
- Как тестировать P95 воспроизводимо в CI?