# Development Plan

_Generated: 2026-03-29_
_Updated: 2026-06-10_

## Фундамент: структура проекта и дизайн-система
_Directory: `milestones/01-foundation/`_

| # | Task | Status | Dependencies | Description |
|---|------|--------|--------------|-------------|
| 1 | check-refs-validation | planned | — | Настройка и запуск check_refs.py с первого дня разработки: валидация дублирования типов, неразрешённых ссылок, iOS 17+ совместимости, структурной целостности Swift-файлов, запрета force-unwrap UTType, проверки L10n покрытия. Обязателен перед каждым merge. |
| 2 | project-structure-cleanup | planned | check-refs-validation | Очистка существующей структуры проекта: удаление дублирующихся файлов (Core/ vs App/Vreader/Vreader/), Untitled.swift, настройка правильной иерархии папок и entitlements. |
| 3 | design-tokens | planned | project-structure-cleanup | Создание DesignTokens.swift — единственного источника всех дизайн-значений: цвета, шрифты, отступы, радиусы, анимации, memory budget. |
| 4 | app-theme-system | planned | design-tokens | Реализация AppTheme protocol, четырёх тем (EditorialDark, CuratorLight, NeuralLink, Typewriter) и Environment key для передачи темы через иерархию вью. |
| 5 | error-code-system | planned | project-structure-cleanup | Создание типизированной системы ошибок ErrorCode с категориями, описаниями и recovery hints согласно архитектурному инварианту #19. |
| 6 | keychain-manager | planned | error-code-system | Реализация KeychainManager для безопасного хранения credentials: WebDAV пароли, OAuth токены, Gemini API ключ. |
| 7 | l10n-foundation | planned | project-structure-cleanup | Настройка системы локализации L10n: структура ключей, RU и EN строки для всех существующих UI-компонентов, валидация через check_refs.py. |
| 8 | network-monitor | planned | error-code-system | Реализация NetworkMonitor на основе NWPathMonitor для отслеживания состояния сети и предоставления @Published isOnline всем сервисам. |
| 9 | icloud-settings-store | planned | keychain-manager, error-code-system | Реализация iCloudSettingsStore для хранения настроек приложения и кэша isPremium с TTL через NSUbiquitousKeyValueStore. |
| 10 | diagnostics-service | planned | error-code-system | Реализация DiagnosticsService на основе OSLog с уровнями логирования, защитой от PII и экспортом логов для DiagnosticsView. |

## Слой данных: SwiftData модели и файловая система
_Directory: `milestones/02-data-layer/`_

| # | Task | Status | Dependencies | Description |
|---|------|--------|--------------|-------------|
| 1 | swiftdata-models | planned | error-code-system | Реализация всех SwiftData моделей (Book, Annotation, Collection, ReadingStatsRecord, DownloadRecord, PendingChangesQueue) с VersionedSchema и SchemaMigrationPlan. |
| 2 | model-actor-context | planned | swiftdata-models | Реализация @ModelActor контекста для фоновых SwiftData операций согласно архитектурному инварианту о thread safety. |
| 3 | file-reference-resolver | planned | swiftdata-models, error-code-system | Реализация FileReferenceResolver для разрешения файловых ссылок через bookmarkData, восстановления broken paths и управления security-scoped bookmarks. |
| 4 | book-importer | planned | file-reference-resolver, model-actor-context | Реализация BookImporter для импорта файлов из Files.app и Share Sheet: создание bookmarkData, копирование в Documents/Books/, извлечение базовых метаданных. |
| 5 | cover-fetcher | planned | book-importer | Реализация CoverFetcher для извлечения обложек из файлов книг и сохранения в Documents/Covers/{bookID}.jpg. |
| 6 | metadata-fetcher | planned | cover-fetcher, keychain-manager | Реализация MetadataFetcher для автоматического получения метаданных книг из Google Books API и OpenLibrary API с fallback цепочкой. |
| 7 | download-manager | planned | file-reference-resolver, model-actor-context | Реализация DownloadManager для управления загрузками книг из облака: три состояния контента, превью (10 страниц), полные файлы, LRU-очистка. |
| 8 | collection-manager | planned | swiftdata-models, model-actor-context | Реализация CollectionManager для автоматического создания коллекций из структуры папок облачных провайдеров и управления статусом orphaned. |
| 9 | spotlight-indexer | planned | swiftdata-models | Реализация SpotlightIndexer для индексации книг в CoreSpotlight и поддержки deep link vreader://open?bookID=. |

## Обработчики форматов файлов
_Directory: `milestones/03-format-handlers/`_

| # | Task | Status | Dependencies | Description |
|---|------|--------|--------------|-------------|
| 1 | file-format-handler-protocol | planned | error-code-system, design-tokens | Определение FileFormatHandler protocol и базовой инфраструктуры для всех обработчиков форматов с поддержкой lazy loading и memory budget. |
| 2 | epub-handler | planned | file-format-handler-protocol | Нативный EPUB обработчик: парсинг ZIP + OPF + HTML/CSS, извлечение метаданных, обложки, поддержка EPUB 2 и EPUB 3. |
| 3 | fb2-handler | planned | file-format-handler-protocol | Нативный FB2/FB2.ZIP обработчик: XML парсинг, извлечение метаданных, обложки, поддержка кириллицы и base64 изображений. |
| 4 | pdf-handler | planned | file-format-handler-protocol | PDF обработчик на основе PDFKit с поддержкой аннотаций, поиска и извлечения метаданных. |
| 5 | comic-handlers | planned | file-format-handler-protocol | Обработчики для комикс-форматов CBZ (ZIP), CBR (RAR), CBT (TAR), CB7 (7-Zip) с поддержкой сортировки страниц и guided view. |
| 6 | text-handlers | planned | file-format-handler-protocol | Обработчики для текстовых форматов TXT и RTF с поддержкой кодировок, разбивкой на страницы и базовым форматированием. |
| 7 | mobi-azw3-handler | planned | file-format-handler-protocol | Обработчик для форматов MOBI и AZW3 (Kindle) через открытую реализацию парсера. |
| 8 | djvu-handler | planned | file-format-handler-protocol | Обработчик для формата DJVU через libdjvu (C-библиотека через Swift bridging header). Поддержка постраничного рендеринга, извлечения метаданных и оглавления. Lazy loading обязателен — файлы DJVU могут быть очень большими. |
| 9 | chm-handler | planned | file-format-handler-protocol | Обработчик для формата CHM (Microsoft Compiled HTML Help) через libchm (C-библиотека через Swift bridging header). Парсинг оглавления, извлечение HTML-страниц, поддержка внутренних ссылок. |
| 10 | audio-handler | planned | file-format-handler-protocol | Обработчик для аудио форматов MP3, M4A, M4B, AAC через AVFoundation с поддержкой глав и метаданных. |

## Основной UI: навигация, библиотека и карточки книг
_Directory: `milestones/04-ui-core/`_

| # | Task | Status | Dependencies | Description |
|---|------|--------|--------------|-------------|
| 1 | navigation-state | planned | swiftdata-models, app-theme-system | Реализация NavigationState, LibraryState, PlayerState, ReaderState как @Observable классов и настройка URL scheme обработчиков. |
| 2 | main-tab-view | planned | navigation-state, l10n-foundation | Реализация MainTabView с TabView навигацией, интеграцией всех state объектов и обработкой URL schemes. |
| 3 | book-card-view | planned | main-tab-view, swiftdata-models | Реализация BookCardView с отображением обложки, прогресса, badges для contentState/format/source и поддержкой контекстного меню. |
| 4 | library-view | planned | book-card-view | Реализация LibraryView с сеткой книг, поиском, фильтрами по жанрам, вкладками Library/Favorites/Collections и пагинацией. |
| 5 | book-detail-view | planned | book-card-view | Реализация BookDetailView с полной информацией о книге, кнопками действий и MetadataEditorView. |
| 6 | settings-view | planned | main-tab-view, icloud-settings-store | Реализация SettingsView с настройками темы, шрифта, облачных коннекторов, управления локальными копиями и DiagnosticsView. |

## Ядро ридера: чтение, аудио и TTS
_Directory: `milestones/05-reader-core/`_

| # | Task | Status | Dependencies | Description |
|---|------|--------|--------------|-------------|
| 1 | reader-view-container | planned | navigation-state, file-format-handler-protocol | Реализация ReaderView — основного контейнера ридера с auto-hide controls, жестами навигации и маршрутизацией к специализированным ридерам. |
| 2 | text-reader-view | planned | reader-view-container, epub-handler, fb2-handler, text-handlers | Реализация TextReaderView для EPUB, FB2, TXT с поддержкой RTL, выделения текста, аннотаций и настроек отображения. |
| 3 | comic-reader-view | planned | reader-view-container, comic-handlers | Реализация ComicReaderView для CBZ/CBR форматов с zoom, guided view и поддержкой RTL (манга). |
| 4 | audio-player-view | planned | reader-view-container, audio-handler | Реализация AudioPlayerView с управлением воспроизведением, главами, скоростью и интеграцией с Control Center. |
| 5 | tts-service | planned | audio-handler, network-monitor, keychain-manager | Реализация TTSService с цепочкой провайдеров: Gemini TTS (Premium), AVSpeechSynthesizer Neural (Premium fallback), AVSpeechSynthesizer стандартный (Free). |
| 6 | reading-state-manager | planned | swiftdata-models, icloud-settings-store | Реализация ReadingStateManager для сохранения и восстановления позиции чтения через NSUbiquitousKeyValueStore. |
| 7 | notes-toc-panels | planned | text-reader-view | Реализация NotesPanel (закладки, хайлайты, заметки) и TOCPanel (оглавление) для ридера. |

## Облачный слой: провайдеры и синхронизация
_Directory: `milestones/06-cloud-layer/`_

| # | Task | Status | Dependencies | Description |
|---|------|--------|--------------|-------------|
| 1 | cloud-provider-protocol | planned | error-code-system, network-monitor, diagnostics-service | Определение CloudProviderProtocol, CloudProviderManager, CloudProviderHealthMonitor с circuit breaker и базовой инфраструктурой. |
| 2 | icloud-provider | planned | cloud-provider-protocol | Реализация ICloudProvider через NSMetadataQuery для работы с iCloud Drive. |
| 3 | webdav-providers | planned | cloud-provider-protocol, keychain-manager | Реализация WebDAVProvider и специализированных провайдеров: YandexDisk, Nextcloud, MailRu с Basic Auth через Keychain. |
| 4 | oauth-providers | planned | cloud-provider-protocol, keychain-manager | Реализация OAuthManager и OAuth2 провайдеров: Google Drive, Dropbox, OneDrive через ASWebAuthenticationSession с PKCE. |
| 5 | smb-provider | planned | cloud-provider-protocol, keychain-manager | Реализация SMBProvider через AMSMB2 с поддержкой SMB2/SMB3 и SMB1 legacy fallback для старых NAS. |
| 6 | cloud-file-browser | planned | icloud-provider, webdav-providers, oauth-providers | Реализация CloudFileBrowserView и CloudStorageView для просмотра файлов облачных провайдеров и управления подключениями. |
| 7 | cloudkit-sync | planned | swiftdata-models, model-actor-context, network-monitor | Реализация CloudKit синхронизации аннотаций и прогресса, ConflictResolver, BackgroundSyncTask и PendingChangesQueue обработки. |

## AI функции: Gemini интеграция
_Directory: `milestones/07-ai-features/`_

| # | Task | Status | Dependencies | Description |
|---|------|--------|--------------|-------------|
| 1 | gemini-service-core | planned | keychain-manager, network-monitor, error-code-system | Реализация GeminiService — единой точки входа для Gemini API с AIRequestQueue, RateLimiter, QuotaTracker и circuit breaker. |
| 2 | translation-service | planned | gemini-service-core | Реализация TranslationService для перевода текста через Gemini с лимитами Free/Premium и TranslationPanel UI. |
| 3 | summary-xray-dictionary | planned | gemini-service-core | Реализация SummaryService, XRayService и DictionaryService — Premium-only AI функции через Gemini. |
| 4 | gemini-tts-provider | planned | gemini-service-core, tts-service | Реализация GeminiTTSProvider для синтеза речи через Gemini TTS API с интеграцией в TTSService. |

## Монетизация: StoreKit 2 и Premium
_Directory: `milestones/08-monetization/`_

| # | Task | Status | Dependencies | Description |
|---|------|--------|--------------|-------------|
| 1 | storekit-manager | planned | error-code-system, diagnostics-service | Реализация StoreKitManager для покупок, восстановления и верификации через Transaction.currentEntitlements на каждом старте. |
| 2 | premium-state-validator | planned | storekit-manager, icloud-settings-store | Реализация PremiumStateValidator и PremiumGate — единственных компонентов для определения isPremium и проверки лимитов. |
| 3 | premium-paywall-view | planned | premium-state-validator, app-theme-system | Реализация PremiumPaywallView с отображением продуктов, функций Premium и обработкой покупки через StoreKit 2. |

## Widget Extension и Spotlight
_Directory: `milestones/09-widget/`_

| # | Task | Status | Dependencies | Description |
|---|------|--------|--------------|-------------|
| 1 | widget-extension | planned | swiftdata-models, navigation-state | Реализация VReaderWidget WidgetKit extension с Timeline provider, App Group shared container и deep link на открытие книги. |

## Локализация и полировка
_Directory: `milestones/10-localization-polish/`_

| # | Task | Status | Dependencies | Description |
|---|------|--------|--------------|-------------|
| 1 | full-localization | planned | l10n-foundation | Полное покрытие всех строк RU и EN, добавление AR с RTL layout и ZH с CJK шрифтами. |
| 2 | accessibility-polish | planned | full-localization | Полная поддержка VoiceOver, Dynamic Type и accessibility для всех UI компонентов. |

## Продвинутые функции: статистика, автоскролл, OPDS
_Directory: `milestones/11-advanced-features/`_

| # | Task | Status | Dependencies | Description |
|---|------|--------|--------------|-------------|
| 1 | reading-stats | planned | reading-state-manager | Реализация экрана статистики чтения: время чтения, страницы, слова, графики прогресса. |
| 2 | opds-catalogs | planned | cloud-provider-protocol, book-importer | Реализация OPDS каталогов для просмотра и загрузки книг из публичных библиотек (Project Gutenberg, Flibusta и др.). Базовый UI (OnlineView) уже существует в коде как заглушка — реализация наполняет его реальной функциональностью: OPDS-парсер, листинг каталогов, поиск, загрузка книг. |
| 3 | auto-scroll | planned | text-reader-view | Реализация автоскролла для TextReaderView с настройкой скорости и паузой при взаимодействии. |
| 4 | quote-export | planned | notes-toc-panels | Реализация экспорта цитат и аннотаций в различные форматы: текст, изображение с обложкой, Markdown. |

---

## Status Legend
- **idea** — не оформлено в задачу
- **planned** — оформлено, назначено в milestone
- **in-progress** — активно разрабатывается
- **done** — завершено и проверено
- **cut** — исключено из scope (с указанием причины)

---

## Change Log

- 2026-03-29: Confirmed 57 tasks: 01-foundation/project-cleanup, 01-foundation/design-tokens, 01-foundation/app-theme, 01-foundation/navigation-state, 01-foundation/error-code, 01-foundation/l10n-foundation, 01-foundation/keychain-manager, 01-foundation/network-monitor, 01-foundation/icloudsettings-store, 01-foundation/diagnostics-service, 02-data-layer/swiftdata-models, 02-data-layer/file-reference-resolver, 02-data-layer/book-importer, 02-data-layer/download-manager, 02-data-layer/metadata-fetcher, 02-data-layer/collection-manager, 02-data-layer/spotlight-indexer, 03-library-ui/book-card-view, 03-library-ui/library-view, 03-library-ui/book-detail-view, 03-library-ui/main-tab-view, 03-library-ui/settings-view, 04-reader-core/file-format-handlers, 04-reader-core/text-reader-view, 04-reader-core/reader-view, 04-reader-core/comic-reader-view, 04-reader-core/annotation-service, 05-audio-player/audio-format-handlers, 05-audio-player/audio-player-view, 05-audio-player/tts-service-basic, 06-cloud-providers/cloud-provider-protocol, 06-cloud-providers/icloud-webdav-providers, 06-cloud-providers/oauth-manager, 06-cloud-providers/oauth-cloud-providers, 06-cloud-providers/smb-provider, 06-cloud-providers/cloud-file-browser-view, 07-sync/cloudkit-sync-manager, 07-sync/conflict-resolver, 07-sync/background-sync-task, 07-sync/reading-position-sync, 08-ai-features/gemini-service, 08-ai-features/translation-service, 08-ai-features/gemini-tts-provider, 08-ai-features/summary-xray-dictionary, 09-monetization/storekit-manager, 09-monetization/premium-state-validator, 09-monetization/premium-paywall-view, 10-widget/widget-extension, 10-widget/app-group-shared-store, 11-additional-formats/cbr-handler, 11-additional-formats/mobi-azw3-handler, 11-additional-formats/djvu-chm-handler, 12-polish/analytics-event, 12-polish/metadata-editor-view, 12-polish/performance-optimization, 12-polish/accessibility, 12-polish/diagnostics-view

- 2026-06-10: Три изменения по запросу: (1) `check-refs-validation` перенесена из M10 в M1 с приоритетом #1 — инструмент валидации должен работать с первого дня разработки; (2) добавлены две новые задачи в M3: `djvu-handler` (#8) и `chm-handler` (#9) — форматы присутствовали в архитектуре, но отсутствовали в плане; (3) задача `opds-catalogs` в M11 дополнена примечанием о том, что базовый UI (OnlineView) уже существует как заглушка. Задача `check-refs-validation` удалена из M10 (перенесена в M1).
- 2026-03-29: Подтверждено 61 задача: 01-foundation/project-structure-cleanup, 01-foundation/design-tokens, 01-foundation/app-theme-system, 01-foundation/error-code-system, 01-foundation/keychain-manager, 01-foundation/l10n-foundation, 01-foundation/network-monitor, 01-foundation/icloud-settings-store, 01-foundation/diagnostics-service, 02-data-layer/swiftdata-models, 02-data-layer/model-actor-context, 02-data-layer/file-reference-resolver, 02-data-layer/book-importer, 02-data-layer/cover-fetcher, 02-data-layer/metadata-fetcher, 02-data-layer/download-manager, 02-data-layer/collection-manager, 02-data-layer/spotlight-indexer, 03-format-handlers/file-format-handler-protocol, 03-format-handlers/epub-handler, 03-format-handlers/fb2-handler, 03-format-handlers/pdf-handler, 03-format-handlers/comic-handlers, 03-format-handlers/text-handlers, 03-format-handlers/mobi-azw3-handler, 03-format-handlers/audio-handler, 04-ui-core/navigation-state, 04-ui-core/main-tab-view, 04-ui-core/book-card-view, 04-ui-core/library-view, 04-ui-core/book-detail-view, 04-ui-core/settings-view, 05-reader-core/reader-view-container, 05-reader-core/text-reader-view, 05-reader-core/comic-reader-view, 05-reader-core/audio-player-view, 05-reader-core/tts-service, 05-reader-core/reading-state-manager, 05-reader-core/notes-toc-panels, 06-cloud-layer/cloud-provider-protocol, 06-cloud-layer/icloud-provider, 06-cloud-layer/webdav-providers, 06-cloud-layer/oauth-providers, 06-cloud-layer/smb-provider, 06-cloud-layer/cloud-file-browser, 06-cloud-layer/cloudkit-sync, 07-ai-features/gemini-service-core, 07-ai-features/translation-service, 07-ai-features/summary-xray-dictionary, 07-ai-features/gemini-tts-provider, 08-monetization/storekit-manager, 08-monetization/premium-state-validator, 08-monetization/premium-paywall-view, 09-widget/widget-extension, 10-localization-polish/full-localization, 10-localization-polish/accessibility-polish, 10-localization-polish/check-refs-validation, 11-advanced-features/reading-stats, 11-advanced-features/opds-catalogs, 11-advanced-features/auto-scroll, 11-advanced-features/quote-export
- 2026-03-29: Начальный план создан с 61 задачей в 11 milestone