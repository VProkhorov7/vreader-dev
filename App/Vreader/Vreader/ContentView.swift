import SwiftUI

enum TabTag: String, CaseIterable, Hashable {
    case library  = "Библиотека"
    case reading  = "Читаю"
    case catalogs = "Каталоги"
    case settings = "Настройки"
    #if DEBUG
    case debug    = "Debug"
    #endif
}

struct ContentView: View {
    @StateObject private var appState = AppState.shared

    var body: some View {
        TabView(selection: $appState.selectedTab) {

            LibraryView()
                .tabItem { Image(systemName: "books.vertical.fill"); Text("Библиотека") }
                .tag(TabTag.library)

            MainTabView()
                .tabItem { Image(systemName: "book.fill"); Text("Читаю") }
                .tag(TabTag.reading)

            OnlineView()
                .tabItem { Image(systemName: "globe"); Text("Каталоги") }
                .tag(TabTag.catalogs)

            SettingsView()
                .tabItem { Image(systemName: "gearshape.fill"); Text("Настройки") }
                .tag(TabTag.settings)

            #if DEBUG
            DebugView()
                .tabItem { Image(systemName: "hammer.fill"); Text("Debug") }
                .tag(TabTag.debug)
            #endif
        }
    }
}

#Preview {
    ContentView()
}
