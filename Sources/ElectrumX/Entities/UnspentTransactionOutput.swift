public struct UnspentTransactionOutput: Decodable {
    public let height: UInt64
    public let position: Int
    public let hash: String
    public let value: UInt64

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        height = try container.decode(UInt64.self, forKey: .height)
        position = try container.decode(Int.self, forKey: .position)
        hash = try container.decode(String.self, forKey: .hash)
        value = try container.decode(UInt64.self, forKey: .value)
    }

    private enum CodingKeys: String, CodingKey {
        case height
        case position = "tx_pos"
        case hash = "tx_hash"
        case value
    }

}
