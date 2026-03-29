# Specification: text-reader-view

## Context
Основной ридер для текстовых форматов. Отображает HTML/текст через WKWebView или SwiftUI Text. Поддержка RTL, выделения текста, создания аннотаций. Существующий `TextReaderView.swift` требует ревизии.

## User Scenarios
1. **Пользователь читает EPUB:** Текст отображается с настройками темы (шрифт, размер, межстрочный интервал).
2. **Пользователь выделяет текст:** Появляется меню: Выделить, Заметка, Перевести, Словарь.
3. **Пользователь читает арабскую книгу:** RTL layout применяется автоматически.

## Functional Requirements
- FR-01: `TextReaderView` — SwiftUI View, принимает `book: Book`, `handler: any FileFormatHandler`.
- FR-02: Отображение HTML контента через `WKWebView` (для EPUB/FB2) или `Text` (для TXT).
- FR-03: Применение темы к WKWebView через CSS injection: цвет фона, цвет текста, шрифт, размер, межстрочный интервал.
- FR-04: Пагинация: горизонтальный scroll по страницам или вертикальный scroll (настройка пользователя).
- FR-05: Выделение текста: `UIMenuController` или `contextMenu` с пунктами: Выделить (highlight), Заметка, Перевести, Словарь, Копировать.
- FR-06: Создание `Annotation` при выделении через `LibraryModelActor`.
- FR-07: Отображение существующих аннотаций (highlights) в тексте.
- FR-08: RTL поддержка: `layoutDirection` из `book.language` или системного языка.
- FR-09: `ReaderSettingsPanel` — sheet: тема, шрифт, размер (12-32pt), межстрочный интервал, горизонтальный/вертикальный scroll.
- FR-10: Настройки применяются мгновенно без перезагрузки страницы.
- FR-11: Предзагрузка следующей страницы в фоне.

## Non-Functional Requirements
- NFR-01: Смена шрифта/размера < 100ms.
- NFR-02: Scroll 60fps.

## Boundaries (что НЕ входит)
- Не реализовывать AI перевод — только callback для открытия TranslationPanel.
- Не реализовывать TTS в TextReaderView — это TTSService.

## Acceptance Criteria
- [ ] EPUB и FB2 отображаются с правильным форматированием.
- [ ] Тема применяется через CSS injection.
- [ ] Выделение текста создаёт аннотацию.
- [ ] RTL текст отображается корректно.
- [ ] ReaderSettingsPanel работает.
- [ ] Существующий TextReaderView.swift обновлён.

## Open Questions
- WKWebView или нативный SwiftUI для отображения HTML?
- Как синхронизировать позицию скролла между WKWebView и SwiftUI?