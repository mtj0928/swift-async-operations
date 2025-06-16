import AsyncOperations
import Foundation

extension SequenceChunks {
    /// Transforms each element to an array and flattens, returns chunked results.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks.
    ///   - priority: The priority of the operation task.
    ///   - transform: A transform closure that returns an array.
    /// - Returns: A chunked array.
    public func pdslChunkedFlatMap<T: Sendable>(
        numberOfConcurrentTasks: UInt = sequenceChunksDefaultConcurrentTasks,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> [T]
    ) async rethrows -> ChunkedArray<T> {
        try await withThrowingOrderedTaskGroup(of: [T].self) { group in
            var resultChunks: [[T]] = []
            
            for chunk in chunks {
                group.addTask(priority: priority) {
                    var flatMappedChunk: [T] = []
                    for element in chunk {
                        let results = try await transform(element)
                        flatMappedChunk.append(contentsOf: results)
                    }
                    return flatMappedChunk
                }
            }
            
            for try await transformedChunk in group {
                if !transformedChunk.isEmpty {
                    resultChunks.append(transformedChunk)
                }
            }
            
            return ChunkedArray(chunks: resultChunks)
        }
    }
    
    /// Transforms each element to an array and flattens, returns a flattened array.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks.
    ///   - priority: The priority of the operation task.
    ///   - transform: A transform closure that returns an array.
    /// - Returns: A flattened array.
    public func pdslFlatMap<T: Sendable>(
        numberOfConcurrentTasks: UInt = sequenceChunksDefaultConcurrentTasks,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> [T]
    ) async rethrows -> [T] {
        let chunkedResult = try await pdslChunkedFlatMap(
            numberOfConcurrentTasks: numberOfConcurrentTasks,
            priority: priority,
            transform
        )
        return chunkedResult.chunks.flatMap { $0 }
    }
} 