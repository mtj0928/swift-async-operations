import AsyncOperations
import Foundation

extension SequenceChunks {
    /// Transforms each element with given closure and compacts, returns chunked results.
    /// - Parameters:
    ///   - priority: The priority of the operation task.
    ///   - transform: A transform closure that may return nil.
    /// - Returns: A chunked array.
    public func pdslChunkedCompactMap<T: Sendable>(
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T?
    ) async rethrows -> ChunkedArray<T> {
        let resultChunks = try await withThrowingOrderedTaskGroup(of: [T].self) { group in
            for chunk in chunks {
                group.addTask(priority: priority) {
                    var transformedChunk: [T] = []
                    for element in chunk {
                        if let result = try await transform(element) {
                            transformedChunk.append(result)
                        }
                    }
                    return transformedChunk
                }
            }
            
            var orderedResults: [[T]] = []
            for try await transformedChunk in group {
                orderedResults.append(transformedChunk)
            }
            return orderedResults
        }
        
        return ChunkedArray(chunks: resultChunks.filter { !$0.isEmpty })
    }
    
    /// Transforms each element with given closure and compacts, returns a flattened array.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks.
    ///   - priority: The priority of the operation task.
    ///   - transform: A transform closure that may return nil.
    /// - Returns: A flattened array.
    public func pdslCompactMap<T: Sendable>(
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T?
    ) async rethrows -> [T] {
        let chunkedResult = try await pdslChunkedCompactMap(
            priority: priority,
            transform
        )
        return chunkedResult.chunks.flatMap { $0 }
    }
}
