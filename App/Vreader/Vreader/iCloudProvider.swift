// Providers/ICloudProvider.swift
import Foundation
import Combine

final class ICloudProvider: CloudProviderProtocol {
    let id = "icloud"
    let displayName = "iCloud Drive"
    let icon = "icloud"
    let rootPath = "/"
    
    @Published var isAuthenticated: Bool = false
    
    private let containerID = "iCloud.com.yourapp.VReader"
    private var containerURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: containerID)
            .map { $0.appendingPathComponent("Documents") }
    }
    
    func authenticate() async throws {
        // iCloud авторизация — через системный аккаунт
        guard containerURL != nil else {
            throw CloudError.notAuthenticated
        }
        isAuthenticated = true
    }
    
    func signOut() async throws {
        isAuthenticated = false // iCloud не требует явного logout
    }
    
    func listFiles(at path: String) async throws -> [CloudFile] {
        guard let base = containerURL else { throw CloudError.notAuthenticated }
        let dir = base.appendingPathComponent(path)
        
        // Запускаем metadata query для iCloud файлов
        return try await withCheckedThrowingContinuation { continuation in
            let query = NSMetadataQuery()
            query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
            query.predicate = NSPredicate(
                format: "%K BEGINSWITH %@",
                NSMetadataItemPathKey,
                dir.path
            )
            // ... обработка результатов
            continuation.resume(returning: [])
        }
    }
    
    func download(file: CloudFile,
                  to localURL: URL,
                  progress: @escaping (Double) -> Void) async throws {
        
        guard let base = containerURL else { throw CloudError.notAuthenticated }
        
        let sourceURL = base.appendingPathComponent(file.path)
        
        // Форсируем скачивание из iCloud (если файл только в облаке)
        do {
            try FileManager.default.startDownloadingUbiquitousItem(at: sourceURL)
        } catch {
            // Файл уже локальный — игнорируем ошибку
        }
        
        // Ждём появления локальной копии с прогрессом
        try await waitForUbiquitousDownload(at: sourceURL, progress: progress)
        
        try? FileManager.default.removeItem(at: localURL)
        try FileManager.default.copyItem(at: sourceURL, to: localURL)
        
        await MainActor.run { progress(1.0) }
    }
    
    func upload(from localURL: URL,
                to path: String,
                progress: @escaping (Double) -> Void) async throws -> CloudFile {
        
        guard let base = containerURL else { throw CloudError.notAuthenticated }
        
        let destinationURL = base.appendingPathComponent(path).appendingPathComponent(localURL.lastPathComponent)
        
        // Создаём родительскую папку если нужно
        let parentDir = destinationURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        
        // Копируем файл в iCloud
        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.copyItem(at: localURL, to: destinationURL)
        
        await MainActor.run { progress(1.0) }
        
        // Возвращаем CloudFile для загруженного файла
        let attrs = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
        let size = attrs[.size] as? Int64 ?? 0
        let modifiedDate = attrs[.modificationDate] as? Date ?? Date()
        
        return CloudFile(
            id: destinationURL.path,
            name: localURL.lastPathComponent,
            path: path + "/" + localURL.lastPathComponent,
            size: size,
            modifiedAt: modifiedDate,
            mimeType: mimeType(for: localURL.pathExtension),
            isDirectory: false
        )
    }
    
    func delete(file: CloudFile) async throws {
        guard let base = containerURL else { throw CloudError.notAuthenticated }
        
        let fileURL = base.appendingPathComponent(file.path)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw CloudError.fileNotFound(file.name)
        }
        
        try FileManager.default.removeItem(at: fileURL)
    }
    
    func getStorageInfo() async throws -> (used: Int64, total: Int64) {
        guard let base = containerURL else { throw CloudError.notAuthenticated }
        
        // Для iCloud можем попробовать посчитать используемое место
        let used = try calculateDirectorySize(at: base)
        
        // iCloud не предоставляет общий лимит через API напрямую,
        // возвращаем разумное значение или 0
        let total: Int64 = 0 // Можно вернуть известный лимит, если есть
        
        return (used: used, total: total)
    }
    
    private func calculateDirectorySize(at url: URL) throws -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        
        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                let attrs = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attrs?.fileSize ?? 0)
            }
        }
        
        return totalSize
    }
    
    private func mimeType(for pathExtension: String) -> String {
        switch pathExtension.lowercased() {
        case "pdf":
            return "application/pdf"
        case "epub":
            return "application/epub+zip"
        case "txt":
            return "text/plain"
        case "mobi":
            return "application/x-mobipocket-ebook"
        default:
            return "application/octet-stream"
        }
    }
    
    private func waitForUbiquitousDownload(at url: URL,
                                           progress: @escaping (Double) -> Void) async throws {
        let keys: Set<URLResourceKey> = [
            .ubiquitousItemDownloadingStatusKey
        ]
        
        for attempt in 0..<120 { // 2 минуты максимум
            let attrs = try? url.resourceValues(forKeys: keys)
            
            switch attrs?.ubiquitousItemDownloadingStatus {
            case .current:
                return  // Готово
            case .downloaded:
                return  // Уже был скачан ранее
            default:
                // На macOS процент загрузки недоступен через URLResourceKey,
                // используем примерный прогресс на основе времени
                let estimatedProgress = min(0.9, Double(attempt) / 100.0)
                await MainActor.run { progress(estimatedProgress) }
            }
            
            if attempt > 5 {
                // Проверяем: файл вообще существует в iCloud?
                let exists = (try? url.checkResourceIsReachable()) ?? false
                if !exists { throw CloudError.fileNotFound(url.lastPathComponent) }
            }
            
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 сек
        }
        
        throw CloudError.downloadFailed("iCloud timeout — проверь соединение")
    }
}
