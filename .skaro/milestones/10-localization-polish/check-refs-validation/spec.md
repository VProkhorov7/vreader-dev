# Specification: check-refs-validation

## Context
check_refs.py — обязательный validation gate перед каждым merge. Проверяет: дублирование типов, неразрешённые ссылки, iOS 17+ совместимость, структурную целостность, использование L10n, UTType optional binding, отсутствие force-unwrap UTType.

## User Scenarios
1. **Разработчик делает PR:** check_refs.py запускается автоматически, находит дублирующийся тип → PR блокируется.
2. **Разработчик добавляет хардкод строку:** check_refs.py находит нарушение L10n инварианта.
3. **Разработчик использует force-unwrap UTType:** check_refs.py находит нарушение security инварианта.

## Functional Requirements
- FR-01: Проверка дублирования типов: один и тот же `struct`/`class`/`enum` в нескольких файлах.
- FR-02: Проверка неразрешённых ссылок: использование типов, не определённых в проекте.
- FR-03: Проверка iOS 17+ совместимости: использование API доступных только в iOS 18+.
- FR-04: Проверка L10n: хардкод строки в UI файлах (паттерн: `Text("...")`  без L10n).
- FR-05: Проверка UTType: `UTType(...)!` force-unwrap запрещён.
- FR-06: Проверка credentials: паттерны `password`, `token`, `apiKey` в логах и UserDefaults.
- FR-07: Проверка `coverData`: использование `coverData: Data` в SwiftData моделях запрещено.
- FR-08: Проверка CloudKit isPremium: синхронизация isPremium через CloudKit запрещена.
- FR-09: Отчёт: список нарушений с файлом, строкой и описанием.
- FR-10: Exit code 0 при успехе, 1 при нарушениях.
- FR-11: Поддержка `--fix` флага для автоматического исправления простых нарушений.

## Non-Functional Requirements
- NFR-01: Проверка всего проекта < 30s.
- NFR-02: Нет false positives для корректного кода.

## Boundaries (что НЕ входит)
- Не заменять Xcode build — только статический анализ.
- Не проверять runtime поведение.

## Acceptance Criteria
- [ ] Все 8 проверок реализованы.
- [ ] Exit code корректен.
- [ ] Нет false positives на корректном коде.
- [ ] Отчёт содержит файл и строку нарушения.
- [ ] Проверка < 30s для всего проекта.

## Open Questions
- Интегрировать check_refs.py в Xcode build phase или только в CI?
- Нужна ли поддержка `.skaroignore` для исключения файлов из проверки?