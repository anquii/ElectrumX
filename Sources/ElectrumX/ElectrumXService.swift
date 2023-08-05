import Foundation
import Combine
import Network
import JSONRPC2

/// Supports TCP and TLS over TCP.
public final class ElectrumXService {
    private static let newlineCharacter = UInt8(10)
    private static let newlineCharacterData = Data([newlineCharacter])

    private let queue = DispatchQueue(label: "\(#file).\(UUID().uuidString)", attributes: .concurrent)
    private let requestID = RequestID()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let connection: NWConnection
    private let connectionTimeout: DispatchQueue.SchedulerTimeType.Stride
    private let responseTimeout: DispatchQueue.SchedulerTimeType.Stride
    private let dataPublisher = PassthroughSubject<Data, ElectrumXError>()
    private let connectionStateWithErrorPublisher = PassthroughSubject<NWConnection.State, ElectrumXError>()
    private let _connectionStatePublisher = PassthroughSubject<NWConnection.State, Never>()
    private let _scriptHashNotificationPublisher = PassthroughSubject<ScriptHashNotification, Never>()
    private var cancellables = Set<AnyCancellable>()

    public init(
        endpoint: NWEndpoint,
        parameters: NWParameters,
        connectionTimeout: DispatchQueue.SchedulerTimeType.Stride = .seconds(30),
        responseTimeout: DispatchQueue.SchedulerTimeType.Stride = .seconds(60)
    ) {
        connection = NWConnection(to: endpoint, using: parameters)
        self.connectionTimeout = connectionTimeout
        self.responseTimeout = responseTimeout
        observeConnectionState()
        observeScriptHashNotifications()
    }
}

// MARK: - NWConnecting
extension ElectrumXService: NWConnecting {
    public var connectionState: NWConnection.State {
        connection.state
    }

    public var connectionStatePublisher: any Publisher<NWConnection.State, Never> {
        _connectionStatePublisher.eraseToAnyPublisher()
    }

    public func startConnection() async throws {
        guard connectionState != .ready else {
            return
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let receiveCompletion = { (completion: Subscribers.Completion<ElectrumXError>) in
                if case .failure(let error) = completion {
                    continuation.resume(throwing: error)
                }
            }
            let receiveValue = { [weak self] (value: NWConnection.State) in
                self?.receiveNextData()
                continuation.resume()
            }
            connectionStateWithErrorPublisher
                .timeout(connectionTimeout, scheduler: queue, customError: { .connectionTimeout })
                .first { $0 == .ready }
                .sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
                .store(in: &cancellables)
            connection.start(queue: queue)
        }
    }

    public func cancelConnection() async throws {
        try await sendFinalMessage()
        connection.cancel()
    }
}

// MARK: - NWCommunicating
extension ElectrumXService: NWCommunicating {
    func sendMessage(data: Data) async throws {
        try await sendMessage(data: data + Self.newlineCharacterData, contentContext: .defaultMessage)
    }

    func sendFinalMessage() async throws {
        try await sendMessage(contentContext: .finalMessage)
    }

    func receiveNextData() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: Int(UInt16.max)) { [weak self] data, _, isComplete, error in
            guard let data, error == nil else {
                return
            }
            let separatedDatas = data.dropLast(1).split(separator: Self.newlineCharacter)
            for separatedData in separatedDatas {
                self?.dataPublisher.send(separatedData)
            }
            if !isComplete, self?.connectionState == .ready {
                self?.receiveNextData()
            }
        }
    }
}

// MARK: - ElectrumX
extension ElectrumXService: ElectrumX {
    public var scriptHashNotificationPublisher: any Publisher<ScriptHashNotification, Never> {
        _scriptHashNotificationPublisher.eraseToAnyPublisher()
    }

    public func ping() async throws {
        let notification = JSONRPC2Request(method: "server.ping")
        let encodedNotification = try encoder.encode(notification)
        try await sendMessage(data: encodedNotification)
    }

    @discardableResult
    public func version(params: VersionParams) async throws -> JSONRPC2Response<Version, JSONRPC2Error> {
        try await sendMessageAndReceiveResponse(method: "server.version", params: params)
    }

    public func history(params: HistoryParams) async throws -> JSONRPC2Response<History, JSONRPC2Error> {
        try await sendMessageAndReceiveResponse(method: "blockchain.scripthash.get_history", params: params)
    }

    public func balance(scriptHash: String) async throws -> JSONRPC2Response<Balance, JSONRPC2Error> {
        try await sendMessageAndReceiveResponse(method: "blockchain.scripthash.get_balance", params: [scriptHash])
    }

    public func unconfirmedTransactions(scriptHash: String) async throws -> JSONRPC2Response<[UnconfirmedTransaction], JSONRPC2Error> {
        try await sendMessageAndReceiveResponse(method: "blockchain.scripthash.get_mempool", params: [scriptHash])
    }

    public func unspentTransactionOutputs(scriptHash: String) async throws -> JSONRPC2Response<[UnspentTransactionOutput], JSONRPC2Error> {
        try await sendMessageAndReceiveResponse(method: "blockchain.scripthash.listunspent", params: [scriptHash])
    }

    public func rawTransaction(hash: String) async throws -> JSONRPC2Response<String, JSONRPC2Error> {
        try await sendMessageAndReceiveResponse(method: "blockchain.transaction.get", params: [hash])
    }

    public func broadcast(rawTransaction: String) async throws -> JSONRPC2Response<String, JSONRPC2Error> {
        try await sendMessageAndReceiveResponse(method: "blockchain.transaction.broadcast", params: [rawTransaction])
    }

    public func subscribe(scriptHash: String) async throws -> JSONRPC2Response<String, JSONRPC2Error> {
        try await sendMessageAndReceiveResponse(method: "blockchain.scripthash.subscribe", params: [scriptHash])
    }

    public func unsubscribe(scriptHash: String) async throws -> JSONRPC2Response<Bool, JSONRPC2Error> {
        try await sendMessageAndReceiveResponse(method: "blockchain.scripthash.unsubscribe", params: [scriptHash])
    }
}

// MARK: - Helpers
fileprivate extension ElectrumXService {
    func observeConnectionState() {
        connection.stateUpdateHandler = { [weak self] state in
            self?.connectionStateWithErrorPublisher.send(state)
            self?._connectionStatePublisher.send(state)
        }
    }

    func observeScriptHashNotifications() {
        dataPublisher
            .decode(type: JSONRPC2ServerNotificationWithParams<ScriptHashNotification>.self, decoder: decoder)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in
                self?._scriptHashNotificationPublisher.send($0.params)
            })
            .store(in: &cancellables)
    }

    func sendMessage(data: Data? = nil, contentContext: NWConnection.ContentContext) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: data, contentContext: contentContext, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    func receiveResponse<R: Decodable, E: Decodable>(requestID: String) async throws -> JSONRPC2Response<R, E> {
        try await withCheckedThrowingContinuation { continuation in
            let receiveCompletion = { (completion: Subscribers.Completion<Error>) in
                if case .failure(let error) = completion {
                    continuation.resume(throwing: error)
                }
            }
            let receiveValue = { (value: JSONRPC2Response<R, E>) in
                continuation.resume(returning: value)
            }
            dataPublisher
                .timeout(responseTimeout, scheduler: queue, customError: { .responseTimeout })
                .decode(type: JSONRPC2Response<R, E>.self, decoder: decoder)
                .first { $0.id == requestID && $0.jsonrpc == "2.0" }
                .sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
                .store(in: &cancellables)
        }
    }

    func sendMessageAndReceiveResponse<P: Encodable, R: Decodable, E: Decodable>(method: String, params: P) async throws -> JSONRPC2Response<R, E> {
        let requestID = await requestID.next()
        let request = JSONRPC2Request(method: method, params: params, id: requestID)
        let encodedRequest = try encoder.encode(request)
        try await sendMessage(data: encodedRequest)
        return try await receiveResponse(requestID: requestID)
    }
}
