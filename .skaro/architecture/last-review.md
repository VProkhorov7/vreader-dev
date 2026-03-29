## Review

---

### Слабые места, несоответствия и риски

---

**[CRITICAL] Хранение `isPremium` в `iCloudSettingsStore` без верификации на стороне StoreKit при каждом запуске**

Severity: CRITICAL
Описание: Архитектура декларирует `isPremium хранится в iCloudSettingsStore + верифицируется через StoreKit`, однако в разделе Monetization Layer нет явного механизма, который гарантирует, что `iCloudSettingsStore.isPremium = true` не может быть выставлен без прохождения StoreKit верификации. iCloudSettingsStore (NSUbiquitousKeyValueStore) — это незащищённое хранилище, доступное для чтения/записи без каких-либо ограничений. Злоумышленник или баг может выставить флаг напрямую. Кроме того, синхронизация `isPremium` через CloudKit создаёт вектор атаки: если один девайс скомпрометирован, флаг распространяется на все устройства.
Рекомендация: `isPremium` должен определяться ИСКЛЮЧИТЕЛЬНО через `StoreKit 2 Transaction.currentEntitlements` при каждом запуске и при каждом вызове `PremiumGate.check()`. iCloudSettingsStore может использоваться только как кэш для оффлайн-сценария с TTL не более 24 часов. Синхронизацию `isPremium` через CloudKit убрать полностью — это не данные пользователя, это статус подписки. Добавить `PremiumStateValidator` как отдельный компонент с явным контрактом.

---

**[CRITICAL] Отсутствие стратегии обработки конфликтов SwiftData + CloudKit при одновременном редактировании аннотаций**

Severity: CRITICAL
Описание: Описана стратегия "winner = latest timestamp", но она не покрывает случаи: (1) clock skew между устройствами, (2) одновременное удаление на одном устройстве и редактирование на другом, (3) merge аннотаций одного и того же хайлайта с разными комментариями. Last-write-wins по timestamp — наивная стратегия, которая приводит к потере данных пользователя.
Рекомендация: Ввести явную `ConflictResolutionStrategy` enum с вариантами: `.lastWriteWins`, `.merge(preferLocal)`, `.merge(preferRemote)`, `.userPrompt`. Для аннотаций использовать `.merge` с объединением комментариев. Добавить `vectorClock` или `lamportTimestamp` к `Annotation` модели. Описать это в отдельном ADR.

---

**[CRITICAL] ElevenLabs TTS — внешняя зависимость без fallback и без описания обработки ошибок**

Severity: CRITICAL
Описание: Premium TTS полностью завязан на ElevenLabs. Нет описания: что происходит при недоступности API, как обрабатываются сетевые ошибки, есть ли retry, есть ли деградация до AVSpeechSynthesizer. Для платного пользователя недоступность ElevenLabs означает полную потерю TTS-функциональности.
Рекомендация: Добавить явный fallback: ElevenLabs → Gemini TTS → AVSpeechSynthesizer. Описать `TTSProviderProtocol` с методами `synthesize(text:) async throws -> AVPlayerItem` и явной цепочкой провайдеров. Добавить circuit breaker для внешних AI-сервисов.

---

**[HIGH] Отсутствие описания обработки больших файлов (DJVU, CBR, MOBI)**

Severity: HIGH
Описание: Форматы DJVU, CBR (RAR), MOBI/AZW3 требуют нативных или сторонних библиотек для парсинга. Архитектура не упоминает: какие библиотеки используются, как они интегрируются, каков memory footprint при открытии 500-страничного DJVU или 200MB CBR. SwiftData хранит `coverData` как Data — это прямой путь к OOM при больших обложках.
Рекомендация: (1) Явно указать библиотеки для каждого формата (libdjvu, UnRAR SDK, etc.). (2) `coverData` в SwiftData заменить на `coverPath: String` — обложки уже кешируются в Documents/Covers/, хранить их дважды нет смысла. (3) Добавить `FileFormatHandler` протокол с lazy loading и streaming API. (4) Описать memory budget: максимальный размер страницы в памяти, политику выгрузки.

---

**[HIGH] `Book.filePath` — строковый путь к файлу без описания стратегии при перемещении файла**

Severity: HIGH
Описание: `filePath: String` — хрупкая ссылка. При обновлении iOS, переименовании папки, восстановлении из бэкапа или синхронизации через iCloud путь может измениться. Нет описания механизма восстановления ссылки.
Рекомендация: Использовать `bookmarkData: Data` (Security-Scoped Bookmarks для iCloud файлов) как основной идентификатор файла, `filePath` — как кэш для быстрого доступа. Добавить `FileReferenceResolver` с логикой восстановления по bookmarkData при broken path.

---

**[HIGH] Отсутствие observability и error reporting**

Severity: HIGH
Описание: В архитектуре нет ни слова об: (1) логировании (даже локальном), (2) crash reporting, (3) аналитике использования фич (для принятия решений о roadmap), (4) диагностике проблем с облачными провайдерами. Для приложения с 9 облачными провайдерами и AI-интеграциями это критично.
Рекомендация: Добавить `DiagnosticsService` с уровнями `.debug`, `.info`, `.warning`, `.error`. Интегрировать OSLog (нативный, без сторонних зависимостей). Добавить `AnalyticsEvent` enum для ключевых событий (book_opened, cloud_connected, premium_purchased, ai_translation_used). Описать политику: никаких PII в логах.

---

**[HIGH] `GeminiService` — единая точка отказа для всех AI-функций без rate limiting и quota management**

Severity: HIGH
Описание: Все AI-функции (перевод, TTS, Summary, X-Ray, Dictionary) идут через один `GeminiService`. Нет описания: (1) как обрабатываются 429 (rate limit), (2) как управляется квота API ключа, (3) что происходит при исчерпании квоты у пользователя, (4) есть ли очередь запросов.
Рекомендация: Добавить `AIRequestQueue` с приоритетами (интерактивные запросы > фоновые), `RateLimiter` с exponential backoff, `QuotaTracker` для отображения пользователю оставшегося лимита. Описать поведение при quota exhaustion: graceful degradation с понятным сообщением.

---

**[HIGH] Отсутствие описания миграции SwiftData схемы**

Severity: HIGH
Описание: SwiftData миграции — известная болевая точка. При добавлении полей в `Book`, `Annotation`, `Collection` между версиями приложения без явной стратегии миграции пользователи потеряют данные или получат crash при обновлении.
Рекомендация: Добавить раздел "Schema Versioning" с описанием: использование `VersionedSchema`, `SchemaMigrationPlan`, политика lightweight vs custom migration. Каждое изменение модели = новая версия схемы.

---

**[HIGH] SMBProvider — безопасность и совместимость**

Severity: HIGH
Описание: SMB на iOS — нетривиальная задача. Нативного SMBClient в iOS нет (есть только в macOS через `SMBClient` framework, доступный с macOS 13). На iOS нужна сторонняя библиотека или собственная реализация. Архитектура не упоминает это ограничение.
Рекомендация: Явно указать: SMBProvider использует `AMSMB2` (популярная Swift-библиотека для iOS SMB2/3). Описать ограничения: только SMB2+, Kerberos не поддерживается, только NTLM/Guest. Добавить в Constraints раздел.

---

**[MEDIUM] `CollectionManager` — нет описания поведения при удалении папки в облаке**

Severity: MEDIUM
Описание: Если пользователь удаляет папку `/Books/Fantasy/` в iCloud, что происходит с коллекцией "Fantasy" и книгами в ней? Удаляются ли книги из библиотеки? Остаётся ли коллекция пустой? Нет описания этого сценария.
Рекомендация: Добавить явную политику: при удалении облачной папки коллекция переходит в статус `.orphaned`, книги остаются в библиотеке с флагом `isLocalCopy: Bool`. Пользователь получает уведомление.

---

**[MEDIUM] `ReadingSession` — неясная ответственность**

Severity: MEDIUM
Описание: `ReadingSession` описан как "последняя открытая книга, статистика чтения" — это два разных концерна в одном компоненте. Статистика чтения (время, страницы) — это аналитические данные, требующие персистентности. Последняя открытая книга — это UI state.
Рекомендация: Разделить на `ReadingStateManager` (текущая позиция, UI state) и `ReadingStatsRepository` (SwiftData модель `ReadingSession` с полями: bookID, startedAt, endedAt, pagesRead, wordsRead).

---

**[MEDIUM] Отсутствие описания Deep Links и Universal Links**

Severity: MEDIUM
Описание: Для OAuth callback (Google Drive, Dropbox, OneDrive) через ASWebAuthenticationSession нужен redirect URI. Архитектура упоминает ASWebAuthenticationSession, но не описывает схему URL и обработку callback.
Рекомендация: Добавить раздел "URL Schemes": `vreader://oauth/callback`, `vreader://open?bookID=`, обработка через `onOpenURL` в SwiftUI. Описать регистрацию custom URL scheme в Info.plist.

---

**[MEDIUM] `AppState` — слишком широкий глобальный стейт**

Severity: MEDIUM
Описание: `AppState` с `selectedTab` и `currentBook` — это начало God Object. По мере роста приложения туда будут добавляться всё новые поля.
Рекомендация: Использовать композицию: `NavigationState` (selectedTab, navigationPath), `LibraryState` (currentBook, searchQuery, filters), `PlayerState` (currentAudioBook, playbackPosition). Каждый — отдельный `@Observable` класс.

---

**[MEDIUM] Нет описания политики кэширования для облачных файлов**

Severity: MEDIUM
Описание: При скачивании книг из облака нет описания: (1) где хранятся скачанные файлы, (2) как управляется дисковое пространство, (3) есть ли лимит кэша, (4) как пользователь удаляет скачанные копии.
Рекомендация: Добавить `DownloadManager` с политикой: файлы в `Documents/Books/`, метаданные скачивания в SwiftData (`DownloadRecord`), UI для управления локальными копиями, автоочистка по LRU при превышении порога (настраивается пользователем).

---

**[MEDIUM] Отсутствие описания Background Tasks для синхронизации**

Severity: MEDIUM
Описание: Синхронизация CloudKit описана как `onAppear/onDisappear`, что означает синхронизация только при активном приложении. Нет описания фоновой синхронизации через `BGAppRefreshTask`.
Рекомендация: Добавить `BackgroundSyncTask` с регистрацией `BGAppRefreshTask`. Описать минимальный интервал (iOS ограничивает до ~15 минут). CloudKit push notifications для мгновенной синхронизации при изменениях на другом устройстве.

---

**[LOW] Milestone 09 содержит "Social (цитаты)" без описания**

Severity: LOW
Описание: "Social" функциональность — это потенциально большой scope (шаринг, профили, фид). Без описания это создаёт неопределённость.
Рекомендация: Уточнить: "Social = экспорт цитаты как изображения (share sheet)". Если планируется что-то большее — вынести в отдельный milestone с описанием.

---

**[LOW] Нет описания Accessibility (VoiceOver, Dynamic Type)**

Severity: LOW
Описание: Для приложения-ридера с AI TTS отсутствие описания accessibility — упущение. VoiceOver и Dynamic Type критичны для части аудитории.
Рекомендация: Добавить в Constraints: "Все UI компоненты должны поддерживать VoiceOver labels и Dynamic Type. Минимальный размер шрифта — не менее .caption2 в DesignTokens."

---

### Несоответствия Constitution

1. **[HIGH]** Constitution: "NSUbiquitousKeyValueStore требует entitlement — не использовать без com.apple.developer.ubiquity-kvs-identifier". Архитектура использует NSUbiquitousKeyValueStore для позиции чтения, но нигде не упоминает entitlement в разделе Infrastructure. Нужно добавить явное упоминание required entitlements.

2. **[HIGH]** Constitution: "Gemini API ключ только в Keychain". В AI Layer описан `GeminiService` без упоминания того, как он получает API ключ. Нужно явно указать: `GeminiService` получает ключ через `KeychainManager.shared`.

3. **[MEDIUM]** Constitution: "Файлы публикуются только пакетами — зависимые файлы всегда вместе". В Milestones нет описания того, какие файлы входят в каждый пакет. Нужно добавить file manifest для каждого milestone.

4. **[MEDIUM]** Constitution: "UTType для нестандартных расширений — только optional, force-unwrap запрещён". Это упомянуто в Invariants, но нет описания конкретных UTType для FB2, CBZ, CBR, CBT, CB7, DJVU, AZW3, CHM — нестандартных форматов, требующих кастомных UTType.

---

### Спорные решения

**Решение 1: ElevenLabs для Premium TTS**
Проблема: ElevenLabs — платный сервис с собственным pricing. Это означает, что стоимость Premium подписки должна покрывать и ElevenLabs API costs. При $9.99/мес и активном использовании TTS маржа может быть отрицательной.
Альтернатива: Использовать Gemini TTS (входит в Gemini API, уже интегрирован) или Apple's AVSpeechSynthesizer с Neural voices (iOS 17+, бесплатно, высокое качество). ElevenLabs оставить как опциональный "ultra-premium" голос.

**Решение 2: SwiftData для всей библиотеки**
Проблема: SwiftData на iOS 17 имеет известные баги с производительностью при больших коллекциях (1000+ книг), проблемы с concurrent access и ограниченные возможности для complex queries.
Альтернатива: Рассмотреть GRDB.swift как более зрелое решение с лучшей производительностью и полным контролем над SQL. Или использовать SwiftData только для метаданных, вынеся тяжёлые операции в отдельный actor.

**Решение 3: Все облачные провайдеры в одном milestone (04)**
Проблема: 9 провайдеров в одном milestone — огромный scope. Google Drive OAuth + REST, Dropbox OAuth + REST, OneDrive OAuth + REST — каждый требует отдельного OAuth app registration, тестирования edge cases, обработки token refresh.
Альтернатива: Разбить на 04a (iCloud + WebDAV-based: Yandex, Nextcloud, MailRu) и 04b (OAuth-based: Google, Dropbox, OneDrive) и 04c (SMB). Это снизит риск и позволит выпустить MVP раньше.

**Решение 4: `coverData: Data` в SwiftData модели**
Проблема: Хранение бинарных данных в SwiftData модели — антипаттерн. Это замедляет загрузку списка книг (каждая запись тянет за собой потенциально мегабайты данных), увеличивает размер базы.
Альтернатива: Только `coverPath: String` (уже есть Documents/Covers/). `coverData` убрать полностью.

---

### Рекомендуемые ADR

| # | Название | Обоснование |
|---|----------|-------------|
| ADR-001 | Стратегия верификации Premium статуса | CRITICAL: определить единственный источник истины для isPremium |
| ADR-002 | Стратегия разрешения конфликтов CloudKit | CRITICAL: last-write-wins vs vector clock для аннотаций |
| ADR-003 | Выбор SwiftData vs GRDB для хранилища библиотеки | HIGH: производительность при 1000+ книгах |
| ADR-004 | Стратегия миграции SwiftData схемы | HIGH: VersionedSchema plan |
| ADR-005 | Выбор TTS провайдера для Premium | HIGH: ElevenLabs vs Gemini TTS vs AVSpeechSynthesizer Neural |
| ADR-006 | Стратегия идентификации файлов (path vs bookmark) | HIGH: Security-Scoped Bookmarks |
| ADR-007 | SMB реализация на iOS | HIGH: AMSMB2 vs альтернативы |
| ADR-008 | Стратегия фоновой синхронизации | MEDIUM: BGAppRefreshTask + CloudKit push |
| ADR-009 | URL Scheme для OAuth callback и deep links | MEDIUM: custom scheme vs universal links |
| ADR-010 | Политика кэширования облачных файлов | MEDIUM: LRU, лимиты, управление |

---

### Рекомендуемые диаграммы

1. **C4 Context Diagram** — VReader в контексте внешних систем (CloudKit, Gemini API, ElevenLabs, StoreKit, 9 облачных провайдеров). Показывает границы системы.

2. **C4 Container Diagram** — основные компоненты приложения и их взаимодействие (Data Layer, Cloud Layer, AI Layer, UI Layer, Sync Layer).

3. **Data Flow: Импорт книги** — sequence diagram от fileImporter до SwiftData insert, включая async шаги MetadataFetcher.

4. **Data Flow: Premium верификация** — state machine: StoreKit Transaction → PremiumStateValidator → PremiumGate → Feature unlock. Критично для понимания security модели.

5. **Sync Architecture Diagram** — как данные движутся между iPhone, iPad, CloudKit, NSUbiquitousKeyValueStore. Показывает conflict resolution points.

6. **CloudProvider Protocol Hierarchy** — UML диаграмма наследования: CloudProviderProtocol → WebDAVProvider → YandexDiskProvider/NextcloudProvider/MailRuProvider; отдельно OAuth-based providers.

7. **SwiftData Schema Diagram** — ER-диаграмма: Book, Annotation, Collection, ReadingSession, DownloadRecord с relationships и типами полей.

---