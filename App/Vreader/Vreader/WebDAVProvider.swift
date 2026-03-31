import Foundation
import Combine

final class WebDAVProvider: CloudProviderProtocol {
    let id = "webdav"
    let displayName: String
    let icon = "server.rack"
    let rootPath = "/"

    @Published var isAuthenticated: Bool = false

    private let baseURL: URL
    private var credentials: URLCredential?

    init(displayName: String, baseURL: URL) {
        self.displayName = displayName
        self.baseURL = baseURL
    }

    func authenticate() async throws {
        isAuthenticated = credentials != nil
    }

    func signOut() async throws {
        credentials = nil
        isAuthenticated = false
    }

    func listFiles(at path: String) async throws -> [CloudFile] {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "PROPFIND"
        request.setValue("1", forHTTPHeaderField: "Depth")
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.httpBody = """
        <?xml version="1.0"?>
        <d:propfind xmlns:d="DAV:">
          <d:prop><d:displayname/><d:getcontentlength/>
                  <d:getlastmodified/><d:resourcetype/></d:prop>
        </d:propfind>
        """.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 207 else {
            throw CloudError.fileNotFound(path)
        }
        return parseWebDAVResponse(data)
    }

    func download(file: CloudFile,
                  to localURL: URL,
                  progress: @escaping (Double) -> Void) async throws {

        guard isAuthenticated else { throw CloudError.notAuthenticated }

        let url = baseURL.appendingPathComponent(file.path)
        var request = URLRequest(url: url)

        if let credentials {
            let token = "\(credentials.user ?? ""):\(credentials.password ?? "")"
            if let data = token.data(using: .utf8) {
                request.setValue(
                    "Basic \(data.base64EncodedString())",
                    forHTTPHeaderField: "Authorization"
                )
            }
        }

        let delegate = DownloadProgressDelegate(onProgress: progress)
        let (tempURL, response) = try await URLSession.shared
            .download(for: request, delegate: delegate)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw CloudError.downloadFailed("HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        try? FileManager.default.removeItem(at: localURL)
        try FileManager.default.moveItem(at: tempURL, to: localURL)

        await MainActor.run { progress(1.0) }
    }

    func upload(from localURL: URL, to path: String,
                progress: @escaping (Double) -> Void) async throws -> CloudFile {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "PUT"
        let (data, _) = try await URLSession.shared.upload(
            for: request,
            fromFile: localURL
        )
        _ = data
        return CloudFile(id: path, name: localURL.lastPathComponent, path: path,
                         size: 0, modifiedAt: .now,
                         mimeType: "application/pdf", isDirectory: false)
    }

    func delete(file: CloudFile) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent(file.path))
        request.httpMethod = "DELETE"
        _ = try await URLSession.shared.data(for: request)
    }

    func getStorageInfo() async throws -> (used: Int64, total: Int64) {
        return (0, 0)
    }

    private func parseWebDAVResponse(_ data: Data) -> [CloudFile] {
        WebDAVXMLParser().parse(data)
    }
}