extension Sequence where Element: Sendable {
    /// An async function of `first`.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `predicate` closure run in parallel when the value is 2 or more.
    ///   - priority: A priority of the giving closure.
    ///   - predicate: A similar closure with `first`'s one, but it's async.
    /// - Returns: A first element which satisfy the given predicate.
    ///
    /// > Note: If `numberOfConcurrentTasks` is 2 or more, the predicate closure may run for elements after the first element.
    public func asyncFirst(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Element? {
        try await withThrowingOrderedTaskGroup(of: Element?.self) { group in
            for (index, element) in self.enumerated() {
                if index >= numberOfConcurrentTasks {
                    if let result = try await group.next(), result != nil  {
                        group.cancelAll()
                        return result
                    }
                }

                group.addTask(priority: priority) {
                    try await predicate(element) ? element : nil
                }
            }

            for try await result in group where result != nil {
                group.cancelAll()
                return result
            }

            return nil
        }
    }
}
