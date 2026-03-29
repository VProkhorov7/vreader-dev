import SwiftUI

// MainTabView оставлен для совместимости, но больше не используется как вкладка.
// Навигация теперь управляется через ContentView + AppState.
struct MainTabView: View {
    var body: some View {
        NavigationStack {
            ReadingView()
        }
    }
}
