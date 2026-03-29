# Specification: metadata-editor-view

## Context
MetadataEditorView позволяет пользователю вручную редактировать метаданные книги. После редактирования MetadataFetcher не перезаписывает изменения (флаг isManuallyEdited). SpotlightIndexer обновляет индекс.

## User Scenarios
1. **Пользователь редактирует название книги:** Открывает MetadataEditorView, меняет title, сохраняет.
2. **Пользователь добавляет теги:** Добавляет теги через chip input.
3. **Пользователь меняет обложку:** Выбирает изображение из Photos или файловой системы.

## Functional Requirements
- FR-01: Sheet presentation
- FR-02: Поля: title (TextField), author (TextField), genre (Picker или TextField), seriesName (TextField), seriesIndex (Stepper), tags (chip input), description (TextEditor)
- FR-03: Кнопка "Обновить метаданные из сети" → MetadataFetcher.fetchMetadata()
- FR-04: Смена обложки: PhotosPicker или fileImporter для изображений
- FR-05: Сохранение через ModelContext
- FR-06: После сохранения: SpotlightIndexer.index(book:) для обновления индекса
- FR-07: Установка book.isManuallyEdited = true после ручного редактирования
- FR-08: Валидация: title не может быть пустым
- FR-09: Все строки через L10n

## Non-Functional Requirements
- NFR-01: Сохранение < 200ms
- NFR-02: Изображение обложки сжимается до < 500KB

## Boundaries (что НЕ входит)
- Не реализовывать bulk редактирование нескольких книг
- Не реализовывать автодополнение жанров из базы данных

## Acceptance Criteria
- [ ] MetadataEditorView открывается как sheet
- [ ] Все поля редактируются и сохраняются
- [ ] Смена обложки работает
- [ ] isManuallyEdited устанавливается
- [ ] Spotlight обновляется после сохранения
- [ ] Валидация title работает

## Open Questions
- Нужна ли поддержка множественных авторов?
- Как обрабатывать специальные символы в тегах?