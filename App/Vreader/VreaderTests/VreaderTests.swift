import Testing
import Foundation
@testable import Vreader

struct VreaderTests {

    @Test func example() async throws {
    }
}

struct KeychainManagerTests {

    private func uniqueKey(_ base: String) -> String {
        "\(base).\(UUID().uuidString)"
    }

    @Test func testSaveAndLoadString() async throws {
        let km = KeychainManager()
        let key = uniqueKey("testSaveAndLoadString")
        let value = "hello-keychain"
        defer { try? await km.delete(key: key) }

        try await km.save(key: key, value: value)
        let loaded: String = try await km.load(key: key)
        #expect(loaded == value)
    }

    @Test func testSaveAndLoadData() async throws {
        let km = KeychainManager()
        let key = uniqueKey("testSaveAndLoadData")
        let original = Data([0xDE, 0xAD, 0xBE, 0xEF, 0x00, 0xFF])
        defer { try? await km.delete(key: key) }

        try await km.save(key: key, data: original)
        let loaded: Data = try await km.load(key: key)
        #expect(loaded == original)
    }

    @Test func testDeleteString() async throws {
        let km = KeychainManager()
        let key = uniqueKey("testDeleteString")

        try await km.save(key: key, value: "to-be-deleted")
        try await km.delete(key: key)
        let exists = await km.exists(key: key)
        #expect(exists == false)
    }

    @Test func testDeleteData() async throws {
        let km = KeychainManager()
        let key = uniqueKey("testDeleteData")

        try await km.save(key: key, data: Data([0x01, 0x02]))
        let strAccount = "dat:\(key)"
        _ = strAccount
        try await km.delete(key: key)
        let exists = await km.exists(key: key)
        #expect(exists == false)
    }

    @Test func testLoadMissingKeyThrows() async throws {
        let km = KeychainManager()
        let key = uniqueKey("testLoadMissingKey")

        do {
            let _: String = try await km.load(key: key)
            Issue.record("Expected throw but load succeeded")
        } catch let error as AppError {
            #expect(error.code == .auth(.credentialsMissing))
        } catch {
            Issue.record("Expected AppError but got \(error)")
        }
    }

    @Test func testStringAndDataNoCollision() async throws {
        let km = KeychainManager()
        let key = uniqueKey("testNoCollision")
        let stringValue = "string-value"
        let dataValue = Data([0xAA, 0xBB, 0xCC])
        defer {
            Task { try? await km.delete(key: key) }
        }

        try await km.save(key: key, value: stringValue)
        try await km.save(key: key, data: dataValue)

        let loadedString: String = try await km.load(key: key)
        let loadedData: Data = try await km.load(key: key)

        #expect(loadedString == stringValue)
        #expect(loadedData == dataValue)
    }

    @Test func testAccessGroupInit() async throws {
        let km = KeychainManager(accessGroup: "com.vreader.shared")
        #expect(km != nil)
    }

    @Test func testOAuthKeyIsSynchronizable() {
        #expect(KeychainKey.googleDriveAccessToken.isSynchronizable == true)
        #expect(KeychainKey.googleDriveRefreshToken.isSynchronizable == true)
        #expect(KeychainKey.dropboxAccessToken.isSynchronizable == true)
        #expect(KeychainKey.dropboxRefreshToken.isSynchronizable == true)
        #expect(KeychainKey.oneDriveAccessToken.isSynchronizable == true)
        #expect(KeychainKey.oneDriveRefreshToken.isSynchronizable == true)
    }

    @Test func testNonOAuthKeyNotSynchronizable() {
        #expect(KeychainKey.geminiAPIKey.isSynchronizable == false)
        #expect(KeychainKey.webDAVPassword(host: "example.com").isSynchronizable == false)
        #expect(KeychainKey.smbPassword(host: "nas.local").isSynchronizable == false)
    }

    @Test func testWebDAVPasswordRawValue() {
        let host = "nas.local"
        let key1 = KeychainKey.webDAVPassword(host: host)
        let key2 = KeychainKey.webDAVPassword(host: host)
        let keyOther = KeychainKey.webDAVPassword(host: "other.host")

        #expect(key1.rawValue == key2.rawValue)
        #expect(key1.rawValue != keyOther.rawValue)
        #expect(key1.rawValue == "webDAVPassword.nas.local")
    }

    @Test func testTypedOverloadDelegatesToRaw() async throws {
        let km = KeychainManager()
        let value = "my-gemini-api-key"
        defer { Task { try? await km.delete(key: KeychainKey.geminiAPIKey) } }

        try await km.save(key: KeychainKey.geminiAPIKey, value: value)

        let rawLoaded: String = try await km.load(key: "geminiAPIKey")
        #expect(rawLoaded == value)
    }

    @Test func testOverwriteExistingKey() async throws {
        let km = KeychainManager()
        let key = uniqueKey("testOverwrite")
        let firstValue = "first-value"
        let secondValue = "second-value"
        defer { Task { try? await km.delete(key: key) } }

        try await km.save(key: key, value: firstValue)
        try await km.save(key: key, value: secondValue)

        let loaded: String = try await km.load(key: key)
        #expect(loaded == secondValue)
    }
}

struct ThemeStoreTests {

    private func makeStore(userDefaults: UserDefaults) -> ThemeStore {
        ThemeStore(userDefaults: userDefaults)
    }

    private func freshDefaults() -> UserDefaults {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return defaults
    }

    @Test func availableThemesAlwaysReturnsFour() {
        let store = ThemeStore(userDefaults: freshDefaults())
        #expect(store.availableThemes.count == 4)
    }

    @Test func availableThemesContainsAllIDs() {
        let store = ThemeStore(userDefaults: freshDefaults())
        let ids = store.availableThemes.map { $0.id }
        #expect(ids.contains(.editorialDark))
        #expect(ids.contains(.curatorLight))
        #expect(ids.contains(.neuralLink))
        #expect(ids.contains(.typewriter))
    }

    @Test func defaultThemeIsEditorialDark() {
        let store = ThemeStore(userDefaults: freshDefaults())
        #expect(store.currentThemeID == .editorialDark)
    }

    @Test func setFreeThemeSucceedsForFreeUser() throws {
        let store = ThemeStore(userDefaults: freshDefaults())
        try store.setTheme(.curatorLight, isPremiumUser: false)
        #expect(store.currentThemeID == .curatorLight)
    }

    @Test func setPremiumThemeThrowsForFreeUser() {
        let store = ThemeStore(userDefaults: freshDefaults())
        var didThrow = false
        do {
            try store.setTheme(.neuralLink, isPremiumUser: false)
        } catch AppThemeError.premiumRequired {
            didThrow = true
        } catch {
            didThrow = false
        }
        #expect(didThrow)
    }

    @Test func setPremiumThemeSucceedsForPremiumUser() throws {
        let store = ThemeStore(userDefaults: freshDefaults())
        try store.setTheme(.neuralLink, isPremiumUser: true)
        #expect(store.currentThemeID == .neuralLink)
    }

    @Test func setTypewriterThemeThrowsForFreeUser() {
        let store = ThemeStore(userDefaults: freshDefaults())
        var didThrow = false
        do {
            try store.setTheme(.typewriter, isPremiumUser: false)
        } catch AppThemeError.premiumRequired {
            didThrow = true
        } catch {
            didThrow = false
        }
        #expect(didThrow)
    }

    @Test func isUnlockedReturnsTrueForFreeThemes() {
        let store = ThemeStore(userDefaults: freshDefaults())
        #expect(store.isUnlocked(for: .editorialDark, isPremiumUser: false))
        #expect(store.isUnlocked(for: .curatorLight, isPremiumUser: false))
    }

    @Test func isUnlockedReturnsFalseForPremiumThemesWhenFreeUser() {
        let store = ThemeStore(userDefaults: freshDefaults())
        #expect(!store.isUnlocked(for: .neuralLink, isPremiumUser: false))
        #expect(!store.isUnlocked(for: .typewriter, isPremiumUser: false))
    }

    @Test func isUnlockedReturnsTrueForPremiumThemesWhenPremiumUser() {
        let store = ThemeStore(userDefaults: freshDefaults())
        #expect(store.isUnlocked(for: .neuralLink, isPremiumUser: true))
        #expect(store.isUnlocked(for: .typewriter, isPremiumUser: true))
    }

    @Test func currentThemeMatchesCurrentThemeID() throws {
        let store = ThemeStore(userDefaults: freshDefaults())
        try store.setTheme(.curatorLight, isPremiumUser: false)
        #expect(store.currentTheme.id == .curatorLight)
    }

    @Test func currentThemeReturnsCorrectTypeForEachID() throws {
        let store = ThemeStore(userDefaults: freshDefaults())

        try store.setTheme(.editorialDark, isPremiumUser: false)
        #expect(store.currentTheme.id == .editorialDark)
        #expect(!store.currentTheme.isPremium)

        try store.setTheme(.curatorLight, isPremiumUser: false)
        #expect(store.currentTheme.id == .curatorLight)
        #expect(!store.currentTheme.isPremium)

        try store.setTheme(.neuralLink, isPremiumUser: true)
        #expect(store.currentTheme.id == .neuralLink)
        #expect(store.currentTheme.isPremium)

        try store.setTheme(.typewriter, isPremiumUser: true)
        #expect(store.currentTheme.id == .typewriter)
        #expect(store.currentTheme.isPremium)
    }

    @Test func persistenceRoundTrip() throws {
        let defaults = freshDefaults()
        let store1 = ThemeStore(userDefaults: defaults)
        try store1.setTheme(.curatorLight, isPremiumUser: false)

        let store2 = ThemeStore(userDefaults: defaults)
        #expect(store2.currentThemeID == .curatorLight)
    }

    @Test func persistenceRoundTripPremium() throws {
        let defaults = freshDefaults()
        let store1 = ThemeStore(userDefaults: defaults)
        try store1.setTheme(.neuralLink, isPremiumUser: true)

        let store2 = ThemeStore(userDefaults: defaults)
        #expect(store2.currentThemeID == .neuralLink)
    }

    @Test func premiumRequiredErrorHasLocalizedDescription() {
        let error = AppThemeError.premiumRequired
        #expect(!error.localizedDescription.isEmpty)
    }

    @Test func themeIDConformsToExpectedValues() {
        #expect(ThemeID.editorialDark.rawValue == "editorialDark")
        #expect(ThemeID.curatorLight.rawValue == "curatorLight")
        #expect(ThemeID.neuralLink.rawValue == "neuralLink")
        #expect(ThemeID.typewriter.rawValue == "typewriter")
        #expect(ThemeID.allCases.count == 4)
    }

    @Test func themeIDCodableRoundTrip() throws {
        for themeID in ThemeID.allCases {
            let encoded = try JSONEncoder().encode(themeID)
            let decoded = try JSONDecoder().decode(ThemeID.self, from: encoded)
            #expect(decoded == themeID)
        }
    }

    @Test func setPremiumThemeDoesNotChangeIDOnFailure() {
        let store = ThemeStore(userDefaults: freshDefaults())
        let originalID = store.currentThemeID
        do {
            try store.setTheme(.neuralLink, isPremiumUser: false)
        } catch {
        }
        #expect(store.currentThemeID == originalID)
    }
}