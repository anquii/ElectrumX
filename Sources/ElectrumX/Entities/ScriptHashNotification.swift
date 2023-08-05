public struct ScriptHashNotification: Decodable {
    public let scriptHash: String
    public let scriptHashStatus: String

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        scriptHash = try container.decode(String.self)
        scriptHashStatus = try container.decode(String.self)
    }
}
