# Specification: diagnostics-view

## Context
DiagnosticsView доступна в Settings. В Debug режиме — полный доступ к логам с фильтрацией. В Release — только кнопка экспорта последних 100 записей через share sheet. Помогает пользователям сообщать о проблемах.

## User Scenarios
1. **Разработчик в Debug режиме:** Видит все логи с фильтрацией по категории и уровню.
2. **Пользователь сообщает о баге:** Нажимает "Экспортировать диагностику" → share sheet с текстовым файлом.
3. **Фильтрация логов:** Разработчик фильтрует только .error уровень для категории .cloud.

## Functional Requirements
- FR-01: DiagnosticsView — условная компиляция: #if DEBUG полный вид, иначе только экспорт
- FR-02: Debug вид: List логов с фильтрами по LogCategory и уровню
- FR-03: Каждая запись: timestamp, уровень (цветной badge), категория, сообщение
- FR-04: Фильтр по категории: Picker с LogCategory
- FR-05: Фильтр по уровню: Picker (debug, info, warning, error, fault)
- FR-06: Поиск по тексту сообщения
- FR-07: Кнопка "Очистить логи"
- FR-08: Release вид: только кнопка "Экспортировать диагностику" → DiagnosticsService.exportLogs() → ShareSheet
- FR-09: Экспортируемый файл: vreader-diagnostics-{date}.txt
- FR-10: Все строки через L10n.Settings.*

## Non-Functional Requirements
- NFR-01: List логов не лагает при 100 записях
- NFR-02: Экспорт < 500ms

## Boundaries (что НЕ входит)
- Не отправлять логи автоматически на сервер
- Не включать PII в экспортируемые логи

## Acceptance Criteria
- [ ] Debug вид показывает все логи
- [ ] Фильтры по категории и уровню работают
- [ ] Release вид показывает только кнопку экспорта
- [ ] Экспорт через share sheet работает
- [ ] Нет PII в экспортируемых логах
- [ ] Все строки через L10n

## Open Questions
- Нужна ли возможность отправки логов напрямую разработчику (email)?
- Как обрабатывать очень длинные сообщения в List (truncation vs expand)?