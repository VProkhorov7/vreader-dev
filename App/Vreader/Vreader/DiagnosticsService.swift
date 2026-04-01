import OSLog

/// A singleton service for centralized logging within the application.
/// It wraps `OSLog` to provide structured logging at various levels.
///
/// Invariant: No PII (Personally Identifiable Information) is logged.
final class DiagnosticsService {
    static let shared = DiagnosticsService()
    private let logger: Logger

    private init() {
        // Using the main bundle identifier for the subsystem is standard practice.
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.vreader.app", category: "Diagnostics")
    }

    /// Logs an informational message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The source file where the log originated (defaults to `#file`).
    ///   - function: The function where the log originated (defaults to `#function`).
    ///   - line: The line number where the log originated (defaults to `#line`).
    func info(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        let fileName = file.split(separator: "/").last ?? ""
        logger.info("[\(fileName):\(line)] \(function): \(message)")
    }

    /// Logs a debug message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The source file where the log originated (defaults to `#file`).
    ///   - function: The function where the log originated (defaults to `#function`).
    ///   - line: The line number where the log originated (defaults to `#line`).
    func debug(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        let fileName = file.split(separator: "/").last ?? ""
        logger.debug("[\(fileName):\(line)] \(function): \(message)")
    }

    /// Logs a warning message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The source file where the log originated (defaults to `#file`).
    ///   - function: The function where the log originated (defaults to `#function`).
    ///   - line: The line number where the log originated (defaults to `#line`).
    func warning(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        let fileName = file.split(separator: "/").last ?? ""
        logger.warning("[\(fileName):\(line)] \(function): \(message)")
    }

    /// Logs an error message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The source file where the log originated (defaults to `#file`).
    ///   - function: The function where the log originated (defaults to `#function`).
    ///   - line: The line number where the log originated (defaults to `#line`).
    func error(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        let fileName = file.split(separator: "/").last ?? ""
        logger.error("[\(fileName):\(line)] \(function): \(message)")
    }

    /// Logs a fault message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - file: The source file where the log originated (defaults to `#file`).
    ///   - function: The function where the log originated (defaults to `#function`).
    ///   - line: The line number where the log originated (defaults to `#line`).
    func fault(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
        let fileName = file.split(separator: "/").last ?? ""
        logger.fault("[\(fileName):\(line)] \(function): \(message)")
    }
}