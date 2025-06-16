import AsyncOperations

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
    public func pdslFlatMap<T: Sendable>(
        numberOfConcurrentTasks: Int = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        chunkSize: Int? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> [T]
    ) async rethrows -> [T] {
        try await withThrowingOrderedTaskGroup(of: [[T]].self) { group in
            var values: [T] = []

            try await pdslInternalForEach(
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

    /// An async function of `flatMap` with chunk size control that returns chunked results.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `transform` closure run in parallel when the value is 2 or more.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - chunkSize: A size of chunk for processing elements.
    ///   - transform: A similar closure with `flatMap`'s one, but it's async.
    /// - Returns: A chunked array.
    public func pdslChunkedFlatMap<T: Sendable>(
        numberOfConcurrentTasks: Int = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        chunkSize: Int? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> [T]
    ) async rethrows -> ChunkedArray<T> {
        try await withThrowingOrderedTaskGroup(of: [[T]].self) { group in
            var chunkedValues: [[T]] = []

            try await pdslInternalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                chunkSize: chunkSize,
                taskOperation: transform
            ) { _ in }

            for try await chunk in group {
                let flattenedChunk = chunk.flatMap { $0 }
                if !flattenedChunk.isEmpty {
                    chunkedValues.append(flattenedChunk)
                }
            }

            return ChunkedArray(chunks: chunkedValues)
        }
    }
}
