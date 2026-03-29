import Foundation
import SwiftUI

// MARK: - Как работает локализация в VReader
//
// iOS автоматически выбирает язык на основе Settings → Language.
// Никакого кода для определения языка не нужно — это делает система.
//
// Структура файлов:
//   ru.lproj/Localizable.strings  ← русский (основной)
//   en.lproj/Localizable.strings  ← английский
//
// В SwiftUI Text("some.key") автоматически ищет ключ в Localizable.strings.
// Для динамических строк — String(localized: "key") или L10n.key.
//
// Чтобы добавить новый язык — создать папку xx.lproj и скопировать .strings.

// MARK: - L10n namespace

enum L10n {

    // MARK: Tabs
    enum Tab {
        static let library  = String(localized: "tab.library",  defaultValue: "Библиотека")
        static let reading  = String(localized: "tab.reading",  defaultValue: "Читаю")
        static let catalogs = String(localized: "tab.catalogs", defaultValue: "Каталоги")
        static let settings = String(localized: "tab.settings", defaultValue: "Настройки")
        static let home     = String(localized: "tab.home",     defaultValue: "Дом")
    }

    // MARK: Library
    enum Library {
        static let title         = String(localized: "library.title",         defaultValue: "Библиотека")
        static let emptyTitle    = String(localized: "library.empty.title",   defaultValue: "Библиотека пуста")
        static let emptyMessage  = String(localized: "library.empty.message", defaultValue: "Добавьте книги с устройства\nили подключите облачное хранилище")
        static let addBook       = String(localized: "library.add_book",      defaultValue: "Добавить книгу")
        static let delete        = String(localized: "library.delete",        defaultValue: "Удалить")
        static let fromDevice    = String(localized: "library.from_device",   defaultValue: "С устройства / iCloud Drive")
        static let chooseSource  = String(localized: "library.choose_source", defaultValue: "Выберите источник")
    }

    // MARK: Reader
    enum Reader {
        static let contents        = String(localized: "reader.contents",          defaultValue: "Содержание")
        static let appearance      = String(localized: "reader.appearance",        defaultValue: "Оформление")
        static let theme           = String(localized: "reader.theme",             defaultValue: "Тема")
        static let fontSize        = String(localized: "reader.font_size",         defaultValue: "Размер текста")
        static let lineSpacing     = String(localized: "reader.line_spacing",      defaultValue: "Межстрочный интервал")
        static let scrollMode      = String(localized: "reader.scroll_mode",       defaultValue: "Режим листания")
        static let languageScript  = String(localized: "reader.language_script",   defaultValue: "Язык / направление")
        static let verticalText    = String(localized: "reader.vertical_text",     defaultValue: "Вертикальный текст")
        static let verticalTextHint = String(localized: "reader.vertical_text.hint", defaultValue: "Для китайского, японского")
        static let rtlHint           = String(localized: "reader.rtl_hint",            defaultValue: "Направление (RTL) для арабского определяется автоматически")
        static let unsupportedFormats = String(localized: "reader.unsupported_formats", defaultValue: "Поддерживаемые форматы: PDF, EPUB, FB2, TXT, RTF, CBZ, CBR, MP3, M4B")

        enum Theme {
            static let light = String(localized: "reader.theme.light", defaultValue: "Светлая")
            static let sepia = String(localized: "reader.theme.sepia", defaultValue: "Сепия")
            static let dark  = String(localized: "reader.theme.dark",  defaultValue: "Тёмная")
        }

        enum Scroll {
            static let pageHorizontal   = String(localized: "reader.scroll.page_h",     defaultValue: "Страницами →")
            static let scrollVertical   = String(localized: "reader.scroll.vertical",   defaultValue: "Полотно ↕")
            static let scrollHorizontal = String(localized: "reader.scroll.horizontal", defaultValue: "Полотно →")
        }

        enum Spacing {
            static let narrow  = String(localized: "reader.spacing.narrow",  defaultValue: "Узкий")
            static let medium  = String(localized: "reader.spacing.medium",  defaultValue: "Средний")
            static let wide    = String(localized: "reader.spacing.wide",    defaultValue: "Широкий")
        }

        static let read          = String(localized: "reader.read",          defaultValue: "Читать")
        static let continueRead  = String(localized: "reader.continue",      defaultValue: "Продолжить чтение")
        static let notDownloaded = String(localized: "reader.not_downloaded",defaultValue: "Книга не скачана")
        static let download      = String(localized: "reader.download",      defaultValue: "Скачать")
        static let finished      = String(localized: "reader.finished",      defaultValue: "Прочитано")
        static let beginning     = String(localized: "reader.beginning",     defaultValue: "Начало")
        static let end           = String(localized: "reader.end",           defaultValue: "Конец")
        static let chapters      = String(localized: "reader.chapters",      defaultValue: "Главы")
        static let chapter       = String(localized: "reader.chapter",       defaultValue: "Глава")
        static let inProgress    = String(localized: "reader.in_progress",   defaultValue: "В процессе")
    }

    // MARK: Settings
    enum Settings {
        static let title        = String(localized: "settings.title",         defaultValue: "Настройки")
        static let appearance   = String(localized: "settings.appearance",    defaultValue: "Оформление")
        static let font         = String(localized: "settings.font",          defaultValue: "Шрифт")
        static let fontPicker   = String(localized: "settings.font_picker",   defaultValue: "Выбор шрифта")
        static let fontSize     = String(localized: "settings.font_size",     defaultValue: "Размер шрифта")
        static let storage      = String(localized: "settings.storage",       defaultValue: "Хранилища")
        static let cloud        = String(localized: "settings.cloud",         defaultValue: "Добавить хранилище")
        static let sync         = String(localized: "settings.sync",          defaultValue: "Синхронизация")
        static let syncDetail   = String(localized: "settings.sync.detail",   defaultValue: "Прогресс и закладки синхронизируются через iCloud")
        static let ai           = String(localized: "settings.ai",            defaultValue: "Искусственный интеллект")
        static let aiSoon       = String(localized: "settings.ai.soon",       defaultValue: "ИИ-функции (скоро)")
        static let app          = String(localized: "settings.app",           defaultValue: "Приложение")
        static let version      = String(localized: "settings.version",       defaultValue: "Версия")
        static let feedback     = String(localized: "settings.feedback",      defaultValue: "Написать в поддержку")
        static let review       = String(localized: "settings.review",        defaultValue: "Оставить отзыв")
        static let dev          = String(localized: "settings.dev",           defaultValue: "Разработка")
    }

    // MARK: Comic
    enum Comic {
        static let opening      = String(localized: "comic.opening",        defaultValue: "Открываю...")
        static let noImages     = String(localized: "comic.no_images",      defaultValue: "Изображения не найдены")
        static let fileNotFound = String(localized: "comic.file_not_found", defaultValue: "Файл не найден")
        static let cbtPending   = String(localized: "comic.cbt_pending",    defaultValue: "Формат CBT (TAR) будет поддержан в следующем обновлении.")
        static let cbrNoLib     = String(localized: "comic.cbr_no_lib",     defaultValue: "требует библиотеку UnRAR. Пока поддерживается только CBZ. Конвертируйте архив с помощью Calibre.")
        static let archiveError = String(localized: "comic.archive_error",  defaultValue: "Не удалось открыть архив: ")
    }

    // MARK: Audio
    enum Audio {
        static let chapters = String(localized: "audio.chapters", defaultValue: "Главы")
        static let noFile   = String(localized: "audio.no_file",  defaultValue: "Файл не найден")
    }

    // MARK: CHM
    enum CHM {
        static let title         = String(localized: "chm.title",          defaultValue: "CHM — дань олдам")
        static let fileNotFound  = String(localized: "chm.not_found",      defaultValue: "Файл не найден")
        static let notDownloaded = String(localized: "chm.not_downloaded", defaultValue: "Файл не скачан")
    }

    // MARK: Catalogs
    enum Catalogs {
        static let title      = String(localized: "catalogs.title",       defaultValue: "Каталоги")
        static let storage    = String(localized: "catalogs.storage",     defaultValue: "Хранилища")
        static let free       = String(localized: "catalogs.free",        defaultValue: "Бесплатные")
        static let connected  = String(localized: "catalogs.connected",   defaultValue: "Подключённые")
        static let available  = String(localized: "catalogs.available",   defaultValue: "Доступные")
        static let disconnect = String(localized: "catalogs.disconnect",  defaultValue: "Отключить")
        static let connect    = String(localized: "catalogs.connect",     defaultValue: "Подключить")
        static let stores     = String(localized: "catalogs.stores",      defaultValue: "Магазины")
        static let comingSoon = String(localized: "catalogs.coming_soon", defaultValue: "Скоро")
        static let builtin    = String(localized: "catalogs.builtin",     defaultValue: "Встроено в систему")

        enum OPDS {
            static let addTitle        = String(localized: "opds.add_title",   defaultValue: "Добавить OPDS")
            static let catalog         = String(localized: "opds.catalog",     defaultValue: "Каталог")
            static let namePlaceholder = String(localized: "opds.name_ph",     defaultValue: "Название (например, Calibre Home)")
            static let urlPlaceholder  = String(localized: "opds.url_ph",      defaultValue: "Адрес OPDS")
            static let urlHint         = String(localized: "opds.url_hint",    defaultValue: "Адрес должен оканчиваться на /opds или /opds/v1.2")
            static let authSection     = String(localized: "opds.auth",        defaultValue: "Авторизация (если требуется)")
            static let serverOk        = String(localized: "opds.server_ok",   defaultValue: "OPDS-сервер отвечает")
            static let serverFail      = String(localized: "opds.server_fail", defaultValue: "Не удалось подключиться")
        }

        enum CloudForm {
            static let addTitle   = String(localized: "cloud_form.add_title",  defaultValue: "Добавить хранилище")
            static let service    = String(localized: "cloud_form.service",    defaultValue: "Сервис")
            static let type_      = String(localized: "cloud_form.type",       defaultValue: "Тип")
            static let connection = String(localized: "cloud_form.connection", defaultValue: "Подключение")
            static let serverAddr = String(localized: "cloud_form.server",     defaultValue: "Адрес сервера")
            static let login      = String(localized: "cloud_form.login",      defaultValue: "Логин")
            static let password   = String(localized: "cloud_form.password",   defaultValue: "Пароль")
            static let test       = String(localized: "cloud_form.test",       defaultValue: "Проверить соединение")
            static let testing    = String(localized: "cloud_form.testing",    defaultValue: "Проверяю...")
            static let testOk     = String(localized: "cloud_form.test_ok",    defaultValue: "Соединение успешно")
            static let testFail   = String(localized: "cloud_form.test_fail",  defaultValue: "Ошибка подключения")
        }
    }

    // MARK: Common
    enum Common {
        static let cancel  = String(localized: "common.cancel",  defaultValue: "Отмена")
        static let done    = String(localized: "common.done",     defaultValue: "Готово")
        static let back    = String(localized: "common.back",     defaultValue: "Назад")
        static let error   = String(localized: "common.error",    defaultValue: "Ошибка")
        static let reading = String(localized: "common.reading",  defaultValue: "Чтение")
        static let add     = String(localized: "common.add",      defaultValue: "Добавить")
        static let delete  = String(localized: "common.delete",   defaultValue: "Удалить")
    }
}

// MARK: - LocalizedStringKey helpers для SwiftUI Text

extension Text {
    init(l10n key: String, defaultValue: String) {
        self.init(verbatim: NSLocalizedString(key, value: defaultValue, comment: ""))
    }
}
