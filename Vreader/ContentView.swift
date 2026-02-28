import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: TabTag = .reading
    
    var body: some View {
        TabView(selection: $selectedTab) {  // ← Читаю по умолчанию
            // 1. ЧИТАЮ — главная reading pane
            ReadingSessionView()
                .tabItem {
                    Label("Читаю", systemImage: "book.fill")
                }
                .tag(.reading)

            // 2. МОЯ БИБЛИОТЕКА — список книг
            LibraryView()  // ← переименован из CollectionView
                .tabItem {
                    Label("Моя библиотека", systemImage: "books.vertical.fill")
                }
                .tag(.library)

            // 3. ОНЛАЙН
            OnlineView()
                .tabItem {
                    Label("Онлайн", systemImage: "globe")
                }
                .tag(.online)

            // 4. ХРАНИЛИЩА
            StorageView()
                .tabItem {
                    Label("Хранилища", systemImage: "externaldrive.fill")
                }
                .tag(.storage)
        }
    }
}

// Tags для TabView selection
enum TabTag: String, CaseIterable {
    case reading = "Читаю"
    case library = "Моя библиотека"
    case online  = "Онлайн"
    case storage = "Хранилища"
}
