import SwiftUI
import SwiftData

@main
struct VReaderApp: App {
    let container: ModelContainer

    private static let dbVersionKey = "db.schemaVersion"
    private static let currentVersion = 2

    init() {
        let schema = Schema([Book.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        let savedVersion = UserDefaults.standard.integer(forKey: Self.dbVersionKey)
        if savedVersion < Self.currentVersion {
            try? FileManager.default.removeItem(at: config.url)
            UserDefaults.standard.set(Self.currentVersion, forKey: Self.dbVersionKey)
        }

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            let storeURL = config.url
            try? FileManager.default.removeItem(at: storeURL)
            do {
                container = try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("Не удалось создать ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
