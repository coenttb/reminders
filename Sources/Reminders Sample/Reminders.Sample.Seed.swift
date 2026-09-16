public import Reminders

extension Reminders.Sample {
    public struct Seed: Hashable, Sendable {
        public var scale: Scale
        public var value: UInt64

        public init(scale: Scale, value: UInt64) {
            self.scale = scale
            self.value = value
        }
    }
}

extension Reminders.Sample.Seed {
    public var description: String { "0x" + String(value, radix: 16, uppercase: true) }
}
