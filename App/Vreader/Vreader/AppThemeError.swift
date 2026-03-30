import Foundation

enum AppThemeError: Error {
    case premiumRequired

    var localizedDescription: String {
        L10n.AppTheme.premiumRequired
    }
}