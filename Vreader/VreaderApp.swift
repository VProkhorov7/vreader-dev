import SwiftUI
import SwiftData

@main
struct VReaderApp: App {
    let container: ModelContainer

    init() {
        // Eagerly initialize iCloudSettingsStore.shared on MainActor
        _ = iCloudSettingsStore.shared

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
            // Attempt to recreate only on migration issues
            if (error as NSError).domain == NSCocoaErrorDomain {
                let storeURL = config.url
                try? FileManager.default.removeItem(at: storeURL)
                do {
                    container = try ModelContainer(for: schema,
                                                   configurations: config)
                } catch {
                    fatalError("Failed to create ModelContainer: \(error)")
                }
            } else {
                fatalError("Failed to create ModelContainer: \(error)")
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