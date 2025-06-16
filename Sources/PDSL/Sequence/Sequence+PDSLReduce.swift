extension Sequence where Element: Sendable {
    /// An async function of `reduce` with chunk size.
    public func pdslReduce<Result: Sendable>(
        _ initialResult: Result,
        chunkSize: Int,
        priority: TaskPriority? = nil,
        _ nextPartialResult: @escaping @Sendable (Result, Element) async throws -> Result
    ) async rethrows -> Result {
        let array = Array(self)
        let chunks = stride(from: 0, to: array.count, by: chunkSize).map {
            Array(array[$0..<Swift.min($0 + chunkSize, array.count)])
        }
        
        var result = initialResult
        for chunk in chunks {
            let currentResult = result
            result = try await withThrowingTaskGroup(of: Result.self) { group in
                group.addTask(priority: priority) { @Sendable in
                    var chunkResult = currentResult
                    for element in chunk {
                        chunkResult = try await nextPartialResult(chunkResult, element)
                    }
                    return chunkResult
                }
                
                return try await group.next() ?? currentResult
            }
        }
        
        return result
    }
    
    /// An async function of `reduce` with chunk size.
    public func pdslReduce<Result: Sendable>(
        into initialResult: Result,
        chunkSize: Int,
        priority: TaskPriority? = nil,
        _ updateAccumulatingResult: @escaping @Sendable (inout Result, Element) async throws -> ()
    ) async rethrows -> Result {
        let array = Array(self)
        let chunks = stride(from: 0, to: array.count, by: chunkSize).map {
            Array(array[$0..<Swift.min($0 + chunkSize, array.count)])
        }
        
        var result = initialResult
        for chunk in chunks {
            let currentResult = result
            result = try await withThrowingTaskGroup(of: Result.self) { group in
                group.addTask(priority: priority) { @Sendable in
                    var chunkResult = currentResult
                    for element in chunk {
                        try await updateAccumulatingResult(&chunkResult, element)
                    }
                    return chunkResult
                }
                
                return try await group.next() ?? currentResult
            }
        }
        
        return result
    }

    /// An async function of `reduce` that returns chunked result.
    /// - Parameters:
    ///   - chunkSize: The number of elements to process in each chunk.
    ///   - initialResult: The initial result value.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - nextPartialResult: A closure that combines the previous result with the next element.
    /// - Returns: A chunked array containing the result. Since reduce returns a single value, this returns a chunk with one element.
    public func pdslChunkedReduce<Result: Sendable>(
        chunkSize: Int,
        _ initialResult: Result,
        priority: TaskPriority? = nil,
        _ nextPartialResult: @escaping @Sendable (Result, Element) async throws -> Result
    ) async rethrows -> ChunkedArray<Result> {
        let result = try await pdslReduce(initialResult, chunkSize: chunkSize, priority: priority, nextPartialResult)
        return ChunkedArray(chunks: [[result]])
    }
    
    /// An async function of `reduce` into chunked result.
    /// - Parameters:
    ///   - chunkSize: The number of elements to process in each chunk.
    ///   - initialResult: The initial result value to start with.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - updateAccumulatingResult: A closure that updates the accumulating result with each element.
    /// - Returns: A chunked array containing the result. Since reduce returns a single value, this returns a chunk with one element.
    public func pdslChunkedReduce<Result: Sendable>(
        chunkSize: Int,
        into initialResult: Result,
        priority: TaskPriority? = nil,
        _ updateAccumulatingResult: @escaping @Sendable (inout Result, Element) async throws -> ()
    ) async rethrows -> ChunkedArray<Result> {
        let result = try await pdslReduce(into: initialResult, chunkSize: chunkSize, priority: priority, updateAccumulatingResult)
        return ChunkedArray(chunks: [[result]])
    }
}
