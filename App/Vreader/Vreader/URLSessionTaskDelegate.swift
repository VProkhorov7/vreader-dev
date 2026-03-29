// Shared/DownloadDelegate.swift
import Foundation

final class DownloadProgressDelegate: NSObject, URLSessionTaskDelegate {
    private let onProgress: (Double) -> Void

    init(onProgress: @escaping (Double) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(_ session: URLSession,
                    didCreateTask task: URLSessionTask) {
        // KVO наблюдение за task.progress
        task.progress.addObserver(self,
            forKeyPath: "fractionCompleted",
            options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "fractionCompleted",
           let progress = object as? Progress {
            DispatchQueue.main.async {
                self.onProgress(progress.fractionCompleted)
            }
        }
    }
}
