extension Sequence where Element: Sendable {
    /// An async function of `flatMap` with chunk size control.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `transform` closure run in parallel when the value is 2 or more.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - chunkSize: A size of chunk for processing elements.
    ///   - transform: A similar closure with `flatMap`'s one, but it's async.
    /// - Returns: A transformed array.
    public func asyncFlatMap<T: Sendable>(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        chunkSize: UInt,
        _ transform: @escaping @Sendable (Element) async throws -> [T]
    ) async rethrows -> [T] {
        try await withThrowingOrderedTaskGroup(of: [[T]].self) { group in
            var values: [T] = []

            try await internalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                chunkSize: chunkSize,
                taskOperation: transform
            ) { results in
                values.append(contentsOf: results)
            }

            return values
        }
    }
}
