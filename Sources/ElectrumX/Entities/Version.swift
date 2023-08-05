public struct Version: Decodable {
    public let softwareVersion: String
    public let protocolVersion: String

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        softwareVersion = try container.decode(String.self)
        protocolVersion = try container.decode(String.self)
    }
}
