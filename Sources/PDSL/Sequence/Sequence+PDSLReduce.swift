extension Sequence where Element: Sendable, Self: Sendable {
    /// An async function of `reduce` with chunk size.
    public func pdslReduce<Result: Sendable>(
        _ initialResult: Result,
        chunkSize: Int? = nil,
        priority: TaskPriority? = nil,
        _ nextPartialResult: @escaping @Sendable (Result, Element) async throws -> Result
    ) async rethrows -> Result {
        let elements = Array(self)
        let elementsCount = elements.count
        let chunkSize = chunkSize ?? (elementsCount / numberOfConcurrentTasks + 1)
        let chunks = stride(from: 0, to: elementsCount, by: chunkSize).map {
            Array(elements[$0..<Swift.min($0 + chunkSize, elementsCount)])
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
        chunkSize: Int? = nil,
        priority: TaskPriority? = nil,
        _ updateAccumulatingResult: @escaping @Sendable (inout Result, Element) async throws -> ()
    ) async rethrows -> Result {
        let elements = Array(self)
        let elementsCount = elements.count
        let chunkSize = chunkSize ?? (elementsCount / numberOfConcurrentTasks + 1)
        let chunks = stride(from: 0, to: elementsCount, by: chunkSize).map {
            Array(elements[$0..<Swift.min($0 + chunkSize, elementsCount)])
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
}
