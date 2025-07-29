import AsyncOperations
import Foundation

extension SequenceChunksV1 {
    public func v1ChunkedMap<T: Sendable>(
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
    
    public func v1Map<T: Sendable>(
        numberOfConcurrentTasks: Int = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        let chunkedResult = try await v1ChunkedMap(
            priority: priority,
            transform
        )
        return chunkedResult.chunks.flatMap { $0 }
    }
}
