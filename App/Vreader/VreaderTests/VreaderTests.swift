import Testing
import Foundation
@testable import Vreader

// MARK: - Actor boundary helper

private actor ErrorReceiver {
    private(set) var received: AppError?

    func receive(_ error: AppError) {
        received = error
    }

    func storedCode() -> ErrorCode? {
        received?.code
    }
}

// MARK: - ThemeStore Tests (preserved from Stage 1)

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

// MARK: - AppError Factory Method Tests

struct AppErrorFactoryTests {

    @Test func fileNotFoundProducesCorrectCode() {
        let error = AppError.fileNotFound(path: "/some/path/book.epub")
        #expect(error.code == .fileSystem(.fileNotFound))
    }

    @Test func fileNotFoundDescriptionIsNonEmpty() {
        let error = AppError.fileNotFound(path: "/some/path/book.epub")
        #expect(!error.description.isEmpty)
    }

    @Test func fileNotFoundRecoveryHintIsNonEmpty() {
        let error = AppError.fileNotFound(path: "/some/path/book.epub")
        #expect(!error.recoveryHint.isEmpty)
    }

    @Test func networkUnavailableProducesCorrectCode() {
        let error = AppError.networkUnavailable()
        #expect(error.code == .network(.unavailable))
    }

    @Test func networkUnavailableDescriptionIsNonEmpty() {
        let error = AppError.networkUnavailable()
        #expect(!error.description.isEmpty)
    }

    @Test func networkUnavailableRecoveryHintIsNonEmpty() {
        let error = AppError.networkUnavailable()
        #expect(!error.recoveryHint.isEmpty)
    }

    @Test func premiumRequiredProducesCorrectCode() {
        let error = AppError.premiumRequired(feature: "translation")
        #expect(error.code == .storeKit(.purchaseFailed))
    }

    @Test func premiumRequiredDescriptionIsNonEmpty() {
        let error = AppError.premiumRequired(feature: "translation")
        #expect(!error.description.isEmpty)
    }

    @Test func premiumRequiredRecoveryHintIsNonEmpty() {
        let error = AppError.premiumRequired(feature: "translation")
        #expect(!error.recoveryHint.isEmpty)
    }

    @Test func timeoutProducesCorrectCode() {
        let error = AppError.timeout(service: "GeminiService")
        #expect(error.code == .network(.timeout))
    }

    @Test func timeoutDescriptionIsNonEmpty() {
        let error = AppError.timeout(service: "GeminiService")
        #expect(!error.description.isEmpty)
    }

    @Test func timeoutRecoveryHintIsNonEmpty() {
        let error = AppError.timeout(service: "GeminiService")
        #expect(!error.recoveryHint.isEmpty)
    }

    @Test func underlyingErrorIsNilByDefaultForFactoryMethods() {
        #expect(AppError.fileNotFound(path: "/x").underlyingError == nil)
        #expect(AppError.networkUnavailable().underlyingError == nil)
        #expect(AppError.premiumRequired(feature: "tts").underlyingError == nil)
        #expect(AppError.timeout(service: "webdav").underlyingError == nil)
    }
}

// MARK: - LocalizedError Surface Tests

struct AppErrorLocalizedErrorTests {

    @Test func errorDescriptionEqualsDescription() {
        let error = AppError.make(.fileSystem(.fileNotFound))
        #expect(error.errorDescription == error.description)
    }

    @Test func recoverySuggestionEqualsRecoveryHint() {
        let error = AppError.make(.network(.unavailable))
        #expect(error.recoverySuggestion == error.recoveryHint)
    }

    @Test func errorDescriptionIsNonEmptyForAllCategories() {
        let codes: [ErrorCode] = [
            .fileSystem(.fileNotFound),
            .fileSystem(.permissionDenied),
            .fileSystem(.bookmarkStale),
            .fileSystem(.diskFull),
            .network(.unavailable),
            .network(.timeout),
            .network(.invalidResponse),
            .network(.sslError),
            .cloudProvider(.authenticationFailed),
            .cloudProvider(.quotaExceeded),
            .cloudProvider(.fileConflict),
            .cloudProvider(.providerUnavailable),
            .aiService(.apiKeyMissing),
            .aiService(.rateLimitExceeded),
            .aiService(.modelUnavailable),
            .aiService(.responseParsingFailed),
            .storeKit(.purchaseFailed),
            .storeKit(.verificationFailed),
            .storeKit(.productNotFound),
            .storeKit(.subscriptionExpired),
            .sync(.conflictUnresolved),
            .sync(.pendingChangesLost),
            .sync(.clockSkewDetected),
            .sync(.recordNotFound),
            .parsing(.unsupportedFormat),
            .parsing(.corruptedData),
            .parsing(.encodingFailed),
            .parsing(.pageRenderFailed),
            .auth(.tokenExpired),
            .auth(.oauthFlowCancelled),
            .auth(.keychainAccessFailed),
            .auth(.credentialsInvalid)
        ]
        for code in codes {
            let error = AppError.make(code)
            #expect(!error.errorDescription!.isEmpty, "errorDescription empty for \(code)")
            #expect(!error.recoverySuggestion!.isEmpty, "recoverySuggestion empty for \(code)")
        }
    }
}

// MARK: - analyticsCode Format Tests

struct AppErrorAnalyticsCodeTests {

    private func matchesDotSeparatedFormat(_ value: String) -> Bool {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        let allowedCharacters = CharacterSet.letters
        for part in parts {
            guard !part.isEmpty else { return false }
            let partString = String(part)
            guard partString.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
                return false
            }
        }
        return true
    }

    @Test func analyticsCodeForFileSystemFileNotFound() {
        let code = AppError.make(.fileSystem(.fileNotFound)).analyticsCode
        #expect(code == "fileSystem.fileNotFound")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForFileSystemPermissionDenied() {
        let code = AppError.make(.fileSystem(.permissionDenied)).analyticsCode
        #expect(code == "fileSystem.permissionDenied")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForFileSystemBookmarkStale() {
        let code = AppError.make(.fileSystem(.bookmarkStale)).analyticsCode
        #expect(code == "fileSystem.bookmarkStale")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForFileSystemDiskFull() {
        let code = AppError.make(.fileSystem(.diskFull)).analyticsCode
        #expect(code == "fileSystem.diskFull")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForNetworkUnavailable() {
        let code = AppError.make(.network(.unavailable)).analyticsCode
        #expect(code == "network.unavailable")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForNetworkTimeout() {
        let code = AppError.make(.network(.timeout)).analyticsCode
        #expect(code == "network.timeout")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForNetworkInvalidResponse() {
        let code = AppError.make(.network(.invalidResponse)).analyticsCode
        #expect(code == "network.invalidResponse")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForNetworkSslError() {
        let code = AppError.make(.network(.sslError)).analyticsCode
        #expect(code == "network.sslError")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForCloudProviderAuthenticationFailed() {
        let code = AppError.make(.cloudProvider(.authenticationFailed)).analyticsCode
        #expect(code == "cloudProvider.authenticationFailed")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForCloudProviderQuotaExceeded() {
        let code = AppError.make(.cloudProvider(.quotaExceeded)).analyticsCode
        #expect(code == "cloudProvider.quotaExceeded")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForCloudProviderFileConflict() {
        let code = AppError.make(.cloudProvider(.fileConflict)).analyticsCode
        #expect(code == "cloudProvider.fileConflict")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForCloudProviderProviderUnavailable() {
        let code = AppError.make(.cloudProvider(.providerUnavailable)).analyticsCode
        #expect(code == "cloudProvider.providerUnavailable")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForAIServiceApiKeyMissing() {
        let code = AppError.make(.aiService(.apiKeyMissing)).analyticsCode
        #expect(code == "aiService.apiKeyMissing")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForAIServiceRateLimitExceeded() {
        let code = AppError.make(.aiService(.rateLimitExceeded)).analyticsCode
        #expect(code == "aiService.rateLimitExceeded")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForAIServiceModelUnavailable() {
        let code = AppError.make(.aiService(.modelUnavailable)).analyticsCode
        #expect(code == "aiService.modelUnavailable")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForAIServiceResponseParsingFailed() {
        let code = AppError.make(.aiService(.responseParsingFailed)).analyticsCode
        #expect(code == "aiService.responseParsingFailed")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForStoreKitPurchaseFailed() {
        let code = AppError.make(.storeKit(.purchaseFailed)).analyticsCode
        #expect(code == "storeKit.purchaseFailed")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForStoreKitVerificationFailed() {
        let code = AppError.make(.storeKit(.verificationFailed)).analyticsCode
        #expect(code == "storeKit.verificationFailed")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForStoreKitProductNotFound() {
        let code = AppError.make(.storeKit(.productNotFound)).analyticsCode
        #expect(code == "storeKit.productNotFound")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForStoreKitSubscriptionExpired() {
        let code = AppError.make(.storeKit(.subscriptionExpired)).analyticsCode
        #expect(code == "storeKit.subscriptionExpired")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForSyncConflictUnresolved() {
        let code = AppError.make(.sync(.conflictUnresolved)).analyticsCode
        #expect(code == "sync.conflictUnresolved")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForSyncPendingChangesLost() {
        let code = AppError.make(.sync(.pendingChangesLost)).analyticsCode
        #expect(code == "sync.pendingChangesLost")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForSyncClockSkewDetected() {
        let code = AppError.make(.sync(.clockSkewDetected)).analyticsCode
        #expect(code == "sync.clockSkewDetected")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForSyncRecordNotFound() {
        let code = AppError.make(.sync(.recordNotFound)).analyticsCode
        #expect(code == "sync.recordNotFound")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForParsingUnsupportedFormat() {
        let code = AppError.make(.parsing(.unsupportedFormat)).analyticsCode
        #expect(code == "parsing.unsupportedFormat")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForParsingCorruptedData() {
        let code = AppError.make(.parsing(.corruptedData)).analyticsCode
        #expect(code == "parsing.corruptedData")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForParsingEncodingFailed() {
        let code = AppError.make(.parsing(.encodingFailed)).analyticsCode
        #expect(code == "parsing.encodingFailed")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForParsingPageRenderFailed() {
        let code = AppError.make(.parsing(.pageRenderFailed)).analyticsCode
        #expect(code == "parsing.pageRenderFailed")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForAuthTokenExpired() {
        let code = AppError.make(.auth(.tokenExpired)).analyticsCode
        #expect(code == "auth.tokenExpired")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForAuthOauthFlowCancelled() {
        let code = AppError.make(.auth(.oauthFlowCancelled)).analyticsCode
        #expect(code == "auth.oauthFlowCancelled")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForAuthKeychainAccessFailed() {
        let code = AppError.make(.auth(.keychainAccessFailed)).analyticsCode
        #expect(code == "auth.keychainAccessFailed")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeForAuthCredentialsInvalid() {
        let code = AppError.make(.auth(.credentialsInvalid)).analyticsCode
        #expect(code == "auth.credentialsInvalid")
        #expect(matchesDotSeparatedFormat(code))
    }

    @Test func analyticsCodeContainsNoSlashes() {
        let allCodes: [ErrorCode] = [
            .fileSystem(.fileNotFound), .fileSystem(.permissionDenied),
            .fileSystem(.bookmarkStale), .fileSystem(.diskFull),
            .network(.unavailable), .network(.timeout),
            .network(.invalidResponse), .network(.sslError),
            .cloudProvider(.authenticationFailed), .cloudProvider(.quotaExceeded),
            .cloudProvider(.fileConflict), .cloudProvider(.providerUnavailable),
            .aiService(.apiKeyMissing), .aiService(.rateLimitExceeded),
            .aiService(.modelUnavailable), .aiService(.responseParsingFailed),
            .storeKit(.purchaseFailed), .storeKit(.verificationFailed),
            .storeKit(.productNotFound), .storeKit(.subscriptionExpired),
            .sync(.conflictUnresolved), .sync(.pendingChangesLost),
            .sync(.clockSkewDetected), .sync(.recordNotFound),
            .parsing(.unsupportedFormat), .parsing(.corruptedData),
            .parsing(.encodingFailed), .parsing(.pageRenderFailed),
            .auth(.tokenExpired), .auth(.oauthFlowCancelled),
            .auth(.keychainAccessFailed), .auth(.credentialsInvalid)
        ]
        for code in allCodes {
            let analyticsCode = AppError.make(code).analyticsCode
            #expect(!analyticsCode.contains("/"), "slash found in analyticsCode: \(analyticsCode)")
            #expect(!analyticsCode.contains(" "), "space found in analyticsCode: \(analyticsCode)")
            #expect(matchesDotSeparatedFormat(analyticsCode), "invalid format: \(analyticsCode)")
        }
    }

    @Test func premiumRequiredAnalyticsCodeContainsNoFeatureString() {
        let featureValue = "ultra-secret-feature-name"
        let error = AppError.premiumRequired(feature: featureValue)
        #expect(!error.analyticsCode.contains(featureValue))
    }

    @Test func timeoutAnalyticsCodeContainsNoServiceString() {
        let serviceValue = "GeminiServiceInternal"
        let error = AppError.timeout(service: serviceValue)
        #expect(!error.analyticsCode.contains(serviceValue))
    }

    @Test func fileNotFoundAnalyticsCodeContainsNoPath() {
        let pathValue = "/Users/secret/Documents/private.epub"
        let error = AppError.fileNotFound(path: pathValue)
        #expect(!error.analyticsCode.contains(pathValue))
        #expect(!error.analyticsCode.contains("/"))
    }
}

// MARK: - ErrorCode Equatable Tests

struct ErrorCodeEquatableTests {

    @Test func sameFileSystemCodesAreEqual() {
        #expect(ErrorCode.fileSystem(.fileNotFound) == ErrorCode.fileSystem(.fileNotFound))
        #expect(ErrorCode.fileSystem(.permissionDenied) == ErrorCode.fileSystem(.permissionDenied))
        #expect(ErrorCode.fileSystem(.bookmarkStale) == ErrorCode.fileSystem(.bookmarkStale))
        #expect(ErrorCode.fileSystem(.diskFull) == ErrorCode.fileSystem(.diskFull))
    }

    @Test func differentFileSystemCodesAreNotEqual() {
        #expect(ErrorCode.fileSystem(.fileNotFound) != ErrorCode.fileSystem(.permissionDenied))
        #expect(ErrorCode.fileSystem(.bookmarkStale) != ErrorCode.fileSystem(.diskFull))
    }

    @Test func sameNetworkCodesAreEqual() {
        #expect(ErrorCode.network(.unavailable) == ErrorCode.network(.unavailable))
        #expect(ErrorCode.network(.timeout) == ErrorCode.network(.timeout))
        #expect(ErrorCode.network(.invalidResponse) == ErrorCode.network(.invalidResponse))
        #expect(ErrorCode.network(.sslError) == ErrorCode.network(.sslError))
    }

    @Test func differentNetworkCodesAreNotEqual() {
        #expect(ErrorCode.network(.unavailable) != ErrorCode.network(.timeout))
        #expect(ErrorCode.network(.invalidResponse) != ErrorCode.network(.sslError))
    }

    @Test func differentCategoriesAreNotEqual() {
        #expect(ErrorCode.fileSystem(.fileNotFound) != ErrorCode.network(.unavailable))
        #expect(ErrorCode.cloudProvider(.authenticationFailed) != ErrorCode.auth(.credentialsInvalid))
        #expect(ErrorCode.storeKit(.purchaseFailed) != ErrorCode.sync(.conflictUnresolved))
        #expect(ErrorCode.parsing(.corruptedData) != ErrorCode.aiService(.apiKeyMissing))
    }

    @Test func sameCloudProviderCodesAreEqual() {
        #expect(ErrorCode.cloudProvider(.authenticationFailed) == ErrorCode.cloudProvider(.authenticationFailed))
        #expect(ErrorCode.cloudProvider(.quotaExceeded) == ErrorCode.cloudProvider(.quotaExceeded))
        #expect(ErrorCode.cloudProvider(.fileConflict) == ErrorCode.cloudProvider(.fileConflict))
        #expect(ErrorCode.cloudProvider(.providerUnavailable) == ErrorCode.cloudProvider(.providerUnavailable))
    }

    @Test func sameAIServiceCodesAreEqual() {
        #expect(ErrorCode.aiService(.apiKeyMissing) == ErrorCode.aiService(.apiKeyMissing))
        #expect(ErrorCode.aiService(.rateLimitExceeded) == ErrorCode.aiService(.rateLimitExceeded))
        #expect(ErrorCode.aiService(.modelUnavailable) == ErrorCode.aiService(.modelUnavailable))
        #expect(ErrorCode.aiService(.responseParsingFailed) == ErrorCode.aiService(.responseParsingFailed))
    }

    @Test func sameStoreKitCodesAreEqual() {
        #expect(ErrorCode.storeKit(.purchaseFailed) == ErrorCode.storeKit(.purchaseFailed))
        #expect(ErrorCode.storeKit(.verificationFailed) == ErrorCode.storeKit(.verificationFailed))
        #expect(ErrorCode.storeKit(.productNotFound) == ErrorCode.storeKit(.productNotFound))
        #expect(ErrorCode.storeKit(.subscriptionExpired) == ErrorCode.storeKit(.subscriptionExpired))
    }

    @Test func sameSyncCodesAreEqual() {
        #expect(ErrorCode.sync(.conflictUnresolved) == ErrorCode.sync(.conflictUnresolved))
        #expect(ErrorCode.sync(.pendingChangesLost) == ErrorCode.sync(.pendingChangesLost))
        #expect(ErrorCode.sync(.clockSkewDetected) == ErrorCode.sync(.clockSkewDetected))
        #expect(ErrorCode.sync(.recordNotFound) == ErrorCode.sync(.recordNotFound))
    }

    @Test func sameParsingCodesAreEqual() {
        #expect(ErrorCode.parsing(.unsupportedFormat) == ErrorCode.parsing(.unsupportedFormat))
        #expect(ErrorCode.parsing(.corruptedData) == ErrorCode.parsing(.corruptedData))
        #expect(ErrorCode.parsing(.encodingFailed) == ErrorCode.parsing(.encodingFailed))
        #expect(ErrorCode.parsing(.pageRenderFailed) == ErrorCode.parsing(.pageRenderFailed))
    }

    @Test func sameAuthCodesAreEqual() {
        #expect(ErrorCode.auth(.tokenExpired) == ErrorCode.auth(.tokenExpired))
        #expect(ErrorCode.auth(.oauthFlowCancelled) == ErrorCode.auth(.oauthFlowCancelled))
        #expect(ErrorCode.auth(.keychainAccessFailed) == ErrorCode.auth(.keychainAccessFailed))
        #expect(ErrorCode.auth(.credentialsInvalid) == ErrorCode.auth(.credentialsInvalid))
    }
}

// MARK: - ErrorCode Hashable Tests

struct ErrorCodeHashableTests {

    @Test func errorCodeCanBeUsedAsDictionaryKey() {
        var dict: [ErrorCode: String] = [:]
        dict[.fileSystem(.fileNotFound)] = "file not found"
        dict[.network(.unavailable)] = "no network"
        dict[.storeKit(.purchaseFailed)] = "purchase failed"

        #expect(dict[.fileSystem(.fileNotFound)] == "file not found")
        #expect(dict[.network(.unavailable)] == "no network")
        #expect(dict[.storeKit(.purchaseFailed)] == "purchase failed")
        #expect(dict[.auth(.tokenExpired)] == nil)
    }

    @Test func errorCodeCanBeUsedInSet() {
        var set: Set<ErrorCode> = []
        set.insert(.fileSystem(.fileNotFound))
        set.insert(.network(.timeout))
        set.insert(.fileSystem(.fileNotFound))

        #expect(set.count == 2)
        #expect(set.contains(.fileSystem(.fileNotFound)))
        #expect(set.contains(.network(.timeout)))
        #expect(!set.contains(.auth(.tokenExpired)))
    }

    @Test func equalCodesProduceSameHashValue() {
        let code1 = ErrorCode.cloudProvider(.quotaExceeded)
        let code2 = ErrorCode.cloudProvider(.quotaExceeded)
        #expect(code1.hashValue == code2.hashValue)
    }

    @Test func allCategoriesHashableAsKeys() {
        var dict: [ErrorCode: Int] = [:]
        dict[.fileSystem(.diskFull)] = 1
        dict[.network(.sslError)] = 2
        dict[.cloudProvider(.fileConflict)] = 3
        dict[.aiService(.modelUnavailable)] = 4
        dict[.storeKit(.subscriptionExpired)] = 5
        dict[.sync(.clockSkewDetected)] = 6
        dict[.parsing(.pageRenderFailed)] = 7
        dict[.auth(.keychainAccessFailed)] = 8

        #expect(dict.count == 8)
        #expect(dict[.fileSystem(.diskFull)] == 1)
        #expect(dict[.network(.sslError)] == 2)
        #expect(dict[.cloudProvider(.fileConflict)] == 3)
        #expect(dict[.aiService(.modelUnavailable)] == 4)
        #expect(dict[.storeKit(.subscriptionExpired)] == 5)
        #expect(dict[.sync(.clockSkewDetected)] == 6)
        #expect(dict[.parsing(.pageRenderFailed)] == 7)
        #expect(dict[.auth(.keychainAccessFailed)] == 8)
    }
}

// MARK: - Actor Boundary (Sendable) Tests

struct AppErrorSendableTests {

    @Test func appErrorCanBePassedAcrossActorBoundary() async {
        let receiver = ErrorReceiver()
        let error = AppError.fileNotFound(path: "/books/test.epub")

        await receiver.receive(error)

        let storedCode = await receiver.storedCode()
        #expect(storedCode == .fileSystem(.fileNotFound))
    }

    @Test func appErrorNetworkUnavailableCanBePassedAcrossActorBoundary() async {
        let receiver = ErrorReceiver()
        let error = AppError.networkUnavailable()

        await receiver.receive(error)

        let storedCode = await receiver.storedCode()
        #expect(storedCode == .network(.unavailable))
    }

    @Test func appErrorPremiumRequiredCanBePassedAcrossActorBoundary() async {
        let receiver = ErrorReceiver()
        let error = AppError.premiumRequired(feature: "summary")

        await receiver.receive(error)

        let storedCode = await receiver.storedCode()
        #expect(storedCode == .storeKit(.purchaseFailed))
    }

    @Test func appErrorTimeoutCanBePassedAcrossActorBoundary() async {
        let receiver = ErrorReceiver()
        let error = AppError.timeout(service: "CloudKit")

        await receiver.receive(error)

        let storedCode = await receiver.storedCode()
        #expect(storedCode == .network(.timeout))
    }

    @Test func appErrorMakeCanBePassedAcrossActorBoundary() async {
        let receiver = ErrorReceiver()
        let error = AppError.make(.auth(.tokenExpired))

        await receiver.receive(error)

        let storedCode = await receiver.storedCode()
        #expect(storedCode == .auth(.tokenExpired))
    }

    @Test func multipleErrorsCanBePassedConcurrently() async {
        let errors: [AppError] = [
            .fileNotFound(path: "/a"),
            .networkUnavailable(),
            .premiumRequired(feature: "x"),
            .timeout(service: "y"),
            .make(.sync(.conflictUnresolved)),
            .make(.parsing(.corruptedData))
        ]

        await withTaskGroup(of: Void.self) { group in
            for error in errors {
                group.addTask {
                    let receiver = ErrorReceiver()
                    await receiver.receive(error)
                    let code = await receiver.storedCode()
                    #expect(code != nil)
                }
            }
        }
    }
}

// MARK: - AppError make() Convenience Tests

struct AppErrorMakeTests {

    @Test func makeProducesCorrectCodeForEveryCategory() {
        let pairs: [(ErrorCode, ErrorCode)] = [
            (.fileSystem(.fileNotFound), .fileSystem(.fileNotFound)),
            (.network(.timeout), .network(.timeout)),
            (.cloudProvider(.providerUnavailable), .cloudProvider(.providerUnavailable)),
            (.aiService(.apiKeyMissing), .aiService(.apiKeyMissing)),
            (.storeKit(.verificationFailed), .storeKit(.verificationFailed)),
            (.sync(.pendingChangesLost), .sync(.pendingChangesLost)),
            (.parsing(.encodingFailed), .parsing(.encodingFailed)),
            (.auth(.oauthFlowCancelled), .auth(.oauthFlowCancelled))
        ]
        for (input, expected) in pairs {
            let error = AppError.make(input)
            #expect(error.code == expected, "Expected \(expected) but got \(error.code)")
        }
    }

    @Test func makeWithUnderlyingErrorPreservesUnderlying() {
        struct SentinelError: Error {}
        let sentinel = SentinelError()
        let error = AppError.make(.network(.invalidResponse), underlying: sentinel)
        #expect(error.underlyingError != nil)
    }

    @Test func makeWithoutUnderlyingErrorIsNil() {
        let error = AppError.make(.parsing(.corruptedData))
        #expect(error.underlyingError == nil)
    }
}