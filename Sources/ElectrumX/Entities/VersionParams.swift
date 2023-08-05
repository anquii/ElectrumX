public struct VersionParams: Encodable {
    public let clientName: String
    public let protocolVersion: String

    public init(clientName: String = "", protocolVersion: String) {
        self.clientName = clientName
        self.protocolVersion = protocolVersion
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(clientName)
        try container.encode(protocolVersion)
    }
}
