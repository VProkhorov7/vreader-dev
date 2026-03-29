# Specification: opds-catalogs

## Context
OPDS (Open Publication Distribution System) — стандарт для каталогов электронных книг. Позволяет подключать публичные библиотеки (Project Gutenberg, Flibusta, Manybooks). Существующие `CatalogsView.swift`, `CatalogModels.swift`, `OnlineView.swift` требуют ревизии.

## User Scenarios
1. **Пользователь добавляет OPDS каталог:** Вводит URL → приложение парсит OPDS feed.
2. **Пользователь просматривает Project Gutenberg:** Видит список книг с обложками и описаниями.
3. **Пользователь скачивает книгу из каталога:** Файл загружается через DownloadManager.

## Functional Requirements
- FR-01: `OPDSProvider` — final class, реализует `CloudProviderProtocol` (адаптер).
- FR-02: Парсинг OPDS Atom feed (XML).
- FR-03: `CatalogModels`: `OPDSCatalog`, `OPDSEntry`, `OPDSLink`.
- FR-04: `CatalogsView` — список добавленных каталогов + встроенные (Gutenberg, Manybooks).
- FR-05: `OnlineView` — просмотр каталога: список книг, поиск, навигация по категориям.
- FR-06: Загрузка книги из каталога через `DownloadManager`.
- FR-07: Поддержка OPDS 1.2 и 2.0.
- FR-08: Кэширование feed на 1 час.
- FR-09: Все строки через `L10n.*`.

## Non-Functional Requirements
- NFR-01: Загрузка каталога < 3s.

## Boundaries (что НЕ входит)
- Не реализовывать авторизацию для приватных OPDS каталогов (milestone 10 advanced).
- Не реализовывать OPDS поиск для всех каталогов одновременно.

## Acceptance Criteria
- [ ] OPDS feed парсируется корректно.
- [ ] Книги из каталога загружаются.
- [ ] Встроенные каталоги (Gutenberg) работают.
- [ ] Существующие файлы обновлены.

## Open Questions
- Как обрабатывать OPDS каталоги с авторизацией (Basic Auth)?
- Нужна ли поддержка OPDS search facets?