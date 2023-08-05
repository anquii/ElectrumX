public struct History: Decodable {
    public let heightRange: ClosedRange<UInt64>
    public let confirmedTransactions: [ConfirmedTransaction]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fromHeight = try container.decode(UInt64.self, forKey: .fromHeight)
        let toHeight = try container.decode(UInt64.self, forKey: .toHeight)
        heightRange = fromHeight...toHeight
        confirmedTransactions = try container.decode([ConfirmedTransaction].self, forKey: .confirmedTransactions)
    }

    private enum CodingKeys: String, CodingKey {
        case fromHeight = "from_height"
        case toHeight = "to_height"
        case confirmedTransactions = "history"
    }
}
