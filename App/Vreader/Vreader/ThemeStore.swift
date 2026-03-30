import SwiftUI
import Observation

@Observable
final class ThemeStore {

    private static let userDefaultsKey = "currentThemeID"

    // TODO: Replace UserDefaults with iCloudSettingsStore after implementing the icloud-settings-store task.
    private var userDefaults: UserDefaults

    private(set) var currentThemeID: ThemeID {
        didSet {
            userDefaults.set(currentThemeID.rawValue, forKey: Self.userDefaultsKey)
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let saved = userDefaults.string(forKey: Self.userDefaultsKey)
        if let saved, let themeID = ThemeID(rawValue: saved) {
            currentThemeID = themeID
        } else {
            currentThemeID = .editorialDark
        }
    }

    var availableThemes: [any AppTheme] {
        [
            EditorialDarkTheme(),
            CuratorLightTheme(),
            NeuralLinkTheme(),
            TypewriterTheme()
        ]
    }

    var currentTheme: any AppTheme {
        theme(for: currentThemeID)
    }

    func isUnlocked(for themeID: ThemeID, isPremiumUser: Bool) -> Bool {
        let t = theme(for: themeID)
        return !t.isPremium || isPremiumUser
    }

    func setTheme(_ themeID: ThemeID, isPremiumUser: Bool) throws {
        let t = theme(for: themeID)
        if t.isPremium && !isPremiumUser {
            throw AppThemeError.premiumRequired
        }
        currentThemeID = themeID
    }

    private func theme(for id: ThemeID) -> any AppTheme {
        switch id {
        case .editorialDark: return EditorialDarkTheme()
        case .curatorLight: return CuratorLightTheme()
        case .neuralLink: return NeuralLinkTheme()
        case .typewriter: return TypewriterTheme()
        }
    }
}