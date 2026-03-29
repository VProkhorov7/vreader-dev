# Specification: reader-view

## Context
ReaderView — основной контейнер ридера. Содержит ReaderTopBar и ReaderBottomBar с frosted glass эффектом. Панели автоматически скрываются при чтении. Включает боковые панели: TOC, Notes, Settings. Offline banner показывается если нет сети.

## User Scenarios
1. **Пользователь читает:** Панели скрыты, только текст. Тап → панели появляются на 3 секунды.
2. **Пользователь открывает оглавление:** Тап на TOC кнопку → боковая панель с главами.
3. **Нет сети:** Offline banner в ReaderTopBar.

## Functional Requirements
- FR-01: ZStack: контент ридера + overlay панели
- FR-02: ReaderTopBar: frosted glass (surface 85% + blur 20px), название книги, кнопки: закрыть, TOC, Notes, Settings. Offline banner если NetworkMonitor.isOnline == false
- FR-03: ReaderBottomBar: frosted glass, прогресс slider, номер страницы, кнопки: предыдущая глава, следующая глава
- FR-04: Auto-hide: панели скрываются через 3 секунды после последнего взаимодействия
- FR-05: Тап на контент: toggle видимости панелей
- FR-06: TOCPanel: список глав, тап → переход к главе
- FR-07: NotesPanel: список аннотаций текущей книги
- FR-08: ReaderSettingsPanel: тема, шрифт, размер, интервал — применяются через ReaderState.displaySettings
- FR-09: Определение формата книги → выбор правильного handler (TextReaderView для EPUB/FB2/TXT, PDFReaderView для PDF)
- FR-10: Сохранение позиции при закрытии ридера
- FR-11: Поддержка landscape orientation
- FR-12: Все строки через L10n.Reader.*

## Non-Functional Requirements
- NFR-01: Анимация появления/скрытия панелей 0.25s (DesignTokens.Animation.normal)
- NFR-02: Frosted glass не должен влиять на производительность scroll

## Boundaries (что НЕ входит)
- Не реализовывать TranslationPanel (milestone 06)
- Не реализовывать TTS в ридере (milestone 03-audio)
- Не реализовывать синхронизацию позиции через CloudKit

## Acceptance Criteria
- [ ] ReaderTopBar и ReaderBottomBar с frosted glass
- [ ] Auto-hide через 3 секунды работает
- [ ] TOCPanel открывается и навигация работает
- [ ] NotesPanel показывает аннотации
- [ ] ReaderSettingsPanel применяет настройки
- [ ] Offline banner показывается при отсутствии сети
- [ ] Позиция сохраняется при закрытии

## Open Questions
- Нужна ли поддержка split view на iPad (ридер + заметки рядом)?
- Как обрабатывать переход между главами при достижении конца страницы?