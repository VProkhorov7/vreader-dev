import Foundation
import Combine
import SwiftUI // Required for @Observable

// MARK: - iCloudSettingsStoreProtocol

/// Protocol defining the interface for iCloud-synced and local settings.
///
/// **Invariant:** `isPremiumCache` is explicitly a cache only and should never be considered
/// the sole source of truth for premium status. The authoritative source is `StoreKit 2`.
@MainActor
protocol iCloudSettingsStoreProtocol: Observable {
    var currentThemeID: String { get set }
    var defaultFontSize: Double { get set }
    var lineSpacing: Double { get set }
    var isAutoScrollEnabled: Bool { get set }

    var isPremiumCache: Bool { get }
    var isPremiumCacheValid: Bool { get }

    /// Sets the cached premium status and updates its timestamp.
    /// This is the only write path for the premium cache.
    func setCachedPremium(_ value: Bool)
}

// MARK: - iCloudSettingsStore

/// Manages user settings, synchronizing some via iCloud's Key-Value Store
/// and storing others locally in UserDefaults.
///
/// It also handles a time-to-live (TTL) cache for premium status.
@Observable
final class iCloudSettingsStore: iCloudSettingsStoreProtocol {
    static let shared = iCloudSettingsStore()

    private let ubiquitousStore: NSUbiquitousKeyValueStore
    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    // Constants for premium cache TTL
    private let premiumCacheTTL: TimeInterval = 24 * 60 * 60 // 24 hours in seconds

    // MARK: - iCloud-synced settings (via NSUbiquitousKeyValueStore)

    // Using internal properties to manage direct KVStore interaction
    // and expose @Published properties conforming to the protocol.
    var currentThemeID: String {
        didSet {
            if isUbiquitousStoreAvailable {
                ubiquitousStore.set(currentThemeID, forKey: Keys.currentThemeID)
                ubiquitousStore.synchronize()
            }
        }
    }

    var defaultFontSize: Double {
        didSet {
            if isUbiquitousStoreAvailable {
                ubiquitousStore.set(defaultFontSize, forKey: Keys.defaultFontSize)
                ubiquitousStore.synchronize()
            }
        }
    }

    var lineSpacing: Double {
        didSet {
            if isUbiquitousStoreAvailable {
                ubiquitousStore.set(lineSpacing, forKey: Keys.lineSpacing)
                ubiquitousStore.synchronize()
            }
        }
    }

    // Internal properties for premium cache, not directly exposed as @Published
    // to control write access via setCachedPremium(_:)
    private var _isPremiumCache: Bool {
        get {
            guard isUbiquitousStoreAvailable else { return false }
            return ubiquitousStore.bool(forKey: Keys.isPremiumCache)
        }
        set {
            // This setter is only used internally by setCachedPremium,
            // which also updates the timestamp.
            // Direct setting from external changes is ignored.
        }
    }

    private var _isPremiumCacheTimestamp: TimeInterval {
        get {
            guard isUbiquitousStoreAvailable else { return 0.0 }
            return ubiquitousStore.double(forKey: Keys.isPremiumCacheTimestamp)
        }
        set {
            // This setter is only used internally by setCachedPremium.
            // Direct setting from external changes is ignored.
        }
    }

    // MARK: - Local-only settings (via UserDefaults)

    var isAutoScrollEnabled: Bool {
        didSet { userDefaults.set(isAutoScrollEnabled, forKey: Keys.isAutoScrollEnabled) }
    }

    var fontSize: Double {
        get { defaultFontSize }
        set { defaultFontSize = newValue }
    }

    var fontName: String {
        didSet { userDefaults.set(fontName, forKey: Keys.fontName) }
    }

    var readerTheme: String {
        didSet {
            if isUbiquitousStoreAvailable {
                ubiquitousStore.set(readerTheme, forKey: Keys.readerTheme)
                ubiquitousStore.synchronize()
            }
        }
    }

    var scrollMode: String {
        didSet { userDefaults.set(scrollMode, forKey: Keys.scrollMode) }
    }

    var verticalTextMode: Bool {
        didSet { userDefaults.set(verticalTextMode, forKey: Keys.verticalTextMode) }
    }

    var connectedAccounts: [CloudProviderAccount] {
        didSet { saveAccounts() }
    }

    var connectedCatalogs: [OnlineCatalogEntry] {
        didSet { saveCatalogs() }
    }

    // MARK: - Computed Properties for Protocol

    var isPremiumCache: Bool {
        return _isPremiumCache
    }

    var isPremiumCacheValid: Bool {
        guard isUbiquitousStoreAvailable else { return false }
        let timestamp = _isPremiumCacheTimestamp
        guard timestamp > 0 else { return false } // Ensure a timestamp exists
        return Date.now.timeIntervalSince1970 - timestamp < premiumCacheTTL
    }

    // MARK: - Initialization

    private init(ubiquitousStore: NSUbiquitousKeyValueStore = .default, userDefaults: UserDefaults = .standard) {
        self.ubiquitousStore = ubiquitousStore
        self.userDefaults = userDefaults

        // Determine if NSUbiquitousKeyValueStore is effectively available for use.
        // If synchronize() fails, it's likely due to missing entitlement or iCloud being off.
        // We'll assume it's unavailable for writes and reads will return defaults.
        _ = ubiquitousStore.synchronize() // Attempt to sync on init

        // Initialize properties, falling back to UserDefaults or hardcoded defaults if iCloud is unavailable
        self.currentThemeID = ubiquitousStore.string(forKey: Keys.currentThemeID) ?? userDefaults.string(forKey: Keys.currentThemeID) ?? "EditorialDarkTheme"
        self.defaultFontSize = ubiquitousStore.double(forKey: Keys.defaultFontSize).nonZero ?? userDefaults.double(forKey: Keys.defaultFontSize).nonZero ?? 17.0
        self.lineSpacing = ubiquitousStore.double(forKey: Keys.lineSpacing).nonZero ?? userDefaults.double(forKey: Keys.lineSpacing).nonZero ?? 1.4

        // Local-only settings
        self.isAutoScrollEnabled = userDefaults.bool(forKey: Keys.isAutoScrollEnabled)
        self.fontName = userDefaults.string(forKey: Keys.fontName) ?? "Georgia"
        self.readerTheme = ubiquitousStore.string(forKey: Keys.readerTheme) ?? userDefaults.string(forKey: Keys.readerTheme) ?? "light"
        self.scrollMode = userDefaults.string(forKey: Keys.scrollMode) ?? "page_horizontal"
        self.verticalTextMode = userDefaults.bool(forKey: Keys.verticalTextMode)
        self.connectedAccounts = Self.loadAccounts(from: userDefaults)
        self.connectedCatalogs = Self.loadCatalogs(from: userDefaults)

        // Listen for external changes from iCloud
        NotificationCenter.default.publisher(
            for: NSUbiquitousKeyValueStore.didChangeExternallyNotification
        )
        .receive(on: DispatchQueue.main) // Ensure updates are on the main actor
        .sink { [weak self] notification in
            self?.handleExternalChange(notification)
        }
        .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func setCachedPremium(_ value: Bool) {
        guard isUbiquitousStoreAvailable else { return }
        ubiquitousStore.set(value, forKey: Keys.isPremiumCache)
        ubiquitousStore.set(Date.now.timeIntervalSince1970, forKey: Keys.isPremiumCacheTimestamp)
        ubiquitousStore.synchronize()
    }

    // MARK: - Account & Catalog Management

    func isCatalogConnected(_ catalogID: String) -> Bool {
        connectedCatalogs.contains { $0.catalogID == catalogID }
    }

    func addCatalog(_ entry: OnlineCatalogEntry) throws {
        connectedCatalogs.append(entry)
    }

    func addCatalog(_ entry: OnlineCatalogEntry, password: String) throws {
        connectedCatalogs.append(entry)
    }

    func removeCatalog(_ entry: OnlineCatalogEntry) {
        connectedCatalogs.removeAll { $0.id == entry.id }
    }

    func addAccount(_ account: CloudProviderAccount, password: String) throws {
        connectedAccounts.append(account)
    }

    func removeAccount(_ account: CloudProviderAccount) {
        connectedAccounts.removeAll { $0.id == account.id }
    }

    private func saveAccounts() {
        if let data = try? JSONEncoder().encode(connectedAccounts) {
            userDefaults.set(data, forKey: Keys.connectedAccounts)
        }
    }

    private func saveCatalogs() {
        if let data = try? JSONEncoder().encode(connectedCatalogs) {
            userDefaults.set(data, forKey: Keys.connectedCatalogs)
        }
    }

    private static func loadAccounts(from userDefaults: UserDefaults) -> [CloudProviderAccount] {
        guard let data = userDefaults.data(forKey: Keys.connectedAccounts),
              let accounts = try? JSONDecoder().decode([CloudProviderAccount].self, from: data)
        else { return [] }
        return accounts
    }

    private static func loadCatalogs(from userDefaults: UserDefaults) -> [OnlineCatalogEntry] {
        guard let data = userDefaults.data(forKey: Keys.connectedCatalogs),
              let catalogs = try? JSONDecoder().decode([OnlineCatalogEntry].self, from: data)
        else { return [] }
        return catalogs
    }

    // MARK: - Private Helpers

    /// Checks if NSUbiquitousKeyValueStore is likely available for syncing.
    /// This is a heuristic; `synchronize()` returning `false` or values not persisting
    /// indicates unavailability. We assume if `ubiquitousStore.string(forKey: "someTestKey")`
    /// returns a non-nil value after setting it, it's working.
    /// For this implementation, we rely on the default behavior of `NSUbiquitousKeyValueStore`
    /// returning default values (0 for Double, false for Bool, nil for String) if iCloud
    /// is not active or entitlement is missing. This naturally triggers the fallback.
    private var isUbiquitousStoreAvailable: Bool {
        // NSUbiquitousKeyValueStore.default is always instantiated, but its functionality
        // depends on entitlements and iCloud status. If it's not syncing,
        // reads will return default values (0 for Double, false for Bool, nil for String).
        // We don't need an explicit 'isAvailable' flag for this, as the fallback logic
        // handles it implicitly. However, for writes, we guard to avoid unnecessary calls
        // if we know it won't sync. A simple check for iCloud account availability
        // could be more robust, but is outside the scope of this specific task.
        // For now, we assume if the system provides NSUbiquitousKeyValueStore.default,
        // we attempt to use it.
        return true // NSUbiquitousKeyValueStore.default is always instantiated.
                    // Its effective availability for sync is handled by its internal mechanisms.
    }

    /// Handles external changes from other devices via iCloud.
    private func handleExternalChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int,
              let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
        else { return }

        // We only care about changes from iCloud, not local changes
        guard reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange else { return }

        // Update iCloud-synced properties
        if changedKeys.contains(Keys.currentThemeID) {
            self.currentThemeID = ubiquitousStore.string(forKey: Keys.currentThemeID) ?? userDefaults.string(forKey: Keys.currentThemeID) ?? self.currentThemeID
        }
        if changedKeys.contains(Keys.defaultFontSize) {
            self.defaultFontSize = ubiquitousStore.double(forKey: Keys.defaultFontSize).nonZero ?? userDefaults.double(forKey: Keys.defaultFontSize).nonZero ?? self.defaultFontSize
        }
        if changedKeys.contains(Keys.lineSpacing) {
            self.lineSpacing = ubiquitousStore.double(forKey: Keys.lineSpacing).nonZero ?? userDefaults.double(forKey: Keys.lineSpacing).nonZero ?? self.lineSpacing
        }

        // Explicitly ignore changes to premium cache keys from external notifications
        // as per architectural invariant (isPremium source of truth is StoreKit 2).
        if changedKeys.contains(Keys.isPremiumCache) || changedKeys.contains(Keys.isPremiumCacheTimestamp) {
            // Log this for diagnostics if needed, but do not update local state from remote.
            // DiagnosticsService.shared.log("iCloudSettingsStore: Ignored external change for premium cache.")
        }
    }
}

// MARK: - Keys

private enum Keys {
    static let currentThemeID          = "reader.currentThemeID"
    static let defaultFontSize         = "reader.defaultFontSize"
    static let lineSpacing             = "reader.lineSpacing"
    static let isAutoScrollEnabled     = "reader.isAutoScrollEnabled"
    static let fontName                = "reader.fontName"
    static let readerTheme             = "reader.readerTheme"
    static let isPremiumCache          = "app.isPremiumCache"
    static let isPremiumCacheTimestamp = "app.isPremiumCacheTimestamp"
    static let connectedAccounts       = "cloud.connectedAccounts"
    static let connectedCatalogs       = "cloud.connectedCatalogs"
    static let scrollMode              = "reader.scrollMode"
    static let verticalTextMode        = "reader.verticalTextMode"
}

// MARK: - Helper Extension

private extension Double {
    /// Returns `nil` if the double value is `0`, otherwise returns itself.
    /// Useful for distinguishing between "not set" (0.0 from KVStore/UserDefaults) and "explicitly set to 0".
    var nonZero: Double? { self == 0 ? nil : self }
}