# Specification: settings-view

## Context
Настройки приложения: тема, шрифт, облачные коннекторы, управление хранилищем, диагностика. Существующий `SettingsView.swift` требует ревизии.

## User Scenarios
1. **Пользователь меняет тему:** Выбирает из доступных тем, Premium темы показывают lock icon.
2. **Пользователь подключает Dropbox:** Переходит в CloudConnectorView, авторизуется.
3. **Пользователь экспортирует логи:** Нажимает 'Поделиться логами' → share sheet.

## Functional Requirements
- FR-01: `SettingsView` — SwiftUI View с `List` секциями.
- FR-02: Секция 'Внешний вид': выбор темы (ThemePickerView), размер шрифта, межстрочный интервал.
- FR-03: `ThemePickerView` — горизонтальный скролл с превью тем. Premium темы с lock icon.
- FR-04: Секция 'Облако': список подключённых провайдеров, кнопка добавить.
- FR-05: Секция 'Хранилище': использованное место, список загруженных книг, кнопка 'Очистить кэш'.
- FR-06: Секция 'Premium': статус подписки, кнопка 'Управление подпиской'.
- FR-07: Секция 'Диагностика': `DiagnosticsView` (в Debug — полные логи, в Release — кнопка экспорта).
- FR-08: `DiagnosticsView` — список последних 100 `LogEntry` с фильтром по уровню и категории.
- FR-09: Кнопка 'Поделиться логами' → `DiagnosticsService.exportLogs()` → `ShareLink`.
- FR-10: Все строки через `L10n.*`.
- FR-11: Тема через `@Environment(\.appTheme)`.
- FR-12: Настройки сохраняются в `iCloudSettingsStore`.

## Non-Functional Requirements
- NFR-01: Открытие SettingsView < 200ms.

## Boundaries (что НЕ входит)
- Не реализовывать CloudConnectorView детально — только placeholder.
- Не реализовывать StoreKit paywall.

## Acceptance Criteria
- [ ] Смена темы применяется мгновенно.
- [ ] Premium темы заблокированы для Free пользователей.
- [ ] DiagnosticsView отображает логи.
- [ ] Экспорт логов работает через share sheet.
- [ ] Настройки сохраняются между сессиями.

## Open Questions
- Нужна ли секция 'О приложении' с версией и ссылкой на Privacy Policy?
- Как отображать статус синхронизации CloudKit в настройках?