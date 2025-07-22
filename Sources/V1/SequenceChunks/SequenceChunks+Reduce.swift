import AsyncOperations
import Foundation

extension SequenceChunks {
    /// Reduces the sequence to a single value using the given initial result and combining closure.
    /// - Parameters:
    ///   - initialResult: The initial result value.
    ///   - priority: The priority of the operation task.
    ///   - nextPartialResult: A closure that combines the previous result with the next element.
    /// - Returns: The final reduced value.
    public func pdslReduce<Result: Sendable>(
        _ initialResult: Result,
        priority: TaskPriority? = nil,
        _ nextPartialResult: @escaping @Sendable (Result, Element) async throws -> Result
    ) async rethrows -> Result {
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
    
    /// Reduces the sequence into a single value using an initial result and a closure that modifies it.
    /// - Parameters:
    ///   - initialResult: The initial result value to start with.
    ///   - priority: The priority of the operation task.
    ///   - updateAccumulatingResult: A closure that updates the accumulating result with each element.
    /// - Returns: The final reduced value.
    public func pdslReduce<Result: Sendable>(
        into initialResult: Result,
        priority: TaskPriority? = nil,
        _ updateAccumulatingResult: @escaping @Sendable (inout Result, Element) async throws -> ()
    ) async rethrows -> Result {
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
