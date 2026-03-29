import SwiftUI

struct MainTabView: View {
    @StateObject private var session = ReadingSession.shared
    @State private var selectedTab = 0  // 0 = Читаю

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ReadingView()
            }
            .tabItem { Label("tab.reading", systemImage: "book") }
            .tag(0)

            NavigationStack {
                LibraryView()
            }
            .tabItem { Label("tab.collection", systemImage: "books.vertical") }
            .tag(1)

            NavigationStack {
                OnlineView()
            }
            .tabItem { Label("tab.online", systemImage: "globe") }
            .tag(2)

            NavigationStack {
                StoragesView()
            }
            .tabItem { Label("tab.storages", systemImage: "externaldrive") }
            .tag(3)
        }
        .onAppear {
            // При запуске всегда на вкладке "Читаю"
            selectedTab = 0
        }
    }
}

#Preview {
    MainTabView()
}
