import XCTest
@testable import Vreader

final class KeychainManagerTests: XCTestCase {

    private var manager: KeychainManager!

    override func setUp() async throws {
        try await super.setUp()
        manager = KeychainManager.shared
        await manager.deleteAll()
        UserDefaults.standard.removeObject(forKey: "keychainDidInitialize")
    }

    override func tearDown() async throws {
        await manager.deleteAll()
        try await super.tearDown()
    }

    // MARK: - Basic String CRUD

    func testSaveLoadDeleteString() async throws {
        let key = KeychainKey.geminiAPIKey
        let value = "test-api-key-12345"

        try await manager.save(key: key, value: value)

        let loaded: String? = try await manager.load(key: key)
        XCTAssertEqual(loaded, value)

        try await manager.delete(key: key)

        let afterDelete: String? = try await manager.load(key: key)
        XCTAssertNil(afterDelete)
    }

    // MARK: - Upsert: save twice does not throw

    func testUpsertDoesNotThrowOnDuplicate() async throws {
        let key = KeychainKey.geminiAPIKey
        let firstValue = "first-value"
        let secondValue = "second-value"

        try await manager.save(key: key, value: firstValue)

        await XCTAssertNoThrowAsync {
            try await self.manager.save(key: key, value: secondValue)
        }

        let loaded: String? = try await manager.load(key: key)
        XCTAssertEqual(loaded, secondValue)
    }

    // MARK: - Load missing key returns nil

    func testLoadMissingKeyReturnsNil() async throws {
        let key = KeychainKey.geminiAPIKey
        let result: String? = try await manager.load(key: key)
        XCTAssertNil(result)
    }

    // MARK: - Basic Data CRUD

    func testSaveLoadDeleteData() async throws {
        let key = KeychainKey.dropboxAccessToken
        let data = Data("binary-token-data".utf8)

        try await manager.save(key: key, data: data)

        let loaded: Data? = try await manager.load(key: key)
        XCTAssertEqual(loaded, data)

        try await manager.delete(key: key)

        let afterDelete: Data? = try await manager.load(key: key)
        XCTAssertNil(afterDelete)
    }

    // MARK: - Upsert Data

    func testUpsertDataDoesNotThrowOnDuplicate() async throws {
        let key = KeychainKey.dropboxRefreshToken
        let firstData = Data("first".utf8)
        let secondData = Data("second".utf8)

        try await manager.save(key: key, data: firstData)

        await XCTAssertNoThrowAsync {
            try await self.manager.save(key: key, data: secondData)
        }

        let loaded: Data? = try await manager.load(key: key)
        XCTAssertEqual(loaded, secondData)
    }

    // MARK: - Delete non-existent key is no-op

    func testDeleteNonExistentKeyDoesNotThrow() async throws {
        let key = KeychainKey.geminiAPIKey
        await XCTAssertNoThrowAsync {
            try await self.manager.delete(key: key)
        }
    }

    // MARK: - Exists

    func testExistsReturnsFalseForMissingKey() async {
        let key = KeychainKey.geminiAPIKey
        let result = await manager.exists(key: key)
        XCTAssertFalse(result)
    }

    func testExistsReturnsTrueAfterSave() async throws {
        let key = KeychainKey.geminiAPIKey
        try await manager.save(key: key, value: "some-value")
        let result = await manager.exists(key: key)
        XCTAssertTrue(result)
    }

    func testExistsReturnsFalseAfterDelete() async throws {
        let key = KeychainKey.geminiAPIKey
        try await manager.save(key: key, value: "some-value")
        try await manager.delete(key: key)
        let result = await manager.exists(key: key)
        XCTAssertFalse(result)
    }

    // MARK: - WebDAV host isolation

    func testWebDAVPasswordsStoredIndependentlyPerHost() async throws {
        let hostA = "a.example.com"
        let hostB = "b.example.com"
        let keyA = KeychainKey.webDAVPassword(host: hostA)
        let keyB = KeychainKey.webDAVPassword(host: hostB)
        let passwordA = "password-for-a"
        let passwordB = "password-for-b"

        try await manager.save(key: keyA, value: passwordA)
        try await manager.save(key: keyB, value: passwordB)

        let loadedA: String? = try await manager.load(key: keyA)
        let loadedB: String? = try await manager.load(key: keyB)

        XCTAssertEqual(loadedA, passwordA)
        XCTAssertEqual(loadedB, passwordB)
        XCTAssertNotEqual(loadedA, loadedB)

        try await manager.delete(key: keyA)
        let afterDeleteA: String? = try await manager.load(key: keyA)
        let afterDeleteB: String? = try await manager.load(key: keyB)

        XCTAssertNil(afterDeleteA)
        XCTAssertEqual(afterDeleteB, passwordB)
    }

    // MARK: - SMB host isolation

    func testSMBPasswordsStoredIndependentlyPerHost() async throws {
        let hostA = "nas.local"
        let hostB = "fileserver.local"
        let keyA = KeychainKey.smbPassword(host: hostA)
        let keyB = KeychainKey.smbPassword(host: hostB)

        try await manager.save(key: keyA, value: "smb-pass-a")
        try await manager.save(key: keyB, value: "smb-pass-b")

        let loadedA: String? = try await manager.load(key: keyA)
        let loadedB: String? = try await manager.load(key: keyB)

        XCTAssertEqual(loadedA, "smb-pass-a")
        XCTAssertEqual(loadedB, "smb-pass-b")
    }

    // MARK: - isSynchronizable

    func testOAuthTokensAreSynchronizable() {
        XCTAssertTrue(KeychainKey.googleDriveAccessToken.isSynchronizable)
        XCTAssertTrue(KeychainKey.googleDriveRefreshToken.isSynchronizable)
        XCTAssertTrue(KeychainKey.dropboxAccessToken.isSynchronizable)
        XCTAssertTrue(KeychainKey.dropboxRefreshToken.isSynchronizable)
        XCTAssertTrue(KeychainKey.oneDriveAccessToken.isSynchronizable)
        XCTAssertTrue(KeychainKey.oneDriveRefreshToken.isSynchronizable)
    }

    func testNonOAuthKeysAreNotSynchronizable() {
        XCTAssertFalse(KeychainKey.geminiAPIKey.isSynchronizable)
        XCTAssertFalse(KeychainKey.webDAVPassword(host: "example.com").isSynchronizable)
        XCTAssertFalse(KeychainKey.smbPassword(host: "nas.local").isSynchronizable)
    }

    // MARK: - Service suffix for host-scoped keys

    func testWebDAVKeyUsesCorrectServiceSuffix() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.vreader.app"
        let key = KeychainKey.webDAVPassword(host: "example.com")
        XCTAssertEqual(key.service, bundleID + ".webdav")
        XCTAssertEqual(key.account, "example.com")
    }

    func testSMBKeyUsesCorrectServiceSuffix() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.vreader.app"
        let key = KeychainKey.smbPassword(host: "nas.local")
        XCTAssertEqual(key.service, bundleID + ".smb")
        XCTAssertEqual(key.account, "nas.local")
    }

    func testStandardKeyUsesMainBundleID() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.vreader.app"
        XCTAssertEqual(KeychainKey.geminiAPIKey.service, bundleID)
        XCTAssertEqual(KeychainKey.googleDriveAccessToken.service, bundleID)
    }

    // MARK: - First-launch cleanup (reinstall simulation)

    func testFirstLaunchAfterReinstallWipesExistingItems() async throws {
        let key = KeychainKey.geminiAPIKey
        try await manager.save(key: key, value: "stale-key-from-previous-install")

        let existsBefore = await manager.exists(key: key)
        XCTAssertTrue(existsBefore)

        UserDefaults.standard.removeObject(forKey: "keychainDidInitialize")

        let freshManager = KeychainManager.testInstance()

        let existsAfter = await freshManager.exists(key: key)
        XCTAssertFalse(existsAfter)

        let sentinelSet = UserDefaults.standard.bool(forKey: "keychainDidInitialize")
        XCTAssertTrue(sentinelSet)
    }

    // MARK: - deleteAll

    func testDeleteAllRemovesAllItems() async throws {
        try await manager.save(key: .geminiAPIKey, value: "api-key")
        try await manager.save(key: .googleDriveAccessToken, value: "gd-token")
        try await manager.save(key: .webDAVPassword(host: "host.example.com"), value: "webdav-pass")

        await manager.deleteAll()

        let gemini = await manager.exists(key: .geminiAPIKey)
        let gdToken = await manager.exists(key: .googleDriveAccessToken)
        let webdav = await manager.exists(key: .webDAVPassword(host: "host.example.com"))

        XCTAssertFalse(gemini)
        XCTAssertFalse(gdToken)
        XCTAssertFalse(webdav)
    }
}

// MARK: - KeychainManager test factory

extension KeychainManager {
    static func testInstance() -> KeychainManager {
        KeychainManager(appGroupID: nil)
    }
}

// MARK: - Async XCTest helpers

func XCTAssertNoThrowAsync(
    _ expression: @escaping () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
    } catch {
        XCTFail("Expected no error but got: \(error)", file: file, line: line)
    }
}