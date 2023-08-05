import Combine
import JSONRPC2

public protocol ElectrumX {
    var scriptHashNotificationPublisher: any Publisher<ScriptHashNotification, Never> { get }

    func ping() async throws
    func version(params: VersionParams) async throws -> JSONRPC2Response<Version, JSONRPC2Error>
    func history(params: HistoryParams) async throws -> JSONRPC2Response<History, JSONRPC2Error>
    func balance(scriptHash: String) async throws -> JSONRPC2Response<Balance, JSONRPC2Error>
    func unconfirmedTransactions(scriptHash: String) async throws -> JSONRPC2Response<[UnconfirmedTransaction], JSONRPC2Error>
    func unspentTransactionOutputs(scriptHash: String) async throws -> JSONRPC2Response<[UnspentTransactionOutput], JSONRPC2Error>
    /// Returns the raw transaction as hex.
    func rawTransaction(hash: String) async throws -> JSONRPC2Response<String, JSONRPC2Error>
    /// Returns the hash of the broadcasted transaction.
    func broadcast(rawTransaction: String) async throws -> JSONRPC2Response<String, JSONRPC2Error>
    /// Returns the status of the script hash.
    func subscribe(scriptHash: String) async throws -> JSONRPC2Response<String, JSONRPC2Error>
    /// Returns a bool to specify if the script hash was subscribed to.
    func unsubscribe(scriptHash: String) async throws -> JSONRPC2Response<Bool, JSONRPC2Error>
}
