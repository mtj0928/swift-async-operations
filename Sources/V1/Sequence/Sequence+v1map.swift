import AsyncOperations

extension Sequence where Element: Sendable, Self: Sendable {
    /// An async function of `map` with chunk size control.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `transform` closure run in parallel when the value is 2 or more.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - chunkSize: A size of chunk for processing elements.
    ///   - transform: A similar closure with `map`'s one, but it's async.
    /// - Returns: A transformed array.
    public func v1map<T: Sendable>(
        numberOfConcurrentTasks: Int = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        chunkSize: Int? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        try await withThrowingOrderedTaskGroup(of: [T].self) { group in
            var values: [T] = []

            try await v1internalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                chunkSize: chunkSize,
                taskOperation: transform
            ) { value in
                values.append(value)
            }

            return values
        }
    }

    /// An async function of `map` with chunk size control that returns chunked results.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `transform` closure run in parallel when the value is 2 or more.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - chunkSize: A size of chunk for processing elements.
    ///   - transform: A similar closure with `map`'s one, but it's async.
    /// - Returns: A chunked array.
    public func v1ChunkedMap<T: Sendable>(
        priority: TaskPriority? = nil,
        chunkSize: Int? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> ChunkedArray<T> {
        try await withThrowingOrderedTaskGroup(of: [T].self) { group in
            var resultChunks: [[T]] = []

            try await pdslChunkedInternalForEach(
                group: &group,
                priority: priority,
                chunkSize: chunkSize,
                taskOperation: transform
            ) {
                resultChunks.append($0)
            }

            return ChunkedArray(chunks: resultChunks)
        }
    }
}

