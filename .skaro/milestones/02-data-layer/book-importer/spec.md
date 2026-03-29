# Specification: book-importer

## Context
Ключевой data flow: fileImporter → BookImporter.import(url:) → FileReferenceResolver.createBookmark → copy to Documents/Books/ → extractMetadata → Book(contentState: .downloaded). BookImporter — точка входа для всех локальных импортов.

## User Scenarios
1. **Пользователь выбирает файл через fileImporter:** BookImporter создаёт Book, копирует файл, извлекает базовые метаданные.
2. **Пользователь импортирует дублирующийся файл:** BookImporter обнаруживает дубликат по имени файла и предлагает заменить или пропустить.
3. **Импорт большого PDF:** Происходит асинхронно с прогрессом, UI не блокируется.

## Functional Requirements
- FR-01: BookImporter — actor
- FR-02: func importBook(from url: URL, context: ModelContext) async throws -> Book — основной метод
- FR-03: Шаги импорта: startAccessingSecurityScopedResource → определить формат → создать UUID → скопировать в Documents/Books/{uuid}/{filename} → createBookmark → extractBasicMetadata → создать Book → context.insert(book) → stopAccessing
- FR-04: func detectFormat(url: URL) -> BookFormat? — определение формата по расширению файла
- FR-05: func extractBasicMetadata(url: URL, format: BookFormat) async -> BookMetadata — извлечение title, author из имени файла как минимум
- FR-06: BookMetadata struct: title (String), author (String?), genre (String?), description (String?), seriesName (String?), seriesIndex (Int?)
- FR-07: Проверка дубликатов: если книга с таким же именем файла уже существует — throw VReaderError с кодом .fileSystem
- FR-08: При ошибке копирования — откат: удалить частично скопированный файл
- FR-09: Поддержка всех форматов из BookFormat enum
- FR-10: func importBooks(from urls: [URL], context: ModelContext) async throws -> [Book] — пакетный импорт
- FR-11: Прогресс через AsyncStream<ImportProgress> для UI
- FR-12: ImportProgress struct: current (Int), total (Int), currentFileName (String)

## Non-Functional Requirements
- NFR-01: Импорт одной книги < 2 секунды для файлов до 50MB
- NFR-02: Не блокировать main thread
- NFR-03: Атомарность: либо книга полностью импортирована, либо нет следов на диске

## Boundaries (что НЕ входит)
- Не запрашивать метаданные из Google Books/OpenLibrary (это MetadataFetcher)
- Не скачивать обложки из сети
- Не индексировать в Spotlight (это SpotlightIndexer)
- Не создавать коллекции (это CollectionManager)

## Acceptance Criteria
- [ ] BookImporter actor определён
- [ ] importBook() создаёт Book с contentState = .downloaded
- [ ] Файл копируется в Documents/Books/{uuid}/
- [ ] bookmarkData создаётся и сохраняется в Book
- [ ] Дубликаты обнаруживаются
- [ ] Откат при ошибке работает
- [ ] Пакетный импорт работает
- [ ] Прогресс через AsyncStream доступен

## Open Questions
- Нужно ли поддерживать импорт из Share Extension в этом milestone?
- Как обрабатывать зашифрованные PDF при импорте?