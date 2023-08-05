import Foundation

protocol NWCommunicating {
    func sendMessage(data: Data) async throws
    func sendFinalMessage() async throws
    func receiveNextData()
}
