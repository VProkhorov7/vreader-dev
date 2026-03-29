# Specification: mobi-azw3-handler

## Context
MOBI и AZW3 — форматы Amazon Kindle. Требуется открытая реализация парсера (без DRM). MOBIHandler и AZW3Handler реализуют FileFormatHandler и интегрируются с TextReaderView.

## User Scenarios
1. **Пользователь открывает MOBI файл без DRM:** MOBIHandler парсирует файл, показывает текст.
2. **Открытие AZW3:** AZW3Handler обрабатывает KF8 формат.

## Functional Requirements
- FR-01: MOBIHandler реализует FileFormatHandler
- FR-02: AZW3Handler реализует FileFormatHandler (KF8 формат)
- FR-03: Парсинг PalmDB структуры для MOBI
- FR-04: Извлечение HTML контента
- FR-05: Извлечение метаданных (title, author, cover)
- FR-06: Только файлы без DRM (DRM файлы → понятная ошибка пользователю)
- FR-07: Интеграция с TextReaderView
- FR-08: Ошибки через VReaderError

## Non-Functional Requirements
- NFR-01: Открытие первой страницы < 1 секунда

## Boundaries (что НЕ входит)
- Не реализовывать DRM расшифровку
- Не реализовывать конвертацию в другие форматы

## Acceptance Criteria
- [ ] MOBIHandler и AZW3Handler реализованы
- [ ] Текст извлекается корректно
- [ ] DRM файлы возвращают понятную ошибку
- [ ] Метаданные и обложка извлекаются

## Open Questions
- Какую открытую библиотеку использовать для MOBI парсинга?
- Как обрабатывать MOBI файлы с встроенными изображениями?