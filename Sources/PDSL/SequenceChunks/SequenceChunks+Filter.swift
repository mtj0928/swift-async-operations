import AsyncOperations
import Foundation

extension SequenceChunks {
    /// Filters each element with given predicate and returns chunked results.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks.
    ///   - priority: The priority of the operation task.
    ///   - predicate: A predicate closure.
    /// - Returns: A chunked array.
    public func pdslChunkedFilter(
        numberOfConcurrentTasks: UInt = sequenceChunksDefaultConcurrentTasks,
        priority: TaskPriority? = nil,
        _ predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> ChunkedArray<Element> {
        try await withThrowingOrderedTaskGroup(of: [Element].self) { group in
            var resultChunks: [[Element]] = []
            
            for chunk in chunks {
                group.addTask(priority: priority) {
                    var filteredChunk: [Element] = []
                    for element in chunk {
                        if try await predicate(element) {
                            filteredChunk.append(element)
                        }
                    }
                    return filteredChunk
                }
            }
            
            for try await filteredChunk in group {
                if !filteredChunk.isEmpty {
                    resultChunks.append(filteredChunk)
                }
            }
            
            return ChunkedArray(chunks: resultChunks)
        }
    }
    
    /// Filters each element with given predicate and returns a flattened array.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks.
    ///   - priority: The priority of the operation task.
    ///   - predicate: A predicate closure.
    /// - Returns: A flattened array.
    public func pdslFilter(
        numberOfConcurrentTasks: UInt = sequenceChunksDefaultConcurrentTasks,
        priority: TaskPriority? = nil,
        _ predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> [Element] {
        let chunkedResult = try await pdslChunkedFilter(
            numberOfConcurrentTasks: numberOfConcurrentTasks,
            priority: priority,
            predicate
        )
        return chunkedResult.chunks.flatMap { $0 }
    }
} 