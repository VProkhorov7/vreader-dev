import SwiftUI

struct StorageView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Облачные хранилища") {
                    Label("iCloud Drive", systemImage: "icloud.fill")
                    Label("Dropbox", systemImage: "cloud.fill")
                    Label("Google Drive", systemImage: "cloud.fill")
                }
                
                Section("Локальное хранилище") {
                    Label("На этом устройстве", systemImage: "internaldrive.fill")
                }
            }
            .navigationTitle("Хранилища")
        }
    }
}

#Preview {
    StorageView()
}
