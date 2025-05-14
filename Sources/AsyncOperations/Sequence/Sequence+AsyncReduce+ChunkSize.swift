import Foundation

extension Sequence where Element: Sendable {
    /// An async function of `reduce` with chunk size.
    public func asyncReduce<Result: Sendable>(
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
    public func asyncReduce<Result: Sendable>(
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
} 
