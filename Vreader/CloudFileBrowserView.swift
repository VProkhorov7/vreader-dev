// CloudFileBrowserViewModel.swift
import Foundation
import Combine

@MainActor
final class CloudFileBrowserViewModel: ObservableObject {
    @Published var files: [CloudFile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPath: String = "/"

    private let provider: any CloudProviderProtocol
    private var pathStack: [String] = []

    init(provider: any CloudProviderProtocol) {
        self.provider = provider
    }

    func loadFiles() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            files = try await provider.listFiles(at: currentPath)
                .filter { $0.isDirectory || isSupportedFormat($0.name) }
                .sorted { $0.isDirectory && !$1.isDirectory }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func navigate(to folder: CloudFile) async {
        pathStack.append(currentPath)
        currentPath = folder.path
        await loadFiles()
    }

    func navigateBack() async {
        guard let prev = pathStack.popLast() else { return }
        currentPath = prev
        await loadFiles()
    }

    private func isSupportedFormat(_ name: String) -> Bool {
        ["pdf", "epub", "fb2"].contains(
            name.split(separator: ".").last?.lowercased() ?? ""
        )
    }
}
