# Architecture: VReader - Digiteka
## Version: 1.2.0

## Vision
"Your Intelligent Personal Book Cloud" - combining the best of Moon+ Reader, KyBook and Marvin with Gemini AI power.
Key competitive advantage: KyBook 3 and Marvin are abandoned, we take the vacant niche.

## Required Entitlements
All entitlements mandatory in .entitlements file:
- com.apple.developer.ubiquity-kvs-identifier
- com.apple.developer.icloud-services
- com.apple.developer.icloud-container-identifiers
- com.apple.security.application-groups (App Group for Widget)

## Book Content States
Each book has one of three states - user never sees physical file location:

- .cloudOnly - metadata only (title, author, genre, format, source, coverPath).
  File not downloaded. Synced: title, cover, format, source.

- .previewed - metadata + first 10 pages.
  Downloaded in background when book appears in provider catalog.
  Allows browsing without full download.
  Preview stored in Documents/Previews/{bookID}/.

- .downloaded - full file in Documents/Books/{bookID}/.
  On transition from .previewed: previews deleted automatically.
  Initiated by: tapping Read on .cloudOnly (silently),
  Download button on card, Download catalog button.

Transition .cloudOnly to .downloaded on Read tap:
DownloadManager.download(book:) - background download - progress on card - open ReaderView on completion.

## Offline-First Contract
Works without network:
- Reading all .downloaded books
- Browsing .previewed book previews
- Editing annotations (saved to PendingChangesQueue)
- Settings (theme, font)
- Local library navigation

Requires network:
- AI translation (GeminiService) - shows offline banner
- AI TTS (Gemini TTS) - shows offline banner, fallback to AVSpeechSynthesizer for Free tier
- CloudKit synchronization
- Downloading from cloud providers
- MetadataFetcher (Google Books, OpenLibrary)
- OAuth authorization

UI always signals offline mode via NetworkMonitor + banner in ReaderTopBar and TranslationPanel.

## Components

### Core Data Layer

#### SwiftData Models (VersionedSchema mandatory)

Book - main entity.
Fields: id, title, author, coverPath (String, NOT Data),
filePath (String, cache), bookmarkData (Data, primary identifier),
format, fileSize, source, addedAt, progress, lastPage,
lastOpenedAt, isFinished, tags, genre, description,
seriesName, seriesIndex, collectionID,
contentState (BookContentState: .cloudOnly | .previewed | .downloaded),
isLocalCopy (Bool), previewPagesPath (String?)

Invariants:
- coverData: Data forbidden - only coverPath: String
- bookmarkData - primary file identifier
- filePath - cache only for fast access

Annotation - bookmarks, highlights, notes.
Fields: id, bookID, chapter, text, comment, type, color,
date, lamportClock (Int), deviceID (String)

Invariants:
- lamportClock mandatory, incremented on every mutation
- deviceID mandatory for conflict resolution

Collection - book collections.
Fields: id, name, sourcePath, isAutomatic, sortOrder,
status (CollectionStatus: .active | .orphaned)

ReadingStatsRecord - reading statistics.
Fields: id, bookID, startedAt, endedAt, pagesRead, wordsRead

DownloadRecord - cloud download metadata.
Fields: id, bookID, providerID, remoteURL, downloadedAt,
localPath, fileSize, contentState

PendingChangesQueue - offline changes queue.
Fields: id, recordType, recordID, operation, payload, createdAt

#### Schema Versioning
- Every model change = new VersionedSchema
- SchemaMigrationPlan mandatory from first release
- Lightweight migration for adding nullable fields
- Custom migration for renaming, deletion, type changes
- Migration testing on real data before every release

#### SwiftData + Concurrency
- All SwiftData operations outside main thread via @ModelActor
- Direct SwiftData writes bypassing @ModelContext forbidden
- Background operations use separate @ModelActor context

#### Key Data Layer Services

BookImporter - file import, bookmarkData creation, metadata extraction.

FileReferenceResolver - file reference resolution.
resolve(book:) -> URL?
createBookmark(url:) -> Data?
repair(book:) -> Bool
On broken path: bookmarkData -> scan Documents/Books/ by name -> book.contentState = .cloudOnly + notification.

MetadataFetcher - auto-fetch on import:
1. From file (EPUB OPF, FB2 description)
2. Google Books API (key via KeychainManager.shared)
3. OpenLibrary API (fallback)
Covers: Documents/Covers/{bookID}.jpg

CollectionManager - folder-based collections.
On cloud folder deletion: collection -> .orphaned,
books remain with isLocalCopy = true, user notified.

ReadingStateManager - current position, UI state.
Separated from statistics.

DownloadManager - download management.
Previews (10 pages): Documents/Previews/{bookID}/
Full files: Documents/Books/{bookID}/
On .previewed -> .downloaded: previews deleted.
LRU cleanup when threshold exceeded (default 2GB).

NetworkMonitor - NWPathMonitor wrapper.
@Published var isOnline: Bool

SpotlightIndexer - CoreSpotlight indexing.
Indexes: title, author, genre, series, tags.
Does NOT index book content (performance).
Deep link: vreader://open?bookID=

#### File Format Handlers
FileFormatHandler protocol:
func openPage(_ index: Int) async throws -> PageContent
func pageCount() async throws -> Int
func extractMetadata() async throws -> BookMetadata
func extractCover() async throws -> Data?

Implementations:
- EPUB: native parser (ZIP + OPF + HTML)
- FB2/FB2.ZIP: native XML parser
- PDF: PDFKit (native)
- CBZ: ZIP + images (native)
- CBR: AMSMB2 / UnRAR SDK
- CBT: TAR parser
- CB7: 7-Zip SDK
- MOBI/AZW3: open implementation
- DJVU: libdjvu (C via Swift bridging)
- TXT/RTF: native
- CHM: libchm (C via Swift bridging)
- MP3/M4A/M4B/AAC: AVFoundation (native)

Invariants:
- Lazy loading and streaming for all formats
- Max page size in memory: 50MB
- Max 3 pages simultaneously (current + neighbors)
- Auto-eviction of distant pages on overflow

#### Custom UTTypes (Info.plist)
- org.idpf.epub-container: EPUB
- com.vreader.fb2: FB2
- com.vreader.fb2zip: FB2.ZIP
- com.vreader.cbz: CBZ
- com.vreader.cbr: CBR
- com.vreader.cbt: CBT
- com.vreader.cb7: CB7
- com.vreader.djvu: DJVU
- com.vreader.azw3: AZW3
- com.vreader.chm: CHM

Invariant: all UTType via optional binding, force-unwrap forbidden.

### Design System

AppTheme protocol:
surfaceBase, surfaceLow, surfaceMid, surfaceHigh,
accent, inkPrimary, inkMuted, fontDisplay, fontBody,
cornerRadius, usesMonospace, usesRTLHints

DesignTokens.swift - single source of all values.
Includes: min font size (.caption2), memory budget, animation parameters.

Rules:
- No 1px borders - only background shifts
- Frosted glass toolbars: surface 85% + backdrop-blur 20px
- Themes via @Environment(\.appTheme)
- All UI components support VoiceOver and Dynamic Type
- Min font size: .caption2

#### Theme Variants
EditorialDarkTheme - #1a1a1a, gold #C8861A, Serif. Default, night mode. Free.
CuratorLightTheme - #F5F0E8, gold underlines, Serif. Day mode. Free.
NeuralLinkTheme - #050505, #00FF41, #00F3FF, grotesque, rx=4. Premium only.
TypewriterTheme - #F4F0E4, #8B2500, American Typewriter / Courier New, rx=2. Premium only.

#### Localization
- Milestone 08: RU, EN, AR (RTL layout), ZH (CJK fonts)
- Milestone 09: ES, FR
- AR: full RTL layout flip + BiDi text rendering
- ZH: CJK fallback font + GBK encoding

### Navigation and State
Composition of @Observable classes instead of single AppState:
- NavigationState - selectedTab, navigationPath
- LibraryState - currentBook, searchQuery, activeFilters
- PlayerState - currentAudioBook, playbackPosition, isPlaying
- ReaderState - currentPosition, currentChapter, displaySettings

Invariant: no God Object. Passed via @Environment.

#### URL Schemes
- vreader://oauth/callback?code=&state= - OAuth redirect
- vreader://open?bookID= - open book (Spotlight deep link)
- vreader://library - go to library
Registration in Info.plist. Handled via onOpenURL in root view.

### Widget Extension
WidgetKit extension (separate target):
- Shows: cover of last reading book + progress + Continue button
- Sizes: small (cover only), medium (cover + progress)
- Data via App Group shared container (com.vreader.shared)
- Timeline provider updates on currentBook change
- Deep link via vreader://open?bookID=
- Entitlement: com.apple.security.application-groups

### UI Layer
- ContentView - TabView: library, reading, catalogs, settings
- LibraryView - book grid, search, genre filters, Library/Favorites/Collections tabs
- BookCardView - 2:3 card, source badge, format badge,
  contentState badge (.cloudOnly = cloud icon, .previewed = partial fill, .downloaded = no badge),
  progress bar
- ReadingView - Continue Reading card + in-progress list
- ReaderView - main reader, auto-hide controls, gestures
- TextReaderView - EPUB/FB2/TXT, RTL support
- ComicReaderView - CBZ/CBR, zoom, guided view
- AudioPlayerView - MP3/M4B, Control Center
- ReaderTopBar - frosted glass. Offline banner when no network.
- ReaderBottomBar - frosted glass, progress, navigation
- ReaderSettingsPanel - theme, font, size, line height
- TranslationPanel - Gemini translation + offline banner + quota display. Unavailable without network.
- NotesPanel - notes and bookmarks
- TOCPanel - table of contents
- CatalogsView / OnlineView - OPDS and online catalogs
- SettingsView - settings + connectors + theme + local copies management
- CloudConnectorView - providers, status, book contentState
- PremiumPaywallView - StoreKit 2 paywall
- MetadataEditorView - title, author, series, tags, genre
- DiagnosticsView - Debug: full log access. Release: export last 100 entries via share sheet.

### Library Organization

#### Folder-Based Collections
- /Books/Fantasy/ -> collection "Fantasy" created automatically
- CollectionManager watches cloud provider folders
- On folder deletion: collection -> .orphaned, books -> isLocalCopy = true, user notified
- Single library for all formats without type separation

#### Metadata and Covers
- Auto-fetch: file -> Google Books -> OpenLibrary
- Covers: Documents/Covers/{bookID}.jpg
- Re-fetch: long press on book card
- Metadata editing in-app

### Cloud Layer
CloudProviderProtocol:
func listFiles(path:) async throws -> [CloudFile]
func download(file:to:) async throws
func upload(url:path:) async throws
func delete(file:) async throws
var providerID: String { get }
var status: CloudProviderStatus { get }

- ICloudProvider - NSMetadataQuery + Documents
- WebDAVProvider - PROPFIND/GET, Basic Auth, Keychain
- YandexDiskProvider - WebDAV (webdav.yandex.ru)
- NextcloudProvider - WebDAV (/remote.php/dav/files/user/)
- MailRuProvider - WebDAV (webdav.cloud.mail.ru)
- GoogleDriveProvider - OAuth2 + REST API
- DropboxProvider - OAuth2 + REST API
- OneDriveProvider - OAuth2 + REST API
- SMBProvider - AMSMB2 for SMB2/SMB3. Fallback to SMB1 legacy for old NAS.
  Limitations: NTLM/Guest auth, Kerberos not supported. iOS only.
- CloudProviderManager - registry, activate, status, CloudProviderHealthMonitor
- OAuthManager - PKCE flow via ASWebAuthenticationSession. Never WKWebView.
- WebDAVXMLParser - PROPFIND parser

### Sync Architecture

#### iCloud Sync
- Reading position -> NSUbiquitousKeyValueStore
- Annotations, progress -> CloudKit (CKRecord)
- Settings -> iCloudSettingsStore

#### Conflict Resolution
ConflictResolutionStrategy:
- .lastWriteWins(lamportClock) - reading position
- .autoMerge - annotations with delta < 5 minutes between devices
- .userPrompt - annotations with delta > 5 minutes, or one device deleted while other edited

Mechanism:
- Annotation.lamportClock incremented on every mutation
- deviceID in every record
- Clock skew protection: compare by lamportClock, not wall clock
- autoMerge: combine comments with separator

#### Background Sync
- BackgroundSyncTask - BGAppRefreshTask (com.vreader.sync, min 15 minutes)
- CloudKit push notifications (CKSubscription) - instant sync on other device changes
- PendingChangesQueue (SwiftData) - offline changes synced on network restore
- Retry: exponential backoff 1s -> 2s -> 4s -> 8s -> 16s, max 5 attempts

### AI Layer
GeminiService - single entry point for all Gemini calls.
API key ONLY via KeychainManager.shared.
Requires active network connection.
On no network - immediate .offline error, UI shows clear banner.

AIRequestQueue - priority queue:
.interactive (translation on demand) > .background (Summary, X-Ray).
Max 3 concurrent requests.

RateLimiter - exponential backoff on 429.
Start: 1s, max: 32s, attempts: 5.

QuotaTracker - API quota usage tracking.
Displayed in TranslationPanel and SettingsView. Daily reset.

TranslationService - chapter translation.
Free: up to 500 words / Premium: full chapter.
Online only. Offline: shows NetworkUnavailableView.

TTSService - provider chain:
1. Gemini TTS (Premium, primary) - online only
2. AVSpeechSynthesizer Neural voices (Premium fallback, iOS 17+)
3. AVSpeechSynthesizer standard (Free, up to 300 words, offline)

TTSProviderProtocol:
func synthesize(text: String) async throws -> AVPlayerItem
var isAvailable: Bool { get }
var requiresNetwork: Bool { get }

Circuit breaker: 3 errors -> switch to next provider.

Invariant: ElevenLabs excluded. May be added in milestone 09 as optional ultra-premium voice.

SummaryService, XRayService, DictionaryService - Premium only, online only.

### Audio and TTS

#### Background Audio
- AVAudioSession.category = .playback
- Now Playing Info: cover, title, author, progress
- Remote Control Events via headphones and Control Center
- AVSpeechSynthesizer (Free) - works offline and in background
- Gemini TTS (Premium) - chunks via AVPlayer, online only

#### Immersion Reading (Milestone 09)
- Synchronized text highlighting during TTS
- Premium only
- AVSpeechSynthesizerDelegate for position mapping

### Monetization Layer

StoreKitManager - StoreKit 2, purchases, restore,
Transaction.currentEntitlements verification on every launch.

PremiumStateValidator - single component determining isPremium:
1. Transaction.currentEntitlements - source of truth
2. If active -> isPremium = true
3. Result cached in iCloudSettingsStore with TTL 24 hours
4. Cache used ONLY when no network
5. On network restore - immediate revalidation

Invariants:
- iCloudSettingsStore.isPremium - cache only, never source of truth
- PremiumGate.check() always via PremiumStateValidator
- isPremium sync via CloudKit FORBIDDEN

PremiumGate - feature limit checks via PremiumStateValidator.

#### Free tier
- Reading .downloaded books without limits
- Themes: EditorialDark + CuratorLight
- Translation: up to 500 words per chapter (online)
- TTS: AVSpeechSynthesizer up to 300 words (offline)
- Cloud: iCloud Drive only
- Cloud downloads: up to 3 books

#### Premium ($9.99/month or $49.99 lifetime)
- Themes: NeuralLink + Typewriter
- Full chapter translation (online)
- Gemini TTS full chapters (online) + AVSpeechSynthesizer Neural fallback
- All cloud connectors
- Unlimited downloads
- AI Summary, X-Ray, Dictionary (online)

### Observability and Diagnostics

DiagnosticsService - OSLog, levels: debug/info/warning/error/fault.
Invariant: no PII in logs (email, tokens, keys, book content).

AnalyticsEvent enum:
bookOpened(format:source:contentState:),
cloudConnected(provider:),
premiumPurchased(productID:),
aiTranslationUsed(wordCount:isOnline:),
syncCompleted(recordCount:duration:),
errorOccurred(code:),
offlineModeEntered(),
previewDownloaded(format:),
bookDownloaded(format:source:)
Only with explicit user consent (GDPR-compliant).

CloudProviderHealthMonitor - circuit breaker:
3 errors -> .degraded -> user notification.
Auto-recovery after 60 seconds.

### Infrastructure
- KeychainManager - WebDAV passwords, OAuth tokens, Gemini API key
- iCloudSettingsStore - settings, isPremium cache (TTL 24h)
- NavigationState, LibraryState, PlayerState, ReaderState
- NetworkMonitor - NWPathMonitor, @Published isOnline
- ErrorCode - categories: .fileSystem, .network, .cloudProvider,
  .aiService, .storeKit, .sync, .parsing
  Every error contains: code, description, recovery hint.
- L10n - RU/EN (milestone 08: AR, ZH)
- check_refs.py - validation gate before every merge

## Architectural Invariants

### Data
- isPremium source of truth - StoreKit 2 only
- coverData in SwiftData forbidden - only coverPath
- bookmarkData mandatory for every Book
- lamportClock mandatory for every Annotation
- All SwiftData operations outside main thread via @ModelActor
- All Book/Annotation mutations via @ModelContext

### Files
- UTType via optional binding, force-unwrap forbidden
- bookmarkData - primary identifier, filePath - cache
- On broken path: FileReferenceResolver.repair()
- Previews deleted on .previewed -> .downloaded transition

### Security
- Credentials only in Keychain
- OAuth only via ASWebAuthenticationSession
- Gemini API key only in Keychain
- No PII in logs
- isPremium sync via CloudKit forbidden

### Performance
- Library load P95 < 300ms for 1000 books
- Book open P95 < 1s for first page
- Reader memory budget: 50MB/page, 3 pages max
- AI requests: interactive timeout 10s, background 30s

### Consistency
- Dependent files published together
- All strings via L10n.*
- DesignTokens.swift - single source of design values
- @Environment(\.appTheme) - only way to get theme
- All errors typed via ErrorCode
- Circuit breaker for all external services

## Key Data Flows

### Book Import
fileImporter -> BookImporter.import(url:)
-> FileReferenceResolver.createBookmark(url:)
-> copy to Documents/Books/
-> FileFormatHandler.extractMetadata()
-> MetadataFetcher (file -> Google Books -> OpenLibrary)
-> cover -> Documents/Covers/{bookID}.jpg
-> Book(coverPath:, bookmarkData:, contentState: .downloaded)
-> CollectionManager.updateCollections()
-> SpotlightIndexer.index(book:)
-> modelContext.insert(book)

### Book appears in cloud catalog
provider.listFiles() -> CloudFile
-> Book(contentState: .cloudOnly, metadata)
-> DownloadManager.schedulePreview(book:) [background]
-> download 10 pages -> Documents/Previews/{bookID}/
-> book.contentState = .previewed

### Tap Read on .cloudOnly book
ReaderView.open(book:)
-> if book.contentState == .cloudOnly:
   DownloadManager.download(book:) [silently, progress on card]
   -> wait for completion
   -> book.contentState = .downloaded
-> FileReferenceResolver.resolve(book:)
-> FileFormatHandler.open(url:)

### AI Translation (online only)
TranslationPanel -> NetworkMonitor.isOnline
-> if offline: show NetworkUnavailableView
-> PremiumGate.check(.translation, wordCount:)
-> QuotaTracker.checkAvailable()
-> AIRequestQueue.enqueue(.interactive)
-> RateLimiter.execute()
-> GeminiService.translate(text:language:) [key from KeychainManager.shared]
-> QuotaTracker.recordUsage(wordCount:)

### Premium Purchase
PremiumPaywallView -> StoreKitManager.purchase(productID:)
-> Transaction.currentEntitlements
-> PremiumStateValidator.validate()
-> iCloudSettingsStore.set(isPremiumCache: true, ttl: 24h)
-> PremiumGate unlocks features
[CloudKit isPremium sync - FORBIDDEN]

### Annotation Sync
onAppear / CKSubscription push
-> CloudKit.fetch(annotations)
-> ConflictResolver.resolve(local:remote:)
   delta < 5 min -> .autoMerge (lamportClock)
   delta > 5 min -> .userPrompt
   deletion vs edit -> .userPrompt
-> modelContext.save()
onDisappear -> PendingChangesQueue -> CloudKit.save()
-> NSUbiquitousKeyValueStore.set(lastPosition)

### Spotlight Deep Link
User searches "Dune" in Spotlight
-> CoreSpotlight returns result (title, author, genre)
-> tap -> vreader://open?bookID=XYZ
-> onOpenURL -> NavigationState.openBook(id: XYZ)

## Competitive Differentiators
1. AI-first - translation, TTS, summary, X-Ray in reader
2. iCloud sync without own server - CloudKit
3. Single library - all formats, no separation
4. OAuth via ASWebAuthenticationSession (not WKWebView)
5. Automatic metadata and covers
6. Background TTS after minimizing
7. Folder-based collections
8. 3 book states: cloudOnly / previewed / downloaded
9. 4 themes: Editorial Dark, Curator Light, Neural Link, Typewriter
10. UN languages: AR (RTL), ZH (CJK)
11. Widget - cover + Continue on home screen
12. Spotlight by title/author/genre/series
13. SMB1 legacy fallback for old NAS
14. Active development (KyBook dead for 3 years)

## Milestones

- 01-design-system: DesignTokens, AppTheme protocol, 4 themes, BookCardView, NetworkMonitor
- 02-library-core: SwiftData v1, all models, BookImporter, FileReferenceResolver,
  MetadataFetcher, CollectionManager, DownloadManager (3 states), SpotlightIndexer,
  FileFormatHandler + EPUB/FB2/TXT/PDF
- 03-reader-core: TextReaderView, ComicReaderView, AudioPlayerView,
  background TTS, Remote Control, Now Playing, CBZ/CBR/MOBI/DJVU/CHM handlers
- 04a-cloud-webdav: CloudProviderProtocol, iCloud, WebDAV providers, CloudProviderManager
- 04b-cloud-oauth: OAuthManager, Google Drive, Dropbox, OneDrive
- 04c-cloud-smb: SMBProvider (AMSMB2, SMB1 fallback)
- 05-sync: CloudKit annotations + progress, ConflictResolver, BackgroundSyncTask
- 06-ai-features: GeminiService, AIRequestQueue, RateLimiter, QuotaTracker,
  TranslationService, TTSService, SummaryService, XRayService, DictionaryService,
  DiagnosticsService, AnalyticsEvent
- 07-monetization: StoreKitManager, PremiumStateValidator, PremiumGate, PremiumPaywallView
- 08-widget: WidgetKit extension, App Group shared container, Timeline provider
- 09-localization: L10n RU/EN full coverage + AR (RTL) + ZH (CJK)
- 10-advanced: AutoScroll, ReadingStats, ImmersionReading, SemanticSearch,
  Social (quote export), ES/FR localization

### UI Layer
- ContentView - TabView: library, reading, catalogs, settings
- LibraryView - book grid, search, genre filters, Library/Favorites/Collections tabs
- BookCardView - 2:3 card, source badge, format badge,
  contentState badge (.cloudOnly = cloud icon, .previewed = partial fill, .downloaded = no badge),
  progress bar
- ReadingView - Continue Reading card + in-progress list
- ReaderView - main reader, auto-hide controls, gestures
- TextReaderView - EPUB/FB2/TXT, RTL support
- ComicReaderView - CBZ/CBR, zoom, guided view
- AudioPlayerView - MP3/M4B, Control Center
- ReaderTopBar - frosted glass. Offline banner when no network.
- ReaderBottomBar - frosted glass, progress, navigation
- ReaderSettingsPanel - theme, font, size, line height
- TranslationPanel - Gemini translation + offline banner + quota display. Unavailable without network.
- NotesPanel - notes and bookmarks
- TOCPanel - table of contents
- CatalogsView / OnlineView - OPDS and online catalogs
- SettingsView - settings + connectors + theme + local copies management
- CloudConnectorView - providers, status, book contentState
- PremiumPaywallView - StoreKit 2 paywall
- MetadataEditorView - title, author, series, tags, genre
- DiagnosticsView - Debug: full log access. Release: export last 100 entries via share sheet.

### Library Organization

#### Folder-Based Collections
- /Books/Fantasy/ -> collection "Fantasy" created automatically
- CollectionManager watches cloud provider folders
- On folder deletion: collection -> .orphaned, books -> isLocalCopy = true, user notified
- Single library for all formats without type separation

#### Metadata and Covers
- Auto-fetch: file -> Google Books -> OpenLibrary
- Covers: Documents/Covers/{bookID}.jpg
- Re-fetch: long press on book card
- Metadata editing in-app

### Cloud Layer
CloudProviderProtocol:
func listFiles(path:) async throws -> [CloudFile]
func download(file:to:) async throws
func upload(url:path:) async throws
func delete(file:) async throws
var providerID: String { get }
var status: CloudProviderStatus { get }

- ICloudProvider - NSMetadataQuery + Documents
- WebDAVProvider - PROPFIND/GET, Basic Auth, Keychain
- YandexDiskProvider - WebDAV (webdav.yandex.ru)
- NextcloudProvider - WebDAV (/remote.php/dav/files/user/)
- MailRuProvider - WebDAV (webdav.cloud.mail.ru)
- GoogleDriveProvider - OAuth2 + REST API
- DropboxProvider - OAuth2 + REST API
- OneDriveProvider - OAuth2 + REST API
- SMBProvider - AMSMB2 for SMB2/SMB3. Fallback to SMB1 legacy for old NAS.
  Limitations: NTLM/Guest auth, Kerberos not supported. iOS only.
- CloudProviderManager - registry, activate, status, CloudProviderHealthMonitor
- OAuthManager - PKCE flow via ASWebAuthenticationSession. Never WKWebView.
- WebDAVXMLParser - PROPFIND parser

### Sync Architecture

#### iCloud Sync
- Reading position -> NSUbiquitousKeyValueStore
- Annotations, progress -> CloudKit (CKRecord)
- Settings -> iCloudSettingsStore

#### Conflict Resolution
ConflictResolutionStrategy:
- .lastWriteWins(lamportClock) - reading position
pip install --upgrade httpx httpcore openai skaro- .autoMerge - annotations with delta < 5 minutes between devices
- .userPrompt - annotations with delta > 5 minutes, or one device deleted while other edited

Mechanism:
- Annotation.lamportClock incremented on every mutation
- deviceID in every record
- Clock skew protection: compare by lamportClock, not wall clock
- autoMerge: combine comments with separator

#### Background Sync
- BackgroundSyncTask - BGAppRefreshTask (com.vreader.sync, min 15 minutes)
- CloudKit push notifications (CKSubscription) - instant sync on other device changes
- PendingChangesQueue (SwiftData) - offline changes synced on network restore
- Retry: exponential backoff 1s -> 2s -> 4s -> 8s -> 16s, max 5 attempts
