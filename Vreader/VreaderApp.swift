import SwiftUI
import SwiftData

@main
struct VReaderApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Book.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            container = try ModelContainer(for: schema,
                                           configurations: config)
        } catch {
            // Попытка пересоздания только при проблемах с миграцией
            if (error as NSError).domain == NSCocoaErrorDomain {
                let storeURL = config.url
                try? FileManager.default.removeItem(at: storeURL)
                do {
                    container = try ModelContainer(for: schema,
                                                   configurations: config)
                } catch {
                    fatalError("Не удалось создать ModelContainer: \(error)")
                }
            } else {
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
