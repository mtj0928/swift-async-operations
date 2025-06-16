import AsyncOperations
import Foundation

extension SequenceChunks {
    /// Transforms each element with given closure and returns chunked results.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks.
    ///   - priority: The priority of the operation task.
    ///   - transform: A transform closure.
    /// - Returns: A chunked array.
    public func pdslChunkedMap<T: Sendable>(
        numberOfConcurrentTasks: UInt = sequenceChunksDefaultConcurrentTasks,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> ChunkedArray<T> {
        try await withThrowingOrderedTaskGroup(of: [T].self) { group in
            var resultChunks: [[T]] = []
            
            for chunk in chunks {
                group.addTask(priority: priority) {
                    var transformedChunk: [T] = []
                    for element in chunk {
                        let result = try await transform(element)
                        transformedChunk.append(result)
                    }
                    return transformedChunk
                }
            }
            
            for try await transformedChunk in group {
                resultChunks.append(transformedChunk)
            }
            
            return ChunkedArray(chunks: resultChunks)
        }
    }
    
    /// Transforms each element with given closure and returns a flattened array.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks.
    ///   - priority: The priority of the operation task.
    ///   - transform: A transform closure.
    /// - Returns: A flattened array.
    public func pdslMap<T: Sendable>(
        numberOfConcurrentTasks: UInt = sequenceChunksDefaultConcurrentTasks,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        let chunkedResult = try await pdslChunkedMap(
            numberOfConcurrentTasks: numberOfConcurrentTasks,
            priority: priority,
            transform
        )
        return chunkedResult.chunks.flatMap { $0 }
    }
} 