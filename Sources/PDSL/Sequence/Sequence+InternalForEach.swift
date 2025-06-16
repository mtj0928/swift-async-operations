import AsyncOperations

extension Sequence where Element: Sendable {
    /// An internal function that processes elements in chunks with a specified limit on concurrent tasks.
    /// - Parameters:
    ///   - group: A throwing ordered task group to add tasks to.
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. The operation is limited to this number of parallel executions.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - chunkSize: A size of chunk for processing elements.
    ///   - taskOperation: An operation to perform on each element.
    ///   - nextOperation: A closure to execute with the result of each operation.
    public func pdslInternalForEach<T: Sendable>(
        group: inout ThrowingOrderedTaskGroup<[T], any Error>,
        numberOfConcurrentTasks: Int,
        priority: TaskPriority?,
        chunkSize: Int? = nil,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: (T) -> ()
    ) async throws {
        var currentChunk: [Element] = []
        let elementsCount = Array(self).count
        var availableConcurrentTasks = numberOfConcurrentTasks
        
        for (index, element) in self.enumerated() {
            currentChunk.append(element)
            if currentChunk.count == chunkSize || index == elementsCount - 1 {
                
                if availableConcurrentTasks == 0 {
                    if let values = try await group.next() {
                        for value in values {
                            nextOperation(value)
                        }
                    }
                } else {
                    availableConcurrentTasks -= 1
                }
                
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
