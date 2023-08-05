public struct UnconfirmedTransaction: Decodable {
    public let height: UInt64
    public let hash: String
    public let fee: UInt64

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        height = try container.decode(UInt64.self, forKey: .height)
        hash = try container.decode(String.self, forKey: .hash)
        fee = try container.decode(UInt64.self, forKey: .fee)
    }

    private enum CodingKeys: String, CodingKey {
        case height
        case hash = "tx_hash"
        case fee
    }
}
