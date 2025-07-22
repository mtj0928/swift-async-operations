import AsyncOperations

extension Sequence where Element: Sendable, Self: Sendable {
    public func pdslInternalForEach<T: Sendable>(
        group: inout ThrowingOrderedTaskGroup<[T], any Error>,
        priority: TaskPriority?,
        chunkSize: Int? = nil,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: (T) -> ()
    ) async throws {
        var currentChunk: [Element] = []
        let elementsCount = Array(self).count
        let chunkSize: Int = chunkSize ?? (elementsCount / numberOfConcurrentTasks + 1)
        
        for (index, element) in self.enumerated() {
            currentChunk.append(element)
            if currentChunk.count == chunkSize || index == elementsCount - 1 {
                let chunkToProcess = currentChunk
                group.addTask(priority: priority) {
                    var results: [T] = []
                    for element in chunkToProcess {
                        let result = try await taskOperation(element)
                        results.append(result)
                    }
                    return results
                }
                currentChunk = []
            }
        }
        
        for try await values: [T] in group {
            for value in values {
                nextOperation(value)
            }
        }
    }
    
    public func pdslChunkedInternalForEach<T: Sendable>(
        group: inout ThrowingOrderedTaskGroup<[T], any Error>,
        priority: TaskPriority?,
        chunkSize: Int? = nil,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: ([T]) -> ()
    ) async throws {
        var currentChunk: [Element] = []
        let elementsCount = Array(self).count
        let chunkSize: Int = chunkSize ?? (elementsCount / numberOfConcurrentTasks + 1)
        
        for (index, element) in self.enumerated() {
            currentChunk.append(element)
            if currentChunk.count == chunkSize || index == elementsCount - 1 {
                let chunkToProcess = currentChunk
                group.addTask(priority: priority) {
                    var results: [T] = []
                    for element in chunkToProcess {
                        let result = try await taskOperation(element)
                        results.append(result)
                    }
                    return results
                }
                currentChunk = []
            }
        }
        
        for try await chunk: [T] in group {
            nextOperation(chunk)
        }
    }
}
