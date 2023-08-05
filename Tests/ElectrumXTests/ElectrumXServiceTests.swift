import XCTest
import ElectrumX

final class ElectrumXServiceTests: XCTestCase {
    private static let versionParams = VersionParams(protocolVersion: "1.5")
    private static let scriptHash = "f586a7ec7fdbfc6d6b4aa7fed034641c742c529dc86fbe8688c7313381f7ca71"

    private func sut() -> ElectrumXService {
        .init(
            endpoint: .hostPort(host: "electrum.nav.community", port: 40002),
            parameters: .tls,
            connectionTimeout: .milliseconds(500),
            responseTimeout: .seconds(1)
        )
    }

    func testStartConnection_AndCancelConnection() async throws {
        let sut = sut()
        try await sut.startConnection()
        try await sut.cancelConnection()
    }

    func testPing() async throws {
        let sut = sut()
        try await sut.startConnection()
        try await sut.ping()
        try await sut.cancelConnection()
    }

    func testVersion() async throws {
        let sut = sut()
        try await sut.startConnection()
        let response = try await sut.version(params: Self.versionParams)
        try await sut.cancelConnection()
        XCTAssertNotNil(response.result)
        XCTAssertNil(response.error)
    }

    func testHistory() async throws {
        let sut = sut()
        try await sut.startConnection()
        try await sut.version(params: Self.versionParams)
        let params = HistoryParams(scriptHash: Self.scriptHash, heightRange: 0...6369450)
        let response = try await sut.history(params: params)
        try await sut.cancelConnection()
        XCTAssertEqual(response.result?.confirmedTransactions.count, 1)
        XCTAssertNil(response.error)
    }

    func testBalance_WithValidScriptHash() async throws {
        let sut = sut()
        try await sut.startConnection()
        try await sut.version(params: Self.versionParams)
        let response = try await sut.balance(scriptHash: Self.scriptHash)
        try await sut.cancelConnection()
        XCTAssertNotNil(response.result)
        XCTAssertNil(response.error)
    }

    func testBalance_WithInvalidScriptHash() async throws {
        let sut = sut()
        try await sut.startConnection()
        try await sut.version(params: Self.versionParams)
        let response = try await sut.balance(scriptHash: "")
        try await sut.cancelConnection()
        XCTAssertNil(response.result)
        XCTAssertNotNil(response.error)
    }

    func testUnconfirmedTransactions() async throws {
        let sut = sut()
        try await sut.startConnection()
        try await sut.version(params: Self.versionParams)
        let response = try await sut.unconfirmedTransactions(scriptHash: Self.scriptHash)
        try await sut.cancelConnection()
        XCTAssertNotNil(response.result)
        XCTAssertNil(response.error)
    }

    func testUnspentTransactionOutputs() async throws {
        let sut = sut()
        try await sut.startConnection()
        try await sut.version(params: Self.versionParams)
        let response = try await sut.unspentTransactionOutputs(scriptHash: Self.scriptHash)
        try await sut.cancelConnection()
        XCTAssertNotNil(response.result)
        XCTAssertNil(response.error)
    }

    func testRawTransaction() async throws {
        let sut = sut()
        try await sut.startConnection()
        try await sut.version(params: Self.versionParams)
        let response = try await sut.rawTransaction(hash: "6b1ccc877521306a7ab84cca371aa64b3e5107a7c06d253d5261b968b17e1165")
        try await sut.cancelConnection()
        XCTAssertNotEqual(response.result?.count, 0)
        XCTAssertNil(response.error)
    }

    func testSubscribe_AndUnsubscribe() async throws {
        let sut = sut()
        try await sut.startConnection()
        try await sut.version(params: Self.versionParams)
        let response1 = try await sut.subscribe(scriptHash: Self.scriptHash)
        let response2 = try await sut.unsubscribe(scriptHash: Self.scriptHash)
        try await sut.cancelConnection()
        XCTAssertNotEqual(response1.result?.count, 0)
        XCTAssertEqual(response2.result, true)
        XCTAssertNil(response1.error)
        XCTAssertNil(response2.error)
    }
}
