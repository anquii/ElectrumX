public struct ConfirmedTransaction: Decodable {
    public let height: UInt64
    public let hash: String

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        height = try container.decode(UInt64.self, forKey: .height)
        hash = try container.decode(String.self, forKey: .hash)
    }

    private enum CodingKeys: String, CodingKey {
        case height
        case hash = "tx_hash"
    }
}
