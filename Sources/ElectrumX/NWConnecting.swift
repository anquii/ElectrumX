import Combine
import Network

public protocol NWConnecting {
    var connectionState: NWConnection.State { get }
    var connectionStatePublisher: any Publisher<NWConnection.State, Never> { get }

    func startConnection() async throws
    func cancelConnection() async throws
}
