# VReader — Handover Document
*Дата: 01.03.2026 | Для переноса в новый диалог*

---

## 1. ПРОЕКТ

**Название:** VReader — iOS/iPad книжный ридер  
**Платформа:** iOS 17+ (deployment target), SwiftUI + SwiftData  
**Язык:** Swift, без комментариев в коде (принципиальное требование)

---

## 2. ТЕКУЩЕЕ СОСТОЯНИЕ ФАЙЛОВ

### Принцип работы
Xcode-проект лежит в `/mnt/project/` (read-only).  
Все изменения — в `/mnt/user-data/outputs/`.  
Outputs перекрывают project: если файл есть в outputs — используется он.

### Файлы в outputs (актуальные, заменить в Xcode):
| Файл | Статус | Что делает |
|------|--------|------------|
| `AppState.swift` | ✅ актуален | selectedTab, currentBook, showSettings, goHome() |
| `Book.swift` | в project | SwiftData модель |
| `Book_Computed.swift` | ✅ актуален | computed props: color, fileURL, formatIcon, formattedSize, progressPercent, sourceIcon, sourceLabel, sourceColor, formatLabel, formatColor, isDownloaded, remoteURL |
| `Book_SampleData.swift` | ✅ актуален | пустой массив samples (без тестовых данных) |
| `BookCardView.swift` | ✅ актуален | карточка грид-режима с MetaStrip (FormatTag + SourceTag поверх обложки) |
| `BookDetailView.swift` | ✅ актуален | экран предпросмотра книги: обложка + скачать/читать |
| `CatalogsView.swift` | ✅ актуален | Каталоги + Хранилища (segmented), CatalogRow, AddCloudAccountSheet |
| `ContentView.swift` | ✅ актуален | TabView с VReaderTabBar (custom tab bar, 5 вкладок) |
| `CoverFetcher.swift` | ✅ актуален | загрузка обложек с Open Library / Google Books |
| `EPUBParser.swift` | ✅ актуален | парсинг EPUB через ZIPFoundation |
| `EPUBReaderView.swift` | ✅ актуален | WKWebView ридер для EPUB |
| `LibraryView.swift` | ✅ актуален | грид/список, empty state, роутинг: скачана→Reader, нет→Detail |
| `iCLoudSettingsStore.swift` | ✅ актуален | NSUbiquitousKVStore настройки + CloudProviderAccount + Keychain |
| `ReaderView.swift` | ✅ актуален | универсальный ридер (PDF/EPUB), жесты, панели |
| `ReadingView.swift` | ✅ актуален | вкладка "Читаю" с карточкой текущей книги |
| `VreaderApp.swift` | ✅ актуален | App entry + ModelContainer + schema version reset |

### Файлы только в project (не трогали):
`KeychainManager.swift`, `WebDAVProvider.swift`, `WebDAVXMLParser.swift`,  
`iCloudProvider.swift`, `CloudProviderProtocol.swift`, `CloudProviderManager.swift`,  
`BookImporter.swift`, `ReadingSession.swift`, `ReadingSessionView.swift`,  
`URLSessionTaskDelegate.swift`, `DownloadTask.swift`, `ErrorCode.swift`,  
`SettingsView.swift`, `MainTabView.swift`

---

## 3. АРХИТЕКТУРА

### Навигация (5 вкладок)
```
ContentView (VReaderTabBar)
├── Дом          → AppState.selectedTab = .library (GoHome)
├── Библиотека   → LibraryView
│   ├── (скачана) → ReaderView (fullScreenCover)
│   └── (не скачана) → BookDetailView (sheet)
│       └── (скачать+открыть) → ReaderView (fullScreenCover)
├── Читаю        → MainTabView → ReadingView
│   └── NavigationLink → ReaderView
├── Каталоги     → CatalogsView
│   ├── seg[0] Каталоги    → OnlineCatalogsSection
│   └── seg[1] Хранилища  → CloudStorageSection
│       └── sheet → AddCloudAccountSheet
└── Настройки    → SettingsView
```

### Хранение данных
- **SwiftData** — `Book` модель, персистентное хранилище
- **NSUbiquitousKeyValueStore** — настройки ридера + аккаунты облаков (sync между устройствами)
- **Keychain** — пароли облачных аккаунтов
- **UserDefaults** — `db.schemaVersion` (2), `library.isGrid`

### Schema version
`VreaderApp.swift` хранит `db.schemaVersion = 2`.  
При смене версии база пересоздаётся (чистый старт). Менять при несовместимых изменениях модели.

---

## 4. ОБЛАЧНЫЕ ХРАНИЛИЩА

### CloudProviderType (все case):
| Case | DisplayName | WebDAV URL | Примечание |
|------|-------------|------------|-----------|
| `.iCloudDrive` | iCloud Drive | — | системное, всегда подключено |
| `.yandexDisk` | Яндекс.Диск | `https://webdav.yandex.ru` | нужен App Password из Яндекс ID |
| `.mailru` | Облако Mail.ru | `https://webdav.cloud.mail.ru` | только платный тариф, App Password с правами Почта+Облако+Календарь |
| `.nextcloud` | Nextcloud | `https://your-server/remote.php/dav/files/` | логин/пароль Nextcloud |
| `.webdav` | WebDAV | `https://` | любой сервер (Calibre и др.) |
| `.smb` | SMB / Samba | `smb://192.168.1.` | локальная сеть |
| `.googleDrive` | Google Drive | — | OAuth, не реализован |
| `.dropbox` | Dropbox | — | OAuth, не реализован |
| `.oneDrive` | OneDrive | — | OAuth, не реализован |

### Российские WebDAV провайдеры (итог исследования):
- ✅ **Яндекс.Диск** — работает, нужен App Password
- ✅ **Облако Mail.ru** — работает, только платный тариф, App Password
- ❌ МТС, Сбер, VK — нет нативного WebDAV API

---

## 5. Book — ВСЕ СВОЙСТВА

### SwiftData модель (Book.swift):
`id`, `title`, `author`, `coverData`, `filePath`, `format`, `fileSize`,  
`source`, `addedAt`, `progress`, `lastPage`, `lastOpenedAt`, `isFinished`

### Computed (Book_Computed.swift):
`color`, `fileURL`, `formatIcon`, `formattedSize`, `progressPercent`,  
`sourceIcon`, `sourceLabel`, `sourceColor`, `formatLabel`, `formatColor`,  
`isDownloaded` (FileManager.fileExists), `remoteURL` (URL из filePath если не скачана)

---

## 6. ДИЗАЙН-ПРИНЦИПЫ

- **Стиль:** Apple Books × Adobe Creative Cloud — чистые белые поверхности
- **Типографика:** SF Pro, строгая иерархия размеров
- **Акцент:** один цвет — системный синий (Color.accentColor)
- **Тени:** subtle, purposeful (не декоративные)
- **Фоны:** `.regularMaterial`, `.ultraThinMaterial`
- **Скругления:** `.continuous` style (squircle)
- **Empty states:** кастомные (не ContentUnavailableView напрямую)
- **Иконки:** SF Symbols с `.hierarchical` рендерингом
- **Метаданные книги:** FormatTag + SourceTag встроены в обложку (MetaStrip), не под ней
- Никаких комментариев в коде

---

## 7. СТРУКТУРА КАТАЛОГИ / ХРАНИЛИЩА

### Паттерн (одинаков для обеих вкладок):
```
Секция "Подключённые" (сверху)  — green checkmark справа
  iCloud Drive (всегда)
  [добавленные аккаунты, swipe-to-delete]

Секция "Доступные" (снизу)  — plus.circle справа, tap → форма
  [список незаполненных провайдеров]
```

---

## 8. ВАЛИДАЦИОННЫЙ СКРИПТ

**Файл:** `/mnt/user-data/outputs/check_refs.py`  
**Запуск:** `python3 /mnt/user-data/outputs/check_refs.py`  

### Что проверяет:
1. **Дубликаты типов** — struct/class/enum с одинаковым именем в разных файлах
2. **Неразрешённые типы** — ссылки на типы не определённые нигде в проекте
3. **book.\* свойства** — использование несуществующих свойств Book в View-файлах
4. **AppState члены** — var/func которых нет в AppState.swift
5. **Баланс скобок** — { vs }
6. **iOS API совместимость** — deployment target iOS 17, таблица ~30 API с версиями

### Правила публикации (ОБЯЗАТЕЛЬНО):
```
❶ Перед present_files — всегда запустить check_refs.py
❷ Если скрипт падает — сначала чинить, потом публиковать
❸ Зависимые файлы публиковать вместе (например BookDetailView + Book_Computed)
❹ Никогда не публиковать один файл если он вводит новые свойства/типы в другие файлы
```

### Известные ложные срабатывания скрипта:
- `Coordinator` — nested класс внутри UIViewRepresentable, не конфликт
- `book.*` в `EPUBParser.swift` — там `book: EPUBBook`, не `Book`
- `var displayName` в `CloudProviderType` — скрипт находит первое вхождение в struct, реальное в enum дальше

---

## 9. НЕРЕШЁННЫЕ ЗАДАЧИ / СЛЕДУЮЩИЕ ШАГИ

### В этом диалоге обсуждалось, но не закончено:
- **Формы входа в Каталоги** (не работают) — онлайн каталоги типа Флибуста, OPDS должны иметь форму подключения
- **Формы входа в Хранилища** — `AddCloudAccountSheet` сделан, тестирование не завершено
- Тема для нового диалога: **подключение к серверам** (OPDS, WebDAV, SMB)

### Технический долг:
- `EPUBReaderView` — координатор с жестами (`UIPanGestureRecognizer`)
- `CoverFetcher` — rate limiting, кэширование
- `ReadingView` — прогресс только из SwiftData, реальная синхронизация с EPUB/PDF не настроена

---

## 10. КОНТЕКСТ ДЛЯ НОВОГО ДИАЛОГА

При старте нового диалога передать:
1. Этот файл целиком
2. `check_refs.py` (валидация)
3. Конкретный вопрос по серверам

**Ключевые договорённости:**
- Проверка взаимосвязей через check_refs.py ПЕРЕД каждым present_files — без исключений
- Зависимые файлы публиковать одним пакетом
- Deployment target iOS 17
- Без комментариев в коде
- Скрипт запускается в `/mnt/user-data/outputs/`
