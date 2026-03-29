# Architecture: VReader — Digiteka
## Version: 1.2.0

## Vision
"Your Intelligent Personal Book Cloud" — объединение лучшего из
Moon+ Reader, KyBook и Marvin с мощью Gemini AI.
Главные конкурентные преимущества: KyBook 3 и Marvin заброшены,
мы занимаем освободившуюся нишу.

---

## Required Entitlements
Все entitlements обязательны в .entitlements файле:
- com.apple.developer.ubiquity-kvs-identifier
- com.apple.developer.icloud-services
- com.apple.developer.icloud-container-identifiers
- com.apple.security.application-groups (App Group для Widget)

---

## Book Content States
Каждая книга имеет одно из трёх состояний — пользователь
никогда не видит физическое расположение файла:

- `.cloudOnly` — только метаданные (title, author, genre,
  format, source, coverPath). Файл не скачан.
  Синхронизируются: название, обложка, тип файла, источник.

- `.previewed` — метаданные + первые 10 страниц.
  Скачиваются фоново при появлении книги в каталоге провайдера.
  Позволяет полистать книгу без полной загрузки.
  Превью хранятся в Documents/Previews/{bookID}/.

- `.downloaded` — полный файл в Documents/Books/{bookID}/.
  При переходе из .previewed: превью удаляются автоматически,
  используются страницы из полного файла.
  Инициируется: тапом "Читать" на .cloudOnly (молча, без диалога),
  кнопкой "Загрузить" на карточке,
  кнопкой "Загрузить каталог" на уровне коллекции.

Переход .cloudOnly → .downloaded при нажатии "Читать":
DownloadManager.download(book:) → фоновая загрузка →
прогресс на карточке → открытие ReaderView по завершении.

---

## Offline-First Contract
Работает без сети:
- Чтение всех .downloaded книг
- Просмотр превью .previewed книг
- Редактирование аннотаций (сохраняются в PendingChangesQueue)
- Настройки (тема, шрифт)
- Навигация по локальной библиотеке

Требует сети:
- AI перевод (GeminiService) — показывает offline banner
- AI TTS (Gemini TTS) — показывает offline banner,
  fallback на AVSpeechSynthesizer для Free tier
- Синхронизация CloudKit
- Загрузка из облачных провайдеров
- MetadataFetcher (Google Books, OpenLibrary)
- OAuth авторизация

UI всегда явно сигнализирует об offline режиме через
NetworkMonitor + banner в ReaderTopBar и TranslationPanel.

---

## Components

### Core Data Layer

#### SwiftData Models (VersionedSchema обязателен)

`Book` — основная сущность.
Поля: id, title, author, coverPath (String, НЕ Data),
filePath (String, кэш), bookmarkData (Data, основной идентификатор),
format, fileSize, source, addedAt, progress, lastPage,
lastOpenedAt, isFinished, tags, genre, description,
seriesName, seriesIndex, collectionID,
contentState (BookContentState: .cloudOnly | .previewed | .downloaded),
isLocalCopy (Bool), previewPagesPath (String?)

Инварианты:
- coverData: Data запрещён — только coverPath: String
- bookmarkData — основной идентификатор файла
- filePath — только кэш для быстрого доступа

`Annotation` — закладки, хайлайты, заметки.
Поля: id, bookID, chapter, text, comment, type, color,
date, lamportClock (Int), deviceID (String)

Инварианты:
- lamportClock обязателен, инкрементируется при каждой мутации
- deviceID обязателен для conflict resolution

`Collection` — коллекции книг.
Поля: id, name, sourcePath, isAutomatic, sortOrder,
status (CollectionStatus: .active | .orphaned)

`ReadingStatsRecord` — статистика чтения.
Поля: id, bookID, startedAt, endedAt, pagesRead, wordsRead

`DownloadRecord` — метаданные загрузок из облака.
Поля: id, bookID, providerID, remoteURL, downloadedAt,
localPath, fileSize, contentState

`PendingChangesQueue` — очередь оффлайн-изменений.
Поля: id, recordType, recordID, operation, payload, createdAt

#### Schema Versioning
- Каждое изменение модели = новая VersionedSchema
- SchemaMigrationPlan обязателен с первого релиза
- Lightweight migration для добавления nullable полей
- Custom migration для переименования, удаления, изменения типов
- Тестирование миграции на реальных данных перед каждым релизом

#### SwiftData + Concurrency
- Все SwiftData операции вне главного потока через @ModelActor
- Прямая запись в SwiftData минуя @ModelContext запрещена
- Фоновые операции (MetadataFetcher, DownloadManager,
  BackgroundSyncTask) используют отдельный @ModelActor контекст

#### Ключевые сервисы Data Layer

`BookImporter` — импорт файлов, создание bookmarkData,
извлечение метаданных из файла.

`FileReferenceResolver` — разрешение файловых ссылок.
resolve(book:) -> URL?
createBookmark(url:) -> Data?
repair(book:) -> Bool
При broken path: bookmarkData → сканирование Documents/Books/
по имени → book.contentState = .cloudOnly + уведомление.

`MetadataFetcher` — автозахват при импорте:
1. Из файла (EPUB OPF, FB2 description)
2. Google Books API (ключ через KeychainManager.shared)
3. OpenLibrary API (fallback)
Обложки: Documents/Covers/{bookID}.jpg

`CollectionManager` — коллекции из структуры папок.
При удалении папки в облаке: коллекция → .orphaned,
книги остаются с isLocalCopy = true, пользователь уведомляется.

`ReadingStateManager` — текущая позиция, UI state.
Отделён от статистики.

`DownloadManager` — управление загрузками.
Превью (10 страниц): Documents/Previews/{bookID}/
Полные файлы: Documents/Books/{bookID}/
При переходе .previewed → .downloaded: превью удаляются.
LRU-очистка при превышении порога (дефолт 2GB).
Политика фонового скачивания превью: только при наличии сети,
приоритет ниже интерактивных загрузок.

`NetworkMonitor` — NWPathMonitor обёртка.
@Published var isOnline: Bool
Используется всеми сервисами для graceful offline handling.

`SpotlightIndexer` — CoreSpotlight индексация.
Индексирует: title, author, genre, series, tags.
НЕ индексирует содержимое книг (производительность).
Обновляется при импорте и редактировании метаданных.
Поддержка deep link: vreader://open?bookID=

#### File Format Handlers
`FileFormatHandler` protocol:
func openPage(_ index: Int) async throws -> PageContent
func pageCount() async throws -> Int
func extractMetadata() async throws -> BookMetadata
func extractCover() async throws -> Data?

Реализации:
- EPUB: нативный парсер (ZIP + OPF + HTML)
- FB2/FB2.ZIP: нативный XML парсер
- PDF: PDFKit (нативный)
- CBZ: ZIP + изображения (нативный)
- CBR: AMSMB2 / UnRAR SDK
- CBT: TAR парсер
- CB7: 7-Zip SDK
- MOBI/AZW3: открытая реализация
- DJVU: libdjvu (C через Swift bridging)
- TXT/RTF: нативный
- CHM: libchm (C через Swift bridging)
- MP3/M4A/M4B/AAC: AVFoundation (нативный)

Инварианты:
- Lazy loading и streaming для всех форматов
- Максимальный размер страницы в памяти: 50MB
- Максимум 3 страницы одновременно (текущая + соседние)
- При превышении — автоматическая выгрузка дальних страниц

#### Custom UTTypes (Info.plist)
- org.idpf.epub-container — EPUB
- com.vreader.fb2 — FB2
- com.vreader.fb2zip — FB2.ZIP
- com.vreader.cbz — CBZ
- com.vreader.cbr — CBR
- com.vreader.cbt — CBT
- com.vreader.cb7 — CB7
- com.vreader.djvu — DJVU
- com.vreader.azw3 — AZW3
- com.vreader.chm — CHM

Инвариант: все UTType через optional binding, force-unwrap запрещён.

---

### Design System

`AppTheme` protocol:
surfaceBase, surfaceLow, surfaceMid, surfaceHigh,
accent, inkPrimary, inkMuted, fontDisplay, fontBody,
cornerRadius, usesMonospace, usesRTLHints

`DesignTokens.swift` — единственный источник всех значений.
Включает: минимальный шрифт (.caption2), memory budget,
анимационные параметры.

Правила:
- Никаких 1px бордеров — только фоновые сдвиги
- Frosted glass тулбары: surface 85% + backdrop-blur 20px
- Темы через @Environment(\.appTheme)
- Все UI компоненты поддерживают VoiceOver и Dynamic Type
- Минимальный шрифт: .caption2

#### Theme Variants
`EditorialDarkTheme` — #1a1a1a, gold #C8861A, Serif.
Дефолт, ночной режим. Free.

`CuratorLightTheme` — #F5F0E8, gold underlines, Serif.
Дневной режим. Free.

`NeuralLinkTheme` — #050505, #00FF41, #00F3FF, гротеск, rx=4.
"Neural Link // Protocol". Premium only.

`TypewriterTheme` — #F4F0E4, #8B2500,
American Typewriter / Courier New, rx=2. Premium only.

#### Localization
- Milestone 08: RU ✓, EN ✓, AR (RTL layout), ZH (CJK fonts)
- Milestone 09: ES, FR
- AR: полный RTL layout flip + BiDi text rendering
- ZH: CJK fallback шрифт + GBK encoding

---

### Navigation & State
Композиция @Observable классов вместо единого AppState:
- `NavigationState` — selectedTab, navigationPath
- `LibraryState` — currentBook, searchQuery, activeFilters
- `PlayerState` — currentAudioBook, playbackPosition, isPlaying
- `ReaderState` — currentPosition, currentChapter, displaySettings

Инвариант: никакого God Object. Передаются через @Environment.

#### URL Schemes
- vreader://oauth/callback?code=&state= — OAuth redirect
- vreader://open?bookID= — открытие книги (Spotlight deep link)
- vreader://library — переход в библиотеку
Регистрация в Info.plist. Обработка через onOpenURL в root view.

---

### Widget Extension
WidgetKit extension (отдельный target):
- Отображает: обложка последней читаемой книги + прогресс
  + кнопка "Продолжить"
- Размеры: small (только обложка), medium (обложка + прогресс)
- Данные через App Group shared container
  (com.vreader.shared)
- Timeline provider обновляется при изменении currentBook
- Deep link на открытие книги через vreader://open?bookID=
- Entitlement: com.apple.security.application-groups

---

### UI Layer
- `ContentView` — TabView: library, reading, catalogs, settings
- `LibraryView` — сетка книг, поиск, жанры, Library/Favorites/Collections
- `BookCardView` — карточка 2:3, source badge, format badge,
  contentState badge (.cloudOnly → облачко, .previewed → частичная
  заливка, .downloaded → нет badge), progress bar
- `ReadingView` — "Продолжить чтение" + список в процессе
- `ReaderView` — основной ридер, auto-hide controls, жесты
- `TextReaderView` — EPUB/FB2/TXT, RTL поддержка
- `ComicReaderView` — CBZ/CBR, zoom, guided view
- `AudioPlayerView` — MP3/M4B, Control Center
- `ReaderTopBar` — frosted glass. Offline banner если нет сети.
- `ReaderBottomBar` — frosted glass, прогресс, навигация
- `ReaderSettingsPanel` — тема, шрифт, размер, интервал
- `TranslationPanel` — Gemini перевод + offline banner +
  quota display. Недоступно без сети.
- `NotesPanel` — заметки и закладки
- `TOCPanel` — оглавление
- `CatalogsView` / `OnlineView` — OPDS и онлайн-каталоги
- `SettingsView` — настройки + коннекторы + тема +
  управление локальными копиями
- `CloudConnectorView` — провайдеры, статус, contentState книг
- `PremiumPaywallView` — StoreKit 2 paywall
- `MetadataEditorView` — title, author, series, tags, genre
- `DiagnosticsView` — Debug: полный доступ к логам.
  Release: экспорт последних 100 записей через share sheet.

---

### Library Organization

#### Folder-Based Collections
- /Books/Fantasy/ → коллекция "Fantasy" автоматически
- CollectionManager следит за папками облачных провайдеров
- При удалении папки: коллекция → .orphaned,
  книги → isLocalCopy = true, уведомление пользователю
- Единая библиотека всех форматов без разделения по типу

#### Metadata & Covers
- Автозахват: файл → Google Books → OpenLibrary
- Обложки: Documents/Covers/{bookID}.jpg
- Повторный запрос: long press на карточке
- Редактирование метаданных in-app

---

### Cloud Layer
`CloudProviderProtocol`:
func listFiles(path:) async throws -> [CloudFile]
func download(file:to:) async throws
func upload(url:path:) async throws
func delete(file:) async throws
var providerID: String { get }
var status: CloudProviderStatus { get }

- `ICloudProvider` — NSMetadataQuery + Documents
- `WebDAVProvider` — PROPFIND/GET, Basic Auth, Keychain
- `YandexDiskProvider` — WebDAV (webdav.yandex.ru)
- `NextcloudProvider` — WebDAV (/remote.php/dav/files/user/)
- `MailRuProvider` — WebDAV (webdav.cloud.mail.ru)
- `GoogleDriveProvider` — OAuth2 + REST API
- `DropboxProvider` — OAuth2 + REST API
- `OneDriveProvider` — OAuth2 + REST API
- `SMBProvider` — AMSMB2 для SMB2/SMB3.
  Fallback на SMB1 legacy mode для старых NAS.
  Ограничения: NTLM/Guest auth, Kerberos не поддерживается.
  Только iOS (macOS использует нативный SMBClient).
- `CloudProviderManager` — реестр, activate, status,
  CloudProviderHealthMonitor (circuit breaker: 3 ошибки → .degraded)
- `OAuthManager` — PKCE flow через ASWebAuthenticationSession.
  Token refresh автоматический. Tokens только в Keychain.
  Никогда WKWebView.
- `WebDAVXMLParser` — PROPFIND парсер

---

### Sync Architecture

#### iCloud Sync
- Позиция чтения → NSUbiquitousKeyValueStore
  (entitlement: com.apple.developer.ubiquity-kvs-identifier)
- Аннотации, прогресс → CloudKit (CKRecord)
- Настройки → iCloudSettingsStore

#### Conflict Resolution
`ConflictResolutionStrategy`:
- `.lastWriteWins(lamportClock)` — позиция чтения
- `.autoMerge` — аннотации с delta < 5 минут между устройствами
- `.userPrompt` — аннотации с delta > 5 минут, или
  когда один девайс удалил, другой изменил

Механизм:
- Annotation.lamportClock инкрементируется при каждой мутации
- deviceID в каждой записи
- Clock skew защита: сравнение по lamportClock, не wall clock
- autoMerge: объединение комментариев с разделителем

#### Background Sync
- `BackgroundSyncTask` — BGAppRefreshTask
  (com.vreader.sync, минимум 15 минут)
- CloudKit push notifications (CKSubscription) —
  мгновенная синхронизация при изменениях на другом устройстве
- `PendingChangesQueue` (SwiftData) — оффлайн-изменения
  синхронизируются при восстановлении сети
- Retry: exponential backoff 1s → 2s → 4s → 8s → 16s,
  максимум 5 попыток

---

### AI Layer
`GeminiService` — единая точка входа.
API ключ ТОЛЬКО через KeychainManager.shared.
Требует активного сетевого соединения.
При отсутствии сети — немедленный .offline error,
UI показывает понятный banner.

`AIRequestQueue` — очередь с приоритетами:
.interactive (перевод по запросу) > .background (Summary, X-Ray).
Максимум 3 одновременных запроса.

`RateLimiter` — exponential backoff при 429.
Начало: 1s, максимум: 32s, попыток: 5.

`QuotaTracker` — отслеживание использования API квоты.
Отображается в TranslationPanel и SettingsView. Сброс ежедневно.

`TranslationService` — перевод главы.
Free: до 500 слов / Premium: полная глава.
Только онлайн. Офлайн: показывает NetworkUnavailableView.

`TTSService` — цепочка провайдеров:
1. Gemini TTS (Premium, основной) — только онлайн
2. AVSpeechSynthesizer Neural voices (Premium fallback, iOS 17+)
3. AVSpeechSynthesizer стандартный (Free, до 300 слов, оффлайн)

`TTSProviderProtocol`:
func synthesize(text: String) async throws -> AVPlayerItem
var isAvailable: Bool { get }
var requiresNetwork: Bool { get }

Circuit breaker: 3 ошибки → переключение на следующий провайдер.

Инвариант: ElevenLabs исключён. Может быть добавлен
в milestone 09 как опциональный ultra-premium голос.

`SummaryService`, `XRayService`, `DictionaryService` —
только Premium, только онлайн.

---

### Audio & TTS

#### Background Audio
- AVAudioSession.category = .playback
- Now Playing Info: обложка, название, автор, прогресс
- Remote Control Events через наушники и Control Center
- AVSpeechSynthesizer (Free) — работает оффлайн и в фоне
- Gemini TTS (Premium) — чанки через AVPlayer,
  только онлайн, не работает в оффлайн

#### Immersion Reading (Milestone 09)
- Синхронное подсвечивание текста во время TTS
- Premium only
- AVSpeechSynthesizerDelegate для маппинга позиций

---

### Monetization Layer

`StoreKitManager` — StoreKit 2, покупки, восстановление,
верификация Transaction.currentEntitlements на каждом старте.

`PremiumStateValidator` — единственный компонент,
определяющий isPremium:
1. Transaction.currentEntitlements — источник истины
2. Если активна → isPremium = true
3. Результат кэшируется в iCloudSettingsStore с TTL 24 часа
4. Кэш используется ТОЛЬКО при отсутствии сети
5. При восстановлении сети — немедленная ревалидация

Инварианты:
- iCloudSettingsStore.isPremium — только кэш, не источник истины
- PremiumGate.check() всегда через PremiumStateValidator
- Синхронизация isPremium через CloudKit ЗАПРЕЩЕНА

`PremiumGate` — проверка лимитов через PremiumStateValidator.

#### Free tier
- Чтение .downloaded книг без ограничений
- Темы: EditorialDark + CuratorLight
- Перевод: до 500 слов на главу (онлайн)
- TTS: AVSpeechSynthesizer до 300 слов (оффлайн)
- Облако: только iCloud Drive
- Скачивание из облаков: до 3 книг

#### Premium ($9.99/мес или $49.99 lifetime)
- Темы: NeuralLink + Typewriter
- Полный перевод глав (онлайн)
- Gemini TTS полных глав (онлайн) +
  AVSpeechSynthesizer Neural fallback
- Все облачные коннекторы
- Безлимитные загрузки
- AI Summary, X-Ray, Dictionary (онлайн)

---

### Observability & Diagnostics

`DiagnosticsService` — OSLog, уровни: debug/info/warning/error/fault.
Инвариант: никаких PII в логах (email, токены, ключи,
содержимое книг, имена личных файлов).

`AnalyticsEvent` enum:
bookOpened(format:source:contentState:),
cloudConnected(provider:),
premiumPurchased(productID:),
aiTranslationUsed(wordCount:isOnline:),
syncCompleted(recordCount:duration:),
errorOccurred(code:),
offlineModeEntered(),
previewDownloaded(format:),
bookDownloaded(format:source:)
Только с явного согласия пользователя (GDPR-compliant).

`CloudProviderHealthMonitor` — circuit breaker:
3 ошибки → .degraded → уведомление пользователя.
Автовосстановление через 60 секунд.

---

### Infrastructure
- `KeychainManager` — WebDAV пароли, OAuth tokens,
  Gemini API ключ
- `iCloudSettingsStore` — настройки, isPremium кэш (TTL 24ч)
- `NavigationState`, `LibraryState`, `PlayerState`, `ReaderState`
- `NetworkMonitor` — NWPathMonitor, @Published isOnline
- `ErrorCode` — категории: .fileSystem, .network,
  .cloudProvider, .aiService, .storeKit, .sync, .parsing
  Каждая ошибка содержит: код, описание, recovery hint.
- `L10n` — RU/EN (milestone 08: AR, ZH)
- `check_refs.py` — validation gate перед каждым merge

---

## Architectural Invariants

### Data
- isPremium источник истины — только StoreKit 2
- coverData в SwiftData запрещён — только coverPath
- bookmarkData обязателен для каждой Book
- lamportClock обязателен для каждой Annotation
- Все SwiftData операции вне main thread через @ModelActor
- Все мутации Book/Annotation через @ModelContext

### Files
- UTType через optional binding, force-unwrap запрещён
- bookmarkData — primary identifier, filePath — кэш
- При broken path: FileReferenceResolver.repair()
- Превью удаляются при переходе .previewed → .downloaded

### Security
- Credentials только в Keychain
- OAuth только через ASWebAuthenticationSession
- Gemini API ключ только в Keychain
- Никаких PII в логах
- isPremium sync через CloudKit запрещён

### Performance
- Загрузка библиотеки P95 < 300ms для 1000 книг
- Открытие книги P95 < 1s для первой страницы
- Memory budget ридера: 50MB/страница, 3 страницы макс
- AI запросы: interactive timeout 10s, background 30s

### Consistency
- Зависимые файлы публикуются вместе
- Все строки через L10n.*
- DesignTokens.swift — единственный источник дизайн-значений
- @Environment(\.appTheme) — единственный способ получить тему
- Все ошибки типизированы через ErrorCode
- Circuit breaker для всех внешних сервисов

---

## Key Data Flows

### Импорт книги
fileImporter → BookImporter.import(url:)
→ FileReferenceResolver.createBookmark(url:)
→ copy to Documents/Books/
→ FileFormatHandler.extractMetadata()
→ MetadataFetcher (файл → Google Books → OpenLibrary)
→ cover → Documents/Covers/{bookID}.jpg
→ Book(coverPath:, bookmarkData:, contentState: .downloaded)
→ CollectionManager.updateCollections()
→ SpotlightIndexer.index(book:)
→ modelContext.insert(book)

### Появление книги в облачном каталоге
provider.listFiles() → CloudFile
→ Book(contentState: .cloudOnly, метаданные)
→ DownloadManager.schedulePreview(book:) [фоново]
→ скачать 10 страниц → Documents/Previews/{bookID}/
→ book.contentState = .previewed

### Нажатие "Читать" на .cloudOnly книге
ReaderView.open(book:)
→ if book.contentState == .cloudOnly:
   DownloadManager.download(book:) [молча, прогресс на карточке]
   → ждём завершения
   → book.contentState = .downloaded
→ FileReferenceResolver.resolve(book:)
→ FileFormatHandler.open(url:)

### AI Перевод (только онлайн)
TranslationPanel → NetworkMonitor.isOnline
→ if offline: показать NetworkUnavailableView
→ PremiumGate.check(.translation, wordCount:)
→ QuotaTracker.checkAvailable()
→ AIRequestQueue.enqueue(.interactive)
→ RateLimiter.execute()
→ GeminiService.translate(text:language:)
   [ключ из KeychainManager.shared]
→ QuotaTracker.recordUsage(wordCount:)

### Покупка Premium
PremiumPaywallView → StoreKitManager.purchase(productID:)
→ Transaction.currentEntitlements
→ PremiumStateValidator.validate()
→ iCloudSettingsStore.set(isPremiumCache: true, ttl: 24h)
→ PremiumGate разблокирует фичи
[CloudKit sync isPremium — ЗАПРЕЩЁН]

### Синхронизация аннотаций
onAppear / CKSubscription push
→ CloudKit.fetch(annotations)
→ ConflictResolver.resolve(local:remote:)
   delta < 5 мин → .autoMerge (lamportClock)
   delta > 5 мин → .userPrompt
   удаление vs изменение → .userPrompt
→ modelContext.save()
onDisappear → PendingChangesQueue → CloudKit.save()
→ NSUbiquitousKeyValueStore.set(lastPosition)

### Spotlight Deep Link
Пользователь ищет "Дюна" в Spotlight
→ CoreSpotlight возвращает результат (title, author, genre)
→ тап → vreader://open?bookID=XYZ
→ onOpenURL → NavigationState.openBook(id: XYZ)

---

## Competitive Differentiators
1. AI-first — перевод, TTS, саммари, X-Ray прямо в ридере
2. iCloud sync без своего сервера — CloudKit
3. Единая библиотека — все форматы, нет разделения
4. OAuth через ASWebAuthenticationSession (не WKWebView)
5. Автоматические метаданные и обложки
6. Фоновый TTS после сворачивания
7. Folder-based collections
8. 3 состояния книги: cloudOnly / previewed / downloaded
9. 4 темы: Editorial Dark, Curator Light, Neural Link, Typewriter
10. Языки ООН: AR (RTL), ZH (CJK)
11. Widget — обложка + "Продолжить" на home screen
12. Spotlight по title/author/genre/series
13. SMB1 legacy fallback для старых NAS
14. Активная разработка (KyBook мёртв 3 года)

---

## Milestones

- **01-design-system**
  DesignTokens, AppTheme protocol, 4 темы, BookCardView,
  ReaderTheme env, NetworkMonitor (base)
  Файлы: DesignTokens.swift, AppTheme.swift, *Theme.swift,
  BookCardView.swift, NetworkMonitor.swift

- **02-library-core**
  SwiftData v1 + SchemaMigrationPlan, Book/Annotation/Collection/
  ReadingStatsRecord/DownloadRecord/PendingChangesQueue,
  BookImporter, FileReferenceResolver, MetadataFetcher,
  CollectionManager, DownloadManager (3 состояния),
  SpotlightIndexer, FileFormatHandler + EPUB/FB2/TXT/PDF
  Файлы: Book.swift, Annotation.swift, Collection.swift,
  ReadingStatsRecord.swift, DownloadRecord.swift,
  PendingChangesQueue.swift, BookImporter.swift,
  MetadataFetcher.swift, CollectionManager.swift,
  FileReferenceResolver.swift, DownloadManager.swift,
  SpotlightIndexer.swift, *FormatHandler.swift

- **03-reader-core**
  TextReaderView, ComicReaderView, AudioPlayerView,
  background TTS, Remote Control, Now Playing,
  CBZ/CBR/MOBI/DJVU/CHM handlers,
  TTSService + TTSProviderProtocol
  Файлы: TextReaderView.swift, ComicReaderView.swift,
  AudioPlayerView.swift, TTSService.swift,
  TTSProviderProtocol.swift, *FormatHandler.swift

- **04a-cloud-webdav**
  CloudProviderProtocol, iCloud, WebDAV-based
  (Yandex, Nextcloud, MailRu), CloudProviderManager,
  CloudProviderHealthMonitor, WebDAVXMLParser
  Файлы: CloudProviderProtocol.swift, ICloudProvider.swift,
  WebDAVProvider.swift, YandexDiskProvider.swift,
  NextcloudProvider.swift, MailRuProvider.swift,
  CloudProviderManager.swift, WebDAVXMLParser.swift,
  CloudProviderHealthMonitor.swift

- **04b-cloud-oauth**
  OAuthManager, Google Drive, Dropbox, OneDrive
  Файлы: OAuthManager.swift, GoogleDriveProvider.swift,
  DropboxProvider.swift, OneDriveProvider.swift

- **04c-cloud-smb**
  SMBProvider (AMSMB2, SMB1 fallback)
  Файлы: SMBProvider.swift

- **05-sync**
  CloudKit аннотации + прогресс, ConflictResolver,
  BackgroundSyncTask, PendingChangesQueue sync,
  CloudKit push notifications
  Файлы: CloudKitSyncManager.swift, ConflictResolver.swift,
  BackgroundSyncTask.swift

- **06-ai-features**
  GeminiService, AIRequestQueue, RateLimiter, QuotaTracker,
  TranslationService, TTSService (Gemini TTS),
  SummaryService, XRayService, DictionaryService,
  DiagnosticsService, AnalyticsEvent
  Файлы: GeminiService.swift, AIRequestQueue.swift,
  RateLimiter.swift, QuotaTracker.swift,
  TranslationService.swift, SummaryService.swift,
  XRayService.swift, DictionaryService.swift,
  DiagnosticsService.swift, AnalyticsEvent.swift

- **07-monetization**
  StoreKitManager, PremiumStateValidator, PremiumGate,
  PremiumPaywallView, Premium themes unlock
  Файлы: StoreKitManager.swift, PremiumStateValidator.swift,
  PremiumGate.swift, PremiumPaywallView.swift

- **08-widget**
  WidgetKit extension, App Group shared container,
  Timeline provider
  Файлы: VReaderWidget.swift, WidgetTimelineProvider.swift

- **09-localization**
  L10n RU/EN полное покрытие + AR (RTL) + ZH (CJK)

- **10-advanced**
  AutoScroll, ReadingStats, ImmersionReading,
  SemanticSearch (in-app), Social (экспорт цитат),
  ES/FR локализация