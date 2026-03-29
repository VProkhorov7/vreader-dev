# Specification: swiftdata-models

## Context
ADR-001 определяет SwiftData как единственное локальное хранилище. Все модели должны иметь VersionedSchema с первого релиза. Инвариант #6 запрещает coverData в Book. Инвариант #7 требует lamportClock в Annotation. Существующие Book.swift и другие модели нужно привести в соответствие.

## User Scenarios
1. **Пользователь импортирует книгу:** Book создаётся в SwiftData с bookmarkData, coverPath, contentState.
2. **Пользователь добавляет аннотацию:** Annotation создаётся с lamportClock=1, deviceID.
3. **Приложение обновляется:** SchemaMigrationPlan выполняет миграцию без потери данных.

## Functional Requirements
- FR-01: Book @Model: id (UUID), title (String), author (String), coverPath (String), filePath (String), bookmarkData (Data?), format (BookFormat), fileSize (Int64), source (ContentSource), addedAt (Date), progress (Double), lastPage (Int), lastOpenedAt (Date?), isFinished (Bool), tags ([String]), genre (String?), description (String?), seriesName (String?), seriesIndex (Int?), collectionID (UUID?), contentState (BookContentState), isLocalCopy (Bool), previewPagesPath (String?)
- FR-02: BookFormat enum: epub, fb2, fb2zip, pdf, cbz, cbr, cbt, cb7, mobi, azw3, djvu, txt, rtf, chm, mp3, m4a, m4b, aac
- FR-03: BookContentState enum: cloudOnly, previewed, downloaded
- FR-04: Annotation @Model: id (UUID), bookID (UUID), chapter (Int), text (String), comment (String?), type (AnnotationType), color (String), date (Date), lamportClock (Int), deviceID (String)
- FR-05: AnnotationType enum: bookmark, highlight, note
- FR-06: Collection @Model: id (UUID), name (String), sourcePath (String?), isAutomatic (Bool), sortOrder (Int), status (CollectionStatus)
- FR-07: CollectionStatus enum: active, orphaned
- FR-08: ReadingStatsRecord @Model: id (UUID), bookID (UUID), startedAt (Date), endedAt (Date?), pagesRead (Int), wordsRead (Int)
- FR-09: DownloadRecord @Model: id (UUID), bookID (UUID), providerID (String), remoteURL (String), downloadedAt (Date), localPath (String), fileSize (Int64), contentState (BookContentState)
- FR-10: PendingChangesQueue @Model: id (UUID), recordType (String), recordID (String), operation (PendingOperation), payload (Data), createdAt (Date)
- FR-11: PendingOperation enum: insert, update, delete
- FR-12: Определить SchemaV1 как VersionedSchema содержащий все модели
- FR-13: Определить VReaderMigrationPlan: SchemaMigrationPlan с MigrationStage.lightweight(from: SchemaV1, to: SchemaV1) как начальный план
- FR-14: Настроить ModelContainer в VreaderApp с VReaderMigrationPlan
- FR-15: coverData: Data ЗАПРЕЩЁН в Book — проверяется check_refs.py

## Non-Functional Requirements
- NFR-01: Все модели Sendable где возможно
- NFR-02: Индексы на часто запрашиваемых полях: Book.addedAt, Book.lastOpenedAt, Book.contentState
- NFR-03: ModelContainer инициализируется асинхронно чтобы не блокировать запуск

## Boundaries (что НЕ входит)
- Не реализовывать CloudKit синхронизацию моделей
- Не реализовывать бизнес-логику в моделях
- Не добавлять computed properties зависящие от файловой системы

## Acceptance Criteria
- [ ] Все 6 моделей определены и компилируются
- [ ] BookFormat содержит все 18 форматов
- [ ] Book не содержит поле coverData
- [ ] Annotation содержит lamportClock и deviceID
- [ ] SchemaV1 и VReaderMigrationPlan определены
- [ ] ModelContainer настроен в VreaderApp
- [ ] check_refs.py не находит coverData в SwiftData моделях

## Open Questions
- Нужны ли @Relationship между Book и Annotation или только bookID как foreign key?
- Как обрабатывать BookFormat для неизвестных расширений файлов?