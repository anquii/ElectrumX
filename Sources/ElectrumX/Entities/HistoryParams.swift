public struct HistoryParams: Encodable {
    public let scriptHash: String
    public let heightRange: ClosedRange<UInt64>

    public init(scriptHash: String, heightRange: ClosedRange<UInt64>) {
        self.scriptHash = scriptHash
        self.heightRange = heightRange
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(scriptHash)
        try container.encode(heightRange.lowerBound)
        try container.encode(heightRange.upperBound)
    }
}
