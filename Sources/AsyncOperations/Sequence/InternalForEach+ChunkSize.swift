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
    public func internalForEach<T: Sendable>(
        group: inout ThrowingOrderedTaskGroup<[T], any Error>,
        numberOfConcurrentTasks: UInt,
        priority: TaskPriority?,
        chunkSize: UInt,
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

    /// An internal function that processes elements in chunks without limiting concurrent tasks.
    /// No limit on the number of concurrent tasks.
    /// - Parameters:
    ///   - group: A throwing ordered task group to add tasks to.
    ///   - priority: A priority of the task.
    ///   - chunkSize: A size of chunk for processing elements.
    ///   - taskOperation: An operation to perform on each element.
    ///   - nextOperation: A closure to execute with the result of each operation.
    public func internalForEach<T: Sendable>(
        group: inout ThrowingOrderedTaskGroup<[T], any Error>,
        priority: TaskPriority?,
        chunkSize: UInt,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: (T) -> ()
    ) async throws {
        var currentChunk: [Element] = []
        let elementsCount = Array(self).count
        
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
}
