import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch appState.selectedTab {
                case .library:
                    LibraryView()
                case .reading:
                    NavigationStack { ReadingView() }
                case .catalogs:
                    NavigationStack { CatalogsView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VReaderTabBar()
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
        }
        .environmentObject(appState)
    }
}

struct VReaderTabBar: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "house", label: "Дом", isActive: false, isButton: true) {
                appState.goHome()
            }

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 1, height: 22)
                .padding(.horizontal, 8)

            TabBarButton(icon: "books.vertical", label: "Библиотека", isActive: appState.selectedTab == .library) {
                appState.selectedTab = .library
            }
            TabBarButton(icon: "book", label: "Читаю", isActive: appState.selectedTab == .reading) {
                appState.selectedTab = .reading
            }
            TabBarButton(icon: "globe", label: "Каталоги", isActive: appState.selectedTab == .catalogs) {
                appState.selectedTab = .catalogs
            }

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 1, height: 22)
                .padding(.horizontal, 8)

            TabBarButton(icon: "gearshape", label: "Настройки", isActive: false, isButton: true) {
                appState.showSettings = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)
        }
    }
}

struct TabBarButton: View {
    let icon:     String
    let label:    String
    let isActive: Bool
    var isButton: Bool = false
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: isActive ? "\(icon).fill" : icon)
                    .font(.system(size: 21, weight: isActive ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                Text(label)
                    .font(.system(size: 10, weight: isActive ? .medium : .regular))
            }
            .foregroundStyle(isActive ? Color.accentColor : Color(uiColor: .secondaryLabel))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}

#Preview {
    ContentView()
}
