extension AsyncSequence where Element: Sendable {
    /// An async function of `forEach`.
    ///
    /// This is an example of a behavior.
    /// ```swift
    /// let asyncSequence = AsyncStream { c in
    ///     (0..<5).forEach { c.yield($0) }
    ///     c.finish()
    /// }
    /// await asyncSequence.asyncForEach(numberOfConcurrentTasks: 3) { @MainActor number in
    ///     print("Start: \(number)")
    ///     await Task.yield()
    ///     print("end: \(number)")
    /// }
    /// // Start: 0
    /// // Start: 1
    /// // Start: 2
    /// // End: 0
    /// // End: 1
    /// // Start: 3
    /// // End: 2
    /// // End: 3
    /// // Start: 4
    /// // End: 4
    /// ```
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `body` closure run in parallel when the value is 2 or more.
    ///   - priority: A priority of the giving closure.
    ///   - body: A similar closure with `forEach`'s one, but it's async.
    public func asyncForEach(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        _ body: @escaping @Sendable (Element) async throws -> Void
    ) async rethrows {
        try await withThrowingOrderedTaskGroup(of: Void.self) { group in
            var counter = 0
            var asyncIterator = self.makeAsyncIterator()
            while let element = try await asyncIterator.next() {
                if counter < numberOfConcurrentTasks {
                    group.addTask(priority: priority) {
                        try await body(element)
                    }
                    counter += 1
                } else {
                    try await group.next()
                    group.addTask(priority: priority) {
                        try await body(element)
                    }
                }
            }
        }
    }
}
