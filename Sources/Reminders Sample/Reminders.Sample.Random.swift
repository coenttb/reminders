public import Reminders

extension Reminders.Sample {
    public struct Random: RandomNumberGenerator, Hashable, Sendable {
        private var state: UInt64

        public init(seed: UInt64) { state = seed }
    }
}

extension Reminders.Sample.Random {
    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func byte() -> UInt8 { UInt8(truncatingIfNeeded: next()) }

    mutating func next(in range: Range<Int>) -> Int { Int.random(in: range, using: &self) }

    mutating func chance(_ numerator: Int, in denominator: Int) -> Bool { next(in: 0..<denominator) < numerator }
}
