extension Sequence where Element: Sendable {
    /// An async function of `map`.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `transform` closure run in parallel when the value is 2 or more.
    ///   - priority: A priority of the giving closure.
    ///   - transform: A similar closure with `map`'s one, but it's async.
    /// - Returns: A transformed array.
    public func asyncMap<T: Sendable>(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        try await withThrowingOrderedTaskGroup(of: T.self) { group in
            var values: [T] = []

            try await internalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                taskOperation: transform
            ) { value in
                values.append(value)
            }

            return values
        }
    }
}
