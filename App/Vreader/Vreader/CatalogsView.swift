import SwiftUI

struct CatalogsView: View {
    @State private var selectedSegment = 0
    @State private var showAddCatalog  = false

    var body: some View {
        VStack(spacing: 0) {

            Picker("", selection: $selectedSegment) {
                Text(L10n.Catalogs.title).tag(0)
                Text(L10n.Catalogs.storage).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            Group {
                if selectedSegment == 0 {
                    OnlineCatalogsSection(showAddCatalog: $showAddCatalog)
                } else {
                    CloudStorageSection()
                }
            }
        }
        .navigationTitle(L10n.Catalogs.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if selectedSegment == 0 {
                        showAddCatalog = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct BuiltInCatalogConfig {
    let id: String
    let displayName: String
    let detail: String
    let icon: String
    let color: Color
    let url: String
    let requiresAuth: Bool
    let description: String

    static let all: [BuiltInCatalogConfig] = [
        BuiltInCatalogConfig(
            id: "gutenberg",
            displayName: "Project Gutenberg",
            detail: "70 000+ бесплатных книг",
            icon: "books.vertical.fill",
            color: .green,
            url: "https://www.gutenberg.org/ebooks/search.opds/",
            requiresAuth: false,
            description: "Крупнейшая библиотека публичного домена. Классика мировой литературы, более 70 000 книг на 60+ языках — бесплатно и без регистрации."
        ),
        BuiltInCatalogConfig(
            id: "standard_ebooks",
            displayName: "Standard Ebooks",
            detail: "Качественные public domain",
            icon: "book.fill",
            color: .teal,
            url: "https://standardebooks.org/feeds/opds",
            requiresAuth: false,
            description: "Тщательно отформатированные книги в открытом доступе. Каждое издание проверено вручную, типографика и вёрстка на уровне коммерческих изданий."
        ),
        BuiltInCatalogConfig(
            id: "manybooks",
            displayName: "Manybooks",
            detail: "Бесплатные EPUB / FB2",
            icon: "books.vertical.fill",
            color: .mint,
            url: "https://manybooks.net/opds-list",
            requiresAuth: false,
            description: "Библиотека из 50 000+ книг в форматах EPUB, FB2 и других. Публичный домен и авторские произведения с открытой лицензией."
        )
    ]
}

struct OnlineCatalogsSection: View {
    @Binding var showAddCatalog: Bool
    @ObservedObject private var store = iCloudSettingsStore.shared

    @State private var connectingCatalog: BuiltInCatalogConfig? = nil
    @State private var selectedOPDSCatalog: OnlineCatalogEntry? = nil

    var body: some View {
        List {
            Section {
                ForEach(BuiltInCatalogConfig.all, id: \.id) { config in
                    let connected = store.isCatalogConnected(config.id)
                    CatalogRow(
                        icon: config.icon,
                        label: config.displayName,
                        detail: connected ? NSLocalizedString("catalog.connected_status", value: "Подключено", comment: "") : config.detail,
                        color: config.color,
                        isConnected: connected
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        connectingCatalog = config
                    }
                    .if(connected) { view in
                        view.swipeActions {
                            Button(role: .destructive) {
                                if let entry = store.connectedCatalogs.first(where: { $0.catalogID == config.id }) {
                                    store.removeCatalog(entry)
                                }
                            } label: {
                                Label(L10n.Catalogs.disconnect, systemImage: "minus.circle")
                            }
                        }
                    }
                }
            } header: {
                Label(L10n.Catalogs.free, systemImage: "gift")
            }

            let opdsEntries = store.connectedCatalogs.filter { entry in
                !BuiltInCatalogConfig.all.map(\.id).contains(entry.catalogID)
            }

            if !opdsEntries.isEmpty {
                Section {
                    ForEach(opdsEntries) { entry in
                        CatalogRow(
                            icon: "antenna.radiowaves.left.and.right",
                            label: entry.displayName,
                            detail: entry.url,
                            color: .purple,
                            isConnected: true
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedOPDSCatalog = entry
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.removeCatalog(entry)
                            } label: {
                                Label(L10n.Common.delete, systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Label("OPDS", systemImage: "antenna.radiowaves.left.and.right")
                }
            }

            Section {
                CatalogRow(
                    icon: "antenna.radiowaves.left.and.right",
                    label: "OPDS-каталог",
                    detail: "Calibre, Флибуста и любой OPDS-сервер",
                    color: .purple,
                    isConnected: false
                )
                .contentShape(Rectangle())
                .onTapGesture { showAddCatalog = true }

                CatalogRow(
                    icon: "cart.fill",
                    label: "Литрес",
                    detail: L10n.Catalogs.comingSoon,
                    color: .orange,
                    isConnected: false
                )
            } header: {
                Label(L10n.Common.add, systemImage: "plus.circle")
            }
        }
        .listStyle(.insetGrouped)
        .sheet(item: $connectingCatalog) { config in
            ConnectBuiltInCatalogSheet(config: config)
        }
        .sheet(isPresented: $showAddCatalog) {
            AddOPDSCatalogSheet()
        }
    }
}

struct CloudStorageSection: View {
    @ObservedObject private var store = iCloudSettingsStore.shared
    @State private var showAddSheet  = false
    @State private var selectedType: CloudProviderType? = nil

    private var availableTypes: [CloudProviderType] {
        [.yandexDisk, .mailru, .nextcloud, .webdav, .smb]
    }

    var body: some View {
        List {
            Section {
                CatalogRow(
                    icon: "icloud.fill",
                    label: "iCloud Drive",
                    detail: L10n.Catalogs.builtin,
                    color: CloudProviderType.iCloudDrive.color,
                    isConnected: true
                )
                ForEach(store.connectedAccounts) { account in
                    CatalogRow(
                        icon: account.providerType.systemImage,
                        label: account.displayName,
                        detail: account.host.isEmpty ? account.username : account.host,
                        color: account.providerType.color,
                        isConnected: true
                    )
                    .swipeActions {
                        Button(role: .destructive) {
                            store.removeAccount(account)
                        } label: {
                            Label(L10n.Common.delete, systemImage: "trash")
                        }
                    }
                }
            } header: {
                Label(L10n.Catalogs.connected, systemImage: "checkmark.circle")
            }

            Section {
                ForEach(availableTypes, id: \.self) { type in
                    CatalogRow(
                        icon: type.systemImage,
                        label: type.displayName,
                        detail: type.helpText,
                        color: type.color,
                        isConnected: false
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedType = type
                        showAddSheet = true
                    }
                }
            } header: {
                Label(L10n.Catalogs.available, systemImage: "plus.circle")
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showAddSheet, onDismiss: { selectedType = nil }) {
            AddCloudAccountSheet(preselectedType: selectedType)
        }
    }
}

struct ConnectBuiltInCatalogSheet: View {
    let config: BuiltInCatalogConfig
    @ObservedObject private var store = iCloudSettingsStore.shared
    @Environment(\.dismiss) private var dismiss

    private var isConnected: Bool { store.isCatalogConnected(config.id) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(config.color.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: config.icon)
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(config.color)
                    }
                    .padding(.top, 32)

                    Text(config.displayName)
                        .font(.title2.bold())

                    Text(config.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 12) {
                    if isConnected {
                        Button(role: .destructive) {
                            if let entry = store.connectedCatalogs.first(where: { $0.catalogID == config.id }) {
                                store.removeCatalog(entry)
                            }
                            dismiss()
                        } label: {
                            Text(L10n.Catalogs.disconnect)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.1))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            let entry = OnlineCatalogEntry(
                                id: UUID(),
                                catalogID: config.id,
                                displayName: config.displayName,
                                url: config.url,
                                login: ""
                            )
                            try? store.addCatalog(entry)
                            dismiss()
                        } label: {
                            Text(L10n.Catalogs.connect)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(config.color)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.done) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AddOPDSCatalogSheet: View {
    @ObservedObject private var store = iCloudSettingsStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name     = ""
    @State private var url      = "https://"
    @State private var login    = ""
    @State private var password = ""
    @State private var isTesting  = false
    @State private var testResult: Bool? = nil
    @State private var saveError: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Catalogs.OPDS.catalog) {
                    TextField(L10n.Catalogs.OPDS.namePlaceholder, text: $name)
                    TextField(L10n.Catalogs.OPDS.urlPlaceholder, text: $url)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    Text(L10n.Catalogs.OPDS.urlHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(L10n.Catalogs.OPDS.authSection) {
                    TextField(L10n.Catalogs.CloudForm.login, text: $login)
                        .autocapitalization(.none)
                        .textContentType(.username)
                    SecureField(L10n.Catalogs.CloudForm.password, text: $password)
                        .textContentType(.password)
                }

                Section {
                    Button {
                        testOPDS()
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: testResult == true
                                      ? "checkmark.circle.fill"
                                      : "bolt.fill")
                                .foregroundStyle(testResult == true ? Color.green : Color.accentColor)
                            }
                            Text(isTesting ? L10n.Catalogs.CloudForm.testing : L10n.Catalogs.CloudForm.test)
                        }
                    }
                    .disabled(url.count < 10 || isTesting)

                    if let result = testResult {
                        Label(
                            result ? L10n.Catalogs.OPDS.serverOk : L10n.Catalogs.OPDS.serverFail,
                            systemImage: result ? "checkmark.circle" : "xmark.circle"
                        )
                        .foregroundStyle(result ? Color.green : Color.red)
                    }

                    if let err = saveError {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(L10n.Catalogs.OPDS.addTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.add) { saveCatalog() }
                        .disabled(name.isEmpty || url.count < 10)
                }
            }
        }
    }

    private func saveCatalog() {
        let entry = OnlineCatalogEntry(
            id: UUID(),
            catalogID: UUID().uuidString,
            displayName: name,
            url: url,
            login: login
        )
        do {
            try store.addCatalog(entry, password: password)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func testOPDS() {
        isTesting = true
        testResult = nil
        guard let urlObj = URL(string: url) else {
            isTesting = false; testResult = false; return
        }
        var request = URLRequest(url: urlObj, timeoutInterval: 10)
        if !login.isEmpty, !password.isEmpty {
            let creds = "\(login):\(password)".data(using: .utf8)!.base64EncodedString()
            request.setValue("Basic \(creds)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                isTesting = false
                if let http = response as? HTTPURLResponse {
                    testResult = (200...299).contains(http.statusCode)
                } else {
                    testResult = false
                }
            }
        }.resume()
    }
}

struct AddCloudAccountSheet: View {
    var preselectedType: CloudProviderType? = nil

    @ObservedObject private var store = iCloudSettingsStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: CloudProviderType = .yandexDisk
    @State private var host     = CloudProviderType.yandexDisk.defaultHost
    @State private var login    = ""
    @State private var password = ""
    @State private var isTesting  = false
    @State private var testResult: Bool? = nil
    @State private var saveError: String? = nil

    private var addableTypes: [CloudProviderType] {
        [.yandexDisk, .mailru, .nextcloud, .webdav, .smb]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Catalogs.CloudForm.service) {
                    Picker(L10n.Catalogs.CloudForm.type_, selection: $selectedType) {
                        ForEach(addableTypes, id: \.self) { type in
                            Label(type.displayName, systemImage: type.systemImage).tag(type)
                        }
                    }
                    .onChange(of: selectedType) {
                        host = selectedType.defaultHost
                        testResult = nil
                        saveError  = nil
                    }
                    if !selectedType.helpText.isEmpty {
                        Text(selectedType.helpText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(L10n.Catalogs.CloudForm.connection) {
                    TextField(L10n.Catalogs.CloudForm.serverAddr, text: $host)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    TextField(L10n.Catalogs.CloudForm.login, text: $login)
                        .autocapitalization(.none)
                        .textContentType(.username)
                    SecureField(L10n.Catalogs.CloudForm.password, text: $password)
                        .textContentType(.password)
                }

                Section {
                    Button {
                        testConnection()
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: testResult == true
                                      ? "checkmark.circle.fill"
                                      : "bolt.fill")
                                .foregroundStyle(testResult == true ? Color.green : Color.accentColor)
                            }
                            Text(isTesting ? L10n.Catalogs.CloudForm.testing : L10n.Catalogs.CloudForm.test)
                        }
                    }
                    .disabled(login.isEmpty || password.isEmpty || isTesting)

                    if let result = testResult {
                        Label(
                            result ? L10n.Catalogs.CloudForm.testOk : L10n.Catalogs.CloudForm.testFail,
                            systemImage: result ? "checkmark.circle" : "xmark.circle"
                        )
                        .foregroundStyle(result ? Color.green : Color.red)
                    }

                    if let err = saveError {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(L10n.Catalogs.CloudForm.addTitle)
            .onAppear {
                if let preselected = preselectedType {
                    selectedType = preselected
                    host = preselected.defaultHost
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.add) { saveAccount() }
                        .disabled(login.isEmpty || password.isEmpty)
                }
            }
        }
    }

    private func saveAccount() {
        let account = CloudProviderAccount(
            id: UUID(),
            providerType: selectedType,
            displayName: selectedType.displayName,
            host: host,
            username: login,
            isPremium: false
        )
        do {
            try store.addAccount(account, password: password)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        guard let url = URL(string: host) else {
            isTesting = false; testResult = false; return
        }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "PROPFIND"
        let creds = "\(login):\(password)".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(creds)", forHTTPHeaderField: "Authorization")
        request.setValue("0", forHTTPHeaderField: "Depth")
        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                isTesting = false
                if let http = response as? HTTPURLResponse {
                    testResult = (200...299).contains(http.statusCode) || http.statusCode == 207
                } else {
                    testResult = false
                }
            }
        }.resume()
    }
}

extension View {
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
}

struct CatalogRow: View {
    let icon: String
    let label: String
    let detail: String
    let color: Color
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(isConnected ? 1.0 : 0.25))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 16))
            } else {
                Image(systemName: "plus.circle")
                    .foregroundStyle(Color(white: 0.5))
                    .font(.system(size: 20))
            }
        }
        .padding(.vertical, 4)
        .accessibilityLabel("\(label), \(detail)")
    }
}

extension BuiltInCatalogConfig: Identifiable {}

#Preview {
    NavigationStack { CatalogsView() }
}
