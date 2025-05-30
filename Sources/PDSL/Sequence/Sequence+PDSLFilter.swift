import AsyncOperations

extension Sequence where Element: Sendable {
    /// An async function of `filter`.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `isIncluded` closure run in parallel when the value is 2 or more.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - chunkSize: A size of chunk for processing elements.
    ///   - isIncluded: A similar closure with `filter`'s one, but it's async.
    /// - Returns: A filtered array which has only elements which satisfy the `isIncluded`.
    public func pdslFilter(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        chunkSize: UInt,
        _ isIncluded: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> [Element] {
        try await withThrowingOrderedTaskGroup(of: [Element?].self) { group in
            var values: [Element] = []

            try await pdslInternalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                chunkSize: chunkSize,
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
