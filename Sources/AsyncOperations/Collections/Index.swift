typealias Index = UInt64

extension Index {
    func next() -> Self {
        self + 1 % Self.max
    }
}
