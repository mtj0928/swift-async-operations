extension Sequence where Element: Sendable {
    /// An async function of `filter`.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `isIncluded` closure run in parallel when the value is 2 or more.
    ///   - priority: A priority of the giving closure.
    ///   - isIncluded: A similar closure with `filter`'s one, but it's async.
    /// - Returns: A filtered array which has only elements which satisfy the `isIncluded`.
    public func asyncFilter(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        _ isIncluded: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> [Element] {
        try await withThrowingTaskGroup(of: (Element?, Int).self) { group in
            var values: [Element] = []

            try await internalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                taskOperation: {
                    value in try await isIncluded(value) ? value : nil
                }
            ) { value in
                if let value {
                    values.append(value)
                }
            }

            return values
        }
    }
}
