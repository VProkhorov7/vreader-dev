import Testing
import Foundation
@testable import Vreader

struct VreaderTests {

    @Test func example() async throws {
    }
}

// MARK: - ThemeStore Tests

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