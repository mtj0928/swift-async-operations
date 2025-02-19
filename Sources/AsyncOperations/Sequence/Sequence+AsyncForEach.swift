extension Sequence where Element: Sendable {
    /// An async function of `forEach`.
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
            try await internalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                taskOperation: body,
                nextOperation: { /* Do nothing */ }
            )
        }
    }
}
