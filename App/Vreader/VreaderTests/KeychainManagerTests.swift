import XCTest
@testable import Vreader

final class KeychainManagerTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        await KeychainManager.shared.deleteAll()
    }

    override func tearDown() async throws {
        await KeychainManager.shared.deleteAll()
        try await super.tearDown()
    }

    // MARK: - Save and Load String

    func testSaveAndLoadString() async throws {
        let key = KeychainKey.geminiAPIKey
        let value = "test-api-key-abc123"

        try await KeychainManager.shared.save(key: key, value: value)
        let loaded: String? = await KeychainManager.shared.load(key: key)

        XCTAssertEqual(loaded, value)
    }

    func testLoadMissingStringKeyReturnsNil() async {
        let loaded: String? = await KeychainManager.shared.load(key: .geminiAPIKey)
        XCTAssertNil(loaded)
    }

    // MARK: - Save and Load Data

    func testSaveAndLoadData() async throws {
        let key = KeychainKey.dropboxRefreshToken
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])

        try await KeychainManager.shared.save(key: key, data: data)
        let loaded: Data? = await KeychainManager.shared.load(key: key)

        XCTAssertEqual(loaded, data)
    }

    func testLoadMissingDataKeyReturnsNil() async {
        let loaded: Data? = await KeychainManager.shared.load(key: .oneDriveRefreshToken)
        XCTAssertNil(loaded)
    }

    // MARK: - Delete

    func testDeleteRemovesKey() async throws {
        let key = KeychainKey.geminiAPIKey

        try await KeychainManager.shared.save(key: key, value: "to-delete")
        try await KeychainManager.shared.delete(key: key)
        let loaded: String? = await KeychainManager.shared.load(key: key)

        XCTAssertNil(loaded)
    }

    func testDeleteNonExistentKeyDoesNotThrow() async {
        do {
            try await KeychainManager.shared.delete(key: .geminiAPIKey)
        } catch {
            XCTFail("Deleting a missing key must not throw, got: \(error)")
        }
    }

    // MARK: - Upsert

    func testSaveTwiceSameKeyDoesNotThrow() async throws {
        let key = KeychainKey.geminiAPIKey

        try await KeychainManager.shared.save(key: key, value: "first-value")
        try await KeychainManager.shared.save(key: key, value: "second-value")

        let loaded: String? = await KeychainManager.shared.load(key: key)
        XCTAssertEqual(loaded, "second-value")
    }

    func testUpsertOverwritesExistingValue() async throws {
        let key = KeychainKey.googleDriveAccessToken

        try await KeychainManager.shared.save(key: key, value: "v1")
        try await KeychainManager.shared.save(key: key, value: "v2")
        try await KeychainManager.shared.save(key: key, value: "v3")

        let loaded: String? = await KeychainManager.shared.load(key: key)
        XCTAssertEqual(loaded, "v3")
    }

    // MARK: - Exists

    func testExistsReturnsFalseForMissingKey() async {
        let exists = await KeychainManager.shared.exists(key: .geminiAPIKey)
        XCTAssertFalse(exists)
    }

    func testExistsReturnsTrueAfterSave() async throws {
        try await KeychainManager.shared.save(key: .geminiAPIKey, value: "present")
        let exists = await KeychainManager.shared.exists(key: .geminiAPIKey)
        XCTAssertTrue(exists)
    }

    func testExistsReturnsFalseAfterDelete() async throws {
        try await KeychainManager.shared.save(key: .geminiAPIKey, value: "present")
        try await KeychainManager.shared.delete(key: .geminiAPIKey)
        let exists = await KeychainManager.shared.exists(key: .geminiAPIKey)
        XCTAssertFalse(exists)
    }

    // MARK: - Host-Scoped Keys

    func testWebDAVPasswordsStoredIndependentlyPerHost() async throws {
        let hostA = "a.example.com"
        let hostB = "b.example.com"

        try await KeychainManager.shared.save(key: .webDAVPassword(host: hostA), value: "pass-a")
        try await KeychainManager.shared.save(key: .webDAVPassword(host: hostB), value: "pass-b")

        let loadedA: String? = await KeychainManager.shared.load(key: .webDAVPassword(host: hostA))
        let loadedB: String? = await KeychainManager.shared.load(key: .webDAVPassword(host: hostB))

        XCTAssertEqual(loadedA, "pass-a")
        XCTAssertEqual(loadedB, "pass-b")
        XCTAssertNotEqual(loadedA, loadedB)
    }

    func testSMBPasswordsStoredIndependentlyPerHost() async throws {
        let hostA = "nas.local"
        let hostB = "server.local"

        try await KeychainManager.shared.save(key: .smbPassword(host: hostA), value: "smb-a")
        try await KeychainManager.shared.save(key: .smbPassword(host: hostB), value: "smb-b")

        let loadedA: String? = await KeychainManager.shared.load(key: .smbPassword(host: hostA))
        let loadedB: String? = await KeychainManager.shared.load(key: .smbPassword(host: hostB))

        XCTAssertEqual(loadedA, "smb-a")
        XCTAssertEqual(loadedB, "smb-b")
    }

    func testWebDAVAndSMBSameHostDoNotCollide() async throws {
        let host = "shared.example.com"

        try await KeychainManager.shared.save(key: .webDAVPassword(host: host), value: "webdav-pass")
        try await KeychainManager.shared.save(key: .smbPassword(host: host), value: "smb-pass")

        let webdav: String? = await KeychainManager.shared.load(key: .webDAVPassword(host: host))
        let smb: String? = await KeychainManager.shared.load(key: .smbPassword(host: host))

        XCTAssertEqual(webdav, "webdav-pass")
        XCTAssertEqual(smb, "smb-pass")
        XCTAssertNotEqual(webdav, smb)
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

    func testSensitiveKeysAreNotSynchronizable() {
        XCTAssertFalse(KeychainKey.geminiAPIKey.isSynchronizable)
        XCTAssertFalse(KeychainKey.webDAVPassword(host: "example.com").isSynchronizable)
        XCTAssertFalse(KeychainKey.smbPassword(host: "nas.local").isSynchronizable)
    }

    // MARK: - DeleteAll

    func testDeleteAllRemovesAllItems() async throws {
        try await KeychainManager.shared.save(key: .geminiAPIKey, value: "k1")
        try await KeychainManager.shared.save(key: .googleDriveAccessToken, value: "k2")
        try await KeychainManager.shared.save(key: .webDAVPassword(host: "host.com"), value: "k3")
        try await KeychainManager.shared.save(key: .smbPassword(host: "nas.local"), value: "k4")

        await KeychainManager.shared.deleteAll()

        let e1 = await KeychainManager.shared.exists(key: .geminiAPIKey)
        let e2 = await KeychainManager.shared.exists(key: .googleDriveAccessToken)
        let e3 = await KeychainManager.shared.exists(key: .webDAVPassword(host: "host.com"))
        let e4 = await KeychainManager.shared.exists(key: .smbPassword(host: "nas.local"))

        XCTAssertFalse(e1)
        XCTAssertFalse(e2)
        XCTAssertFalse(e3)
        XCTAssertFalse(e4)
    }

    // MARK: - Reinstall Simulation

    func testReinstallSimulationWipesItems() async throws {
        try await KeychainManager.shared.save(key: .geminiAPIKey, value: "stale-key")

        let existsBefore = await KeychainManager.shared.exists(key: .geminiAPIKey)
        XCTAssertTrue(existsBefore)

        await KeychainManager.shared.deleteAll()

        let existsAfter = await KeychainManager.shared.exists(key: .geminiAPIKey)
        XCTAssertFalse(existsAfter)
    }
}