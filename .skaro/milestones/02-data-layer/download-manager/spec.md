# Specification: download-manager

## Context
ADR-006 определяет трёхуровневую модель состояния книги. DownloadManager управляет переходами между состояниями. Превью (10 страниц) хранятся в Documents/Previews/{bookID}/. Полные файлы в Documents/Books/{bookID}/. LRU-очистка при превышении 2GB.

## User Scenarios
1. **Пользователь нажимает "Читать" на cloudOnly книге:** DownloadManager.download(book:) запускает тихую фоновую загрузку с прогрессом на карточке.
2. **Книга появляется в облачном каталоге:** schedulePreview(book:) фоново скачивает 10 страниц.
3. **Хранилище превышает 2GB:** LRU-очистка удаляет превью наименее используемых книг.
4. **Загрузка завершена:** book.contentState = .downloaded, превью удаляются автоматически.

## Functional Requirements
- FR-01: DownloadManager — @Observable singleton (shared), actor для операций
- FR-02: func download(book: Book, context: ModelContext) async throws — полная загрузка. Обновляет contentState = .downloaded по завершении
- FR-03: func schedulePreview(book: Book, context: ModelContext) async — фоновая загрузка превью. Приоритет ниже интерактивных загрузок
- FR-04: func cancelDownload(bookID: UUID) — отмена активной загрузки
- FR-05: func deleteLocalCopy(book: Book, context: ModelContext) async throws — удаление локальной копии, contentState = .cloudOnly
- FR-06: var activeDownloads: [UUID: DownloadProgress] — словарь активных загрузок для UI
- FR-07: DownloadProgress struct: bookID (UUID), progress (Double 0-1), bytesDownloaded (Int64), totalBytes (Int64), state (DownloadState)
- FR-08: DownloadState enum: queued, downloading, paused, completed, failed
- FR-09: При переходе .previewed → .downloaded: удалить Documents/Previews/{bookID}/ автоматически
- FR-10: LRU-очистка: при превышении порога (дефолт 2GB) удалять превью книг с наиболее старым lastOpenedAt
- FR-11: func storageUsed() async -> Int64 — текущее использование хранилища
- FR-12: Только при наличии сети (NetworkMonitor.isOnline). При оффлайн — добавить в очередь
- FR-13: Не загружать превью при isExpensive == true (cellular) без явного разрешения пользователя
- FR-14: Создать DownloadRecord в SwiftData при каждой загрузке

## Non-Functional Requirements
- NFR-01: Максимум 3 одновременных загрузки
- NFR-02: Превью загружаются с приоритетом ниже полных загрузок
- NFR-03: Возобновление загрузки после прерывания (URLSession background)

## Boundaries (что НЕ входит)
- Не реализовывать конкретные облачные провайдеры (это CloudProvider реализации)
- Не парсить содержимое скачанных файлов
- Не управлять обложками

## Acceptance Criteria
- [ ] DownloadManager.shared существует
- [ ] download() обновляет contentState = .downloaded
- [ ] schedulePreview() создаёт файлы в Documents/Previews/{bookID}/
- [ ] При переходе previewed→downloaded превью удаляются
- [ ] activeDownloads обновляется в реальном времени
- [ ] LRU-очистка срабатывает при превышении 2GB
- [ ] Не загружает при isOnline == false

## Open Questions
- Использовать ли URLSession background configuration для загрузок?
- Как определять "10 страниц" для превью разных форматов (PDF vs EPUB vs CBZ)?