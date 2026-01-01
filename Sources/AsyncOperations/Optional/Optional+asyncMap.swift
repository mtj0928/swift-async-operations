extension Optional {
    /// An async function of `map`.
    /// - Parameter transform: A similar closure with `map`'s one, but it's async.
    /// - Returns: A transformed optional.
    public func asyncMap<T>(_ transform: (Wrapped) async throws -> T) async rethrows -> T? {
        guard let value = self else {
            return nil
        }

        return try await transform(value)
    }

    /// An async function of `flatMap`.
    /// - Parameter transform: A similar closure with `flatMap`'s one, but it's async.
    /// - Returns: A transformed optional.
    public func asyncFlatMap<T>(_ transform: (Wrapped) async throws -> T?) async rethrows -> T? {
        guard let value = self else {
            return nil
        }

        return try await transform(value)
    }
}
