import AsyncOperations
import Foundation

extension SequenceChunks {
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
