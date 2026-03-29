# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VReader is an iOS/iPadOS book reader app built with SwiftUI + SwiftData. It supports multiple book formats and cloud storage providers. The UI aesthetic targets Apple Books × Adobe Creative Cloud (clean white surfaces, SF Pro typography, system blue accent, squircle corners via `.continuous`, `.regularMaterial`/`.ultraThinMaterial` backgrounds).

**No code comments** — this is a deliberate style requirement.

## Building & Running

Open `App/Vreader/Vreader.xcodeproj` in Xcode. Requires iOS 17+ deployment target. Run on a device or simulator.

```bash
# Validate code references before committing
python3 Description/check_refs.py
```

Tests are in `App/Vreader/VreaderTests/` and `App/Vreader/VreaderUITests/` (currently minimal).

## Architecture

### Navigation (5 tabs via custom `VReaderTabBar` in `ContentView`)

- **Home** — triggers `AppState.goHome()` to return to library
- **Library** (`LibraryView`) — book grid/list; downloaded books open `ReaderView` (fullScreenCover), others open `BookDetailView` (sheet) → download → reader
- **Reading** (`ReadingView`) — currently-reading books with progress
- **Catalogs** (`CatalogsView`) — two tabs: OPDS online catalogs + cloud storage accounts
- **Settings** (`SettingsView`)

### State Management

- **`AppState`** (singleton `@Observable`) — `selectedTab`, `currentBook`, `showSettings`; controls global navigation
- **SwiftData `@Query`** — reactive book list in `LibraryView`
- **`iCloudSettingsStore`** wraps `NSUbiquitousKeyValueStore` for cross-device sync of cloud accounts and reader preferences
- **`KeychainManager`** — stores cloud account passwords securely

### Data Model

`Core/Book.swift` — SwiftData `@Model` with properties: id, title, authors, format, progress, source info, etc.
`App/Vreader/Vreader/Book_Computed.swift` — extension with computed properties: `fileURL`, `color`, `formatIcon`, `formatColor`, `sourceLabel`.

**Schema versioning:** `db.schemaVersion` (UserDefaults, currently `2`). On version change the SwiftData store is wiped and rebuilt — see `VreaderApp.swift`.

### Reader Components

`ReaderView.swift` is the universal reader that dispatches to format-specific views:

| Format | View |
|--------|------|
| PDF | `PDFKit` native (embedded in `ReaderView`) |
| EPUB | `EPUBReaderView` (WKWebView) |
| FB2, TXT, RTF, MOBI, AZW3, DJVU | `TextReaderView` |
| CBZ/CBR/CB7/CBT | `ComicReaderView` |
| CHM | `CHMReaderView` |
| MP3, M4A, M4B | `AudioPlayerView` |

**Gesture scheme in `ReaderView`:**
- Center tap → toggle nav/tool bars; swipe down → close
- Top edge (80pt) tap → show bars
- Left edge (44pt) swipe right → show TOC
- Right edge (44pt) swipe left → show settings panel

### Cloud Providers

`CloudProviderProtocol.swift` defines the interface. Implemented in:
- `iCloudProvider.swift` — iCloud Drive (always available)
- `WebDAVProvider.swift` + `WebDAVXMLParser.swift` — Yandex.Disk, Mail.ru Cloud, Nextcloud, generic WebDAV
- SMB — local network shares

`CloudProviderManager.swift` manages active provider instances.
`CoverFetcher.swift` — fetches covers from Open Library / Google Books APIs.
`EPUBParser.swift` — extracts EPUB metadata using ZIPFoundation.

### Key File Locations

```
VReader/
├── Core/                        # Book.swift, ContentSource.swift, ErrorCode.swift, DownloadTask.swift
├── App/Vreader/Vreader/         # All SwiftUI views and supporting files (~40 .swift files)
│   ├── VreaderApp.swift         # Entry point, SwiftData init, schema versioning
│   ├── AppState.swift           # Global navigation state
│   ├── ContentView.swift        # Tab bar root
│   ├── L10n.swift               # Localization strings (Russian UI)
│   └── ...
├── Description/
│   ├── HANDOVER.md              # Detailed project handover in Russian (2000+ lines)
│   └── check_refs.py            # Code validation: duplicate types, unresolved refs, iOS API compat
└── Connectors/, Engines/        # Planned, currently empty
```

### Localization

The app UI is in Russian. All user-visible strings go through `L10n.swift`.
