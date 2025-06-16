import AsyncOperations

extension Sequence where Element: Sendable {
    /// An async function of `forEach` with chunk size control.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `body` closure run in parallel when the value is 2 or more.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - chunkSize: A size of chunk for processing elements.
    ///   - body: A similar closure with `forEach`'s one, but it's async.
    public func pdslForEach(
        numberOfConcurrentTasks: Int = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        chunkSize: Int? = nil,
        _ body: @escaping @Sendable (Element) async throws -> Void
    ) async rethrows {
        try await withThrowingOrderedTaskGroup(of: [Void].self) { group in
            try await pdslInternalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                chunkSize: chunkSize,
                taskOperation: body,
                nextOperation: { /* Do nothing */ }
            )
        }
    }
}
