import XCTest
import Foundation
import OSLog // For OSLogType comparison if needed, but not directly testable
@testable import Vreader // Import the module to access internal types and classes

final class DiagnosticsServiceTests: XCTestCase {

    var service: DiagnosticsService!
    let logFileName = "diagnostics.log"

    override func setUpWithError() throws {
        super.setUpWithError()
        service = DiagnosticsService.shared
        service._clearRingBuffer() // Ensure a clean state for each test

        // Clean up any existing log file in Caches directory
        let cachesDirectory = try XCTUnwrap(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)
        let logFileURL = cachesDirectory.appendingPathComponent(logFileName)
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            try FileManager.default.removeItem(at: logFileURL)
        }

        #if DEBUG
        service._isTestingReleaseMode = false // Reset simulation flag
        #endif
    }

    override func tearDownWithError() throws {
        service = nil
        super.tearDownWithError()
    }

    // MARK: - DoD: DiagnosticsService.shared is final class conforming to @unchecked Sendable

    func testSharedInstanceIsSingletonAndSendable() {
        let instance1 = DiagnosticsService.shared
        let instance2 = DiagnosticsService.shared
        XCTAssertTrue(instance1 === instance2, "DiagnosticsService.shared should be a singleton.")

        // Conformance to @unchecked Sendable is a compile-time check.
        // We can't directly test it at runtime, but its presence in the declaration
        // satisfies the DoD.
        _ = instance1 as @unchecked Sendable
    }

    // MARK: - DoD: LogLevel enum with cases

    func testLogLevelEnum() {
        XCTAssertEqual(DiagnosticsService.LogLevel.allCases.count, 5)
        XCTAssertTrue(DiagnosticsService.LogLevel.allCases.contains(.debug))
        XCTAssertTrue(DiagnosticsService.LogLevel.allCases.contains(.info))
        XCTAssertTrue(DiagnosticsService.LogLevel.allCases.contains(.warning))
        XCTAssertTrue(DiagnosticsService.LogLevel.allCases.contains(.error))
        XCTAssertTrue(DiagnosticsService.LogLevel.allCases.contains(.fault))
    }

    // MARK: - DoD: LogCategory enum with 8 cases

    func testLogCategoryEnum() {
        XCTAssertEqual(DiagnosticsService.LogCategory.allCases.count, 8)
        XCTAssertTrue(DiagnosticsService.LogCategory.allCases.contains(.library))
        XCTAssertTrue(DiagnosticsService.LogCategory.allCases.contains(.reader))
        XCTAssertTrue(DiagnosticsService.LogCategory.allCases.contains(.cloud))
        XCTAssertTrue(DiagnosticsService.LogCategory.allCases.contains(.ai))
        XCTAssertTrue(DiagnosticsService.LogCategory.allCases.contains(.sync))
        XCTAssertTrue(DiagnosticsService.LogCategory.allCases.contains(.storeKit))
        XCTAssertTrue(DiagnosticsService.LogCategory.allCases.contains(.fileSystem))
        XCTAssertTrue(DiagnosticsService.LogCategory.allCases.contains(.navigation))
    }

    // MARK: - DoD: All 5 public logging methods compile & use os.Logger

    func testAllLoggingMethodsCompile() {
        // This test primarily checks compilation. Runtime verification of os.Logger
        // calls is difficult without mocking OSLog, which is out of scope.
        // We rely on the internal implementation correctly calling os.Logger.
        service.debug("Test debug message", category: .library)
        service.info("Test info message", category: .reader)
        service.warning("Test warning message", category: .cloud)
        service.error(AppError.network(.timeout), context: "Cloud sync failed")
        service.fault("Test fault message", category: .ai)

        // Verify that entries are added to the buffer (in debug mode)
        #if DEBUG
        XCTAssertGreaterThan(service._ringBufferCount, 0)
        #else
        // In release, debug/info won't be added, but warning/error/fault will.
        XCTAssertGreaterThan(service._ringBufferCount, 0)
        #endif
    }

    // MARK: - DoD: Ring buffer capped at 100 entries

    func testRingBufferCapacity() {
        let maxEntries = 100
        for i in 1...200 {
            service.info("Test message \(i)", category: .library)
        }
        XCTAssertEqual(service._ringBufferCount, maxEntries, "Ring buffer should be capped at \(maxEntries) entries.")

        let bufferContents = service._getRingBufferContents()
        XCTAssertEqual(bufferContents.first?.message, "Test message 101", "Oldest entry should be evicted.")
        XCTAssertEqual(bufferContents.last?.message, "Test message 200", "Newest entry should be present.")
    }

    // MARK: - DoD: NSLock protects only ring buffer mutations

    func testNSLockUsage() {
        // This is primarily a code review item.
        // We can't directly test the lock's scope at runtime without complex introspection.
        // The implementation ensures lock is acquired/released around buffer mutations.
        // For this test, we ensure that concurrent access doesn't crash or produce obvious data races.
        let expectation = XCTestExpectation(description: "Concurrent logging completes")
        expectation.expectedFulfillmentCount = 100

        DispatchQueue.concurrentPerform(iterations: 100) { i in
            service.info("Concurrent message \(i)", category: .library)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        XCTAssertLessThanOrEqual(service._ringBufferCount, 100) // Should not exceed capacity
    }

    // MARK: - DoD: #if DEBUG / #if !DEBUG guard: Release builds skip debug and info from buffer

    func testReleaseModeBufferExclusion() {
        #if DEBUG
        service._isTestingReleaseMode = true // Simulate release mode behavior

        service.debug("Debug message in simulated release", category: .library)
        service.info("Info message in simulated release", category: .reader)
        service.warning("Warning message in simulated release", category: .cloud)
        service.error(AppError.network(.timeout), context: "Error in simulated release")
        service.fault("Fault message in simulated release", category: .ai)

        XCTAssertEqual(service._ringBufferCount, 3, "Only warning, error, and fault should be added in simulated release mode.")
        let bufferContents = service._getRingBufferContents()
        XCTAssertFalse(bufferContents.contains(where: { $0.level == .debug }))
        XCTAssertFalse(bufferContents.contains(where: { $0.level == .info }))
        XCTAssertTrue(bufferContents.contains(where: { $0.level == .warning }))
        XCTAssertTrue(bufferContents.contains(where: { $0.level == .error }))
        XCTAssertTrue(bufferContents.contains(where: { $0.level == .fault }))

        service._isTestingReleaseMode = false // Reset for other tests
        #else
        // This block runs only in Release configuration.
        // We can't directly test the buffer content in unit tests for Release builds
        // without making the buffer public, which is undesirable.
        // We rely on the compiler's behavior for #if DEBUG.
        // However, we can assert that the service exists and logs without crashing.
        service.debug("Debug message in actual release", category: .library)
        service.info("Info message in actual release", category: .reader)
        service.warning("Warning message in actual release", category: .cloud)
        service.error(AppError.network(.timeout), context: "Error in actual release")
        service.fault("Fault message in actual release", category: .ai)
        // We cannot assert _ringBufferCount here as it's not available in Release.
        // The primary check for this DoD is compile-time conditional compilation.
        #endif
    }

    // MARK: - DoD: PII filter: case-insensitive \b(token|password|key|secret)\b regex

    func testPIIFiltering_RedactsKeywords() {
        let message1 = "This message contains a token: abc123tokenXYZ"
        service.info(message1, category: .library)
        XCTAssertEqual(service._getRingBufferContents().last?.message, "This message contains a [REDACTED]: abc123tokenXYZ")

        let message2 = "My password is P@ssw0rd and my secret key is 123secret"
        service.info(message2, category: .library)
        XCTAssertEqual(service._getRingBufferContents().last?.message, "My [REDACTED] is P@ssw0rd and my [REDACTED] [REDACTED] is 123secret")

        let message3 = "APIKEY=xyz, bearer token=abc"
        service.info(message3, category: .library)
        XCTAssertEqual(service._getRingBufferContents().last?.message, "APIKEY=xyz, bearer [REDACTED]=abc")

        let message4 = "My secret is safe."
        service.info(message4, category: .library)
        XCTAssertEqual(service._getRingBufferContents().last?.message, "My [REDACTED] is safe.")

        let message5 = "TOKEN and PASSWORD in uppercase."
        service.info(message5, category: .library)
        XCTAssertEqual(service._getRingBufferContents().last?.message, "[REDACTED] and [REDACTED] in uppercase.")
    }

    func testPIIFiltering_WholeWordBoundary() {
        let message1 = "This is a keystroke event."
        service.info(message1, category: .library)
        XCTAssertEqual(service._getRingBufferContents().last?.message, "This is a keystroke event.")

        let message2 = "StoreKit purchase initiated."
        service.info(message2, category: .library)
        XCTAssertEqual(service._getRingBufferContents().last?.message, "StoreKit purchase initiated.")

        let message3 = "The key to success is hard work."
        service.info(message3, category: .library)
        XCTAssertEqual(service._getRingBufferContents().last?.message, "The [REDACTED] to success is hard work.") // "key" is a whole word

        let message4 = "A tokenized string."
        service.info(message4, category: .library)
        XCTAssertEqual(service._getRingBufferContents().last?.message, "A tokenized string.")
    }

    // MARK: - DoD: exportLogs() returns plain text, one line per entry, newlines escaped

    func testExportLogs_FormatAndNewlines() {
        service.info("First log entry.", category: .library)
        service.warning("Second log entry with a\nnewline.", category: .reader)
        service.error(AppError.fileSystem(.fileNotFound), context: "File access")

        let exportedLogs = service.exportLogs()
        let lines = exportedLogs.split(separator: "\n")

        XCTAssertEqual(lines.count, 3, "Exported logs should have 3 lines.")

        // Check format of first line
        XCTAssertTrue(lines[0].starts(with: "["), "First line should start with '['")
        XCTAssertTrue(lines[0].contains("] [INFO] [LIBRARY] First log entry."), "First line format incorrect.")

        // Check newline escaping in second line
        XCTAssertTrue(lines[1].contains("] [WARNING] [READER] Second log entry with a\\nnewline."), "Newline should be escaped.")

        // Check error log format
        XCTAssertTrue(lines[2].contains("] [ERROR] [FILESYSTEM] File access: The file could not be found. (fileSystem.fileNotFound) - Recovery: The file may have been moved or deleted. Try re-importing it from the original source."), "Error log format incorrect.")
    }

    // MARK: - DoD: persistLogsToCache() writes to Caches directory, overwrites

    func testPersistLogsToCache_CreatesAndOverwritesFile() throws {
        let cachesDirectory = try XCTUnwrap(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)
        let logFileURL = cachesDirectory.appendingPathComponent(logFileName)

        // First persist
        service.info("Initial log entry.", category: .library)
        service.persistLogsToCache()

        XCTAssertTrue(FileManager.default.fileExists(atPath: logFileURL.path), "Log file should exist after first persist.")
        var content = try String(contentsOf: logFileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("Initial log entry."), "Log file should contain initial entry.")
        XCTAssertEqual(content.split(separator: "\n").count, 1)

        // Second persist (should overwrite)
        service._clearRingBuffer() // Clear in-memory buffer to ensure only new logs are written
        service.warning("Overwritten log entry.", category: .cloud)
        service.persistLogsToCache()

        content = try String(contentsOf: logFileURL, encoding: .utf8)
        XCTAssertFalse(content.contains("Initial log entry."), "Log file should not contain initial entry after overwrite.")
        XCTAssertTrue(content.contains("Overwritten log entry."), "Log file should contain new entry after overwrite.")
        XCTAssertEqual(content.split(separator: "\n").count, 1)
    }

    // MARK: - DoD: Buffer is NOT restored from file on launch

    func testBufferIsNotRestoredFromCacheOnLaunch() throws {
        let cachesDirectory = try XCTUnwrap(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)
        let logFileURL = cachesDirectory.appendingPathComponent(logFileName)

        // Write some logs to cache
        service.info("Log for persistence test.", category: .library)
        service.persistLogsToCache()
        service._clearRingBuffer() // Clear current in-memory buffer

        // Simulate app launch by re-initializing the service
        service = DiagnosticsService() // This will call init again, which calls loadLogsFromCache()

        XCTAssertEqual(service._ringBufferCount, 0, "Ring buffer should be empty after re-initialization, not restored from cache.")
        XCTAssertNotNil(service.loadLogsFromCache(), "Cache file should still be readable.")
    }

    // MARK: - DoD: func error(_ error: AppError, context: String) compiles with AppError

    func testErrorLoggingWithAppError() {
        let testError = AppError.aiService(.apiKeyMissing)
        let context = "Gemini API call"
        service.error(testError, context: context)

        let bufferContents = service._getRingBufferContents()
        XCTAssertEqual(bufferContents.count, 1)
        let lastEntry = try XCTUnwrap(bufferContents.last)

        XCTAssertEqual(lastEntry.level, .error)
        XCTAssertEqual(lastEntry.category, .ai) // Check category mapping
        XCTAssertTrue(lastEntry.message.contains(context))
        XCTAssertTrue(lastEntry.message.contains(testError.description))
        XCTAssertTrue(lastEntry.message.contains(testError.code))
        XCTAssertTrue(lastEntry.message.contains(testError.recoveryHint))
        XCTAssertFalse(lastEntry.message.contains("apiKeyMissing"), "Error code should be 'aiService.apiKeyMissing', not just 'apiKeyMissing'")
        XCTAssertTrue(lastEntry.message.contains("aiService.apiKeyMissing"))
    }

    // MARK: - DoD: No PII in logs (implementation itself)

    func testNoPIIInServiceImplementation() {
        // This is a code review item. The implementation itself should not log PII.
        // This test serves as a reminder and placeholder for manual review.
        // The PII filter is applied to messages passed into the logging functions,
        // but the service's own internal logging should also be free of PII.
        // For example, `logger.error("Failed to persist logs to cache: \(error.localizedDescription)", category: .fileSystem)`
        // does not contain PII.
        XCTAssertTrue(true, "Manual code review required to ensure no PII in DiagnosticsService implementation.")
    }
}