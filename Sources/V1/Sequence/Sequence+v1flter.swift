import AsyncOperations

extension Sequence where Element: Sendable, Self: Sendable {
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
        numberOfConcurrentTasks: Int = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        chunkSize: Int? = nil,
        _ isIncluded: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> [Element] {
        try await withThrowingOrderedTaskGroup(of: [Element?].self) { group in
            var values: [Element] = []

            try await v1internalForEach(
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

    /// An async function of `filter` that returns chunked results.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `isIncluded` closure run in parallel when the value is 2 or more.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - chunkSize: A size of chunk for processing elements.
    ///   - isIncluded: A similar closure with `filter`'s one, but it's async.
    /// - Returns: A chunked array.
    public func pdslChunkedFilter(
        numberOfConcurrentTasks: Int = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        chunkSize: Int? = nil,
        _ isIncluded: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> ChunkedArray<Element> {
        try await withThrowingOrderedTaskGroup(of: [Element?].self) { group in
            var chunkedValues: [[Element]] = []

            try await v1internalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                chunkSize: chunkSize,
                taskOperation: {
                    value in try await isIncluded(value) ? value : nil
                }
            ) { _ in }

            for try await chunk in group {
                let filteredChunk = chunk.compactMap { $0 }
                if !filteredChunk.isEmpty {
                    chunkedValues.append(filteredChunk)
                }
            }

            return ChunkedArray(chunks: chunkedValues)
        }
    }
}
