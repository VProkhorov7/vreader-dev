import Foundation

enum L10n {

    enum Library {
        static var title: String { NSLocalizedString("library.title", comment: "") }
        static var searchPlaceholder: String { NSLocalizedString("library.searchPlaceholder", comment: "") }
        static var emptyState: String { NSLocalizedString("library.emptyState", comment: "") }
        static var addBook: String { NSLocalizedString("library.addBook", comment: "") }
        static var sortBy: String { NSLocalizedString("library.sortBy", comment: "") }
        static var filterBy: String { NSLocalizedString("library.filterBy", comment: "") }
        static var collections: String { NSLocalizedString("library.collections", comment: "") }
        static var favorites: String { NSLocalizedString("library.favorites", comment: "") }
        static var allBooks: String { NSLocalizedString("library.allBooks", comment: "") }
        static var recentlyRead: String { NSLocalizedString("library.recentlyRead", comment: "") }
    }

    enum Reader {
        static var continueReading: String { NSLocalizedString("reader.continueReading", comment: "") }
        static var chapter: String { NSLocalizedString("reader.chapter", comment: "") }
        static var page: String { NSLocalizedString("reader.page", comment: "") }
        static var of: String { NSLocalizedString("reader.of", comment: "") }
        static var translate: String { NSLocalizedString("reader.translate", comment: "") }
        static var tts: String { NSLocalizedString("reader.tts", comment: "") }
        static var notes: String { NSLocalizedString("reader.notes", comment: "") }
        static var bookmarks: String { NSLocalizedString("reader.bookmarks", comment: "") }
        static var toc: String { NSLocalizedString("reader.toc", comment: "") }
        static var settings: String { NSLocalizedString("reader.settings", comment: "") }
        static var share: String { NSLocalizedString("reader.share", comment: "") }
        static var close: String { NSLocalizedString("reader.close", comment: "") }
        static var nextChapter: String { NSLocalizedString("reader.nextChapter", comment: "") }
        static var prevChapter: String { NSLocalizedString("reader.prevChapter", comment: "") }

        static func pageOf(current: Int, total: Int) -> String {
            String(format: NSLocalizedString("reader.pageOf", comment: ""), current, total)
        }
    }

    enum Settings {
        static var title: String { NSLocalizedString("settings.title", comment: "") }
        static var theme: String { NSLocalizedString("settings.theme", comment: "") }
        static var font: String { NSLocalizedString("settings.font", comment: "") }
        static var fontSize: String { NSLocalizedString("settings.fontSize", comment: "") }
        static var lineSpacing: String { NSLocalizedString("settings.lineSpacing", comment: "") }
        static var language: String { NSLocalizedString("settings.language", comment: "") }
        static var cloud: String { NSLocalizedString("settings.cloud", comment: "") }
        static var premium: String { NSLocalizedString("settings.premium", comment: "") }
        static var diagnostics: String { NSLocalizedString("settings.diagnostics", comment: "") }
        static var about: String { NSLocalizedString("settings.about", comment: "") }
        static var version: String { NSLocalizedString("settings.version", comment: "") }
        static var resetSettings: String { NSLocalizedString("settings.resetSettings", comment: "") }
    }

    enum Cloud {
        static var title: String { NSLocalizedString("cloud.title", comment: "") }
        static var connect: String { NSLocalizedString("cloud.connect", comment: "") }
        static var disconnect: String { NSLocalizedString("cloud.disconnect", comment: "") }
        static var sync: String { NSLocalizedString("cloud.sync", comment: "") }
        static var lastSync: String { NSLocalizedString("cloud.lastSync", comment: "") }
        static var providers: String { NSLocalizedString("cloud.providers", comment: "") }
        static var icloud: String { NSLocalizedString("cloud.icloud", comment: "") }
        static var webdav: String { NSLocalizedString("cloud.webdav", comment: "") }
        static var yandex: String { NSLocalizedString("cloud.yandex", comment: "") }
        static var nextcloud: String { NSLocalizedString("cloud.nextcloud", comment: "") }
        static var mailru: String { NSLocalizedString("cloud.mailru", comment: "") }
        static var google: String { NSLocalizedString("cloud.google", comment: "") }
        static var dropbox: String { NSLocalizedString("cloud.dropbox", comment: "") }
        static var onedrive: String { NSLocalizedString("cloud.onedrive", comment: "") }
        static var smb: String { NSLocalizedString("cloud.smb", comment: "") }
        static var downloading: String { NSLocalizedString("cloud.downloading", comment: "") }
        static var downloaded: String { NSLocalizedString("cloud.downloaded", comment: "") }
        static var cloudOnly: String { NSLocalizedString("cloud.cloudOnly", comment: "") }
        static var previewed: String { NSLocalizedString("cloud.previewed", comment: "") }
    }

    enum AI {
        static var translate: String { NSLocalizedString("ai.translate", comment: "") }
        static var summary: String { NSLocalizedString("ai.summary", comment: "") }
        static var xray: String { NSLocalizedString("ai.xray", comment: "") }
        static var dictionary: String { NSLocalizedString("ai.dictionary", comment: "") }
        static var tts: String { NSLocalizedString("ai.tts", comment: "") }
        static var quota: String { NSLocalizedString("ai.quota", comment: "") }
        static var quotaUsed: String { NSLocalizedString("ai.quotaUsed", comment: "") }
        static var offline: String { NSLocalizedString("ai.offline", comment: "") }
        static var premiumRequired: String { NSLocalizedString("ai.premiumRequired", comment: "") }
        static var translating: String { NSLocalizedString("ai.translating", comment: "") }
        static var generating: String { NSLocalizedString("ai.generating", comment: "") }
    }

    enum Premium {
        static var title: String { NSLocalizedString("premium.title", comment: "") }
        static var subtitle: String { NSLocalizedString("premium.subtitle", comment: "") }
        static var monthly: String { NSLocalizedString("premium.monthly", comment: "") }
        static var lifetime: String { NSLocalizedString("premium.lifetime", comment: "") }
        static var restore: String { NSLocalizedString("premium.restore", comment: "") }
        static var features: String { NSLocalizedString("premium.features", comment: "") }
        static var unlockThemes: String { NSLocalizedString("premium.unlockThemes", comment: "") }
        static var unlockCloud: String { NSLocalizedString("premium.unlockCloud", comment: "") }
        static var unlockAI: String { NSLocalizedString("premium.unlockAI", comment: "") }
        static var unlockTTS: String { NSLocalizedString("premium.unlockTTS", comment: "") }
    }

    enum Common {
        static var ok: String { NSLocalizedString("common.ok", comment: "") }
        static var cancel: String { NSLocalizedString("common.cancel", comment: "") }
        static var delete: String { NSLocalizedString("common.delete", comment: "") }
        static var edit: String { NSLocalizedString("common.edit", comment: "") }
        static var save: String { NSLocalizedString("common.save", comment: "") }
        static var close: String { NSLocalizedString("common.close", comment: "") }
        static var retry: String { NSLocalizedString("common.retry", comment: "") }
        static var loading: String { NSLocalizedString("common.loading", comment: "") }
        static var error: String { NSLocalizedString("common.error", comment: "") }
        static var success: String { NSLocalizedString("common.success", comment: "") }
        static var warning: String { NSLocalizedString("common.warning", comment: "") }
        static var unknown: String { NSLocalizedString("common.unknown", comment: "") }
    }

    enum Errors {
        static var fileNotFound: String { NSLocalizedString("errors.fileNotFound", comment: "") }
        static var networkOffline: String { NSLocalizedString("errors.networkOffline", comment: "") }
        static var cloudProviderError: String { NSLocalizedString("errors.cloudProviderError", comment: "") }
        static var aiServiceError: String { NSLocalizedString("errors.aiServiceError", comment: "") }
        static var premiumRequired: String { NSLocalizedString("errors.premiumRequired", comment: "") }
        static var syncFailed: String { NSLocalizedString("errors.syncFailed", comment: "") }
        static var parsingFailed: String { NSLocalizedString("errors.parsingFailed", comment: "") }
    }

    enum Onboarding {
        static var title: String { NSLocalizedString("onboarding.title", comment: "") }
        static var subtitle: String { NSLocalizedString("onboarding.subtitle", comment: "") }
        static var addFirstBook: String { NSLocalizedString("onboarding.addFirstBook", comment: "") }
        static var connectCloud: String { NSLocalizedString("onboarding.connectCloud", comment: "") }
        static var skip: String { NSLocalizedString("onboarding.skip", comment: "") }
        static var getStarted: String { NSLocalizedString("onboarding.getStarted", comment: "") }
    }
}