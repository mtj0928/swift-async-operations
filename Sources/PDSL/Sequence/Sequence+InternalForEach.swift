import AsyncOperations

extension Sequence where Element: Sendable, Self: Sendable {
    /// 標準の ThrowingTaskGroup を利用
    public func pInternalForEach<T: Sendable>(
        chunkSize: Int? = nil,
        priority: TaskPriority? = nil,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: (T) -> ()
    ) async rethrows {
        try await withThrowingTaskGroup(of: (startIndex: Int, results: [T]).self) { group in
            var currentChunk: [Element] = []
            let elementsCount = Array(self).count
            let chunkSize: Int = chunkSize ?? (elementsCount / numberOfConcurrentTasks)
            
            for (index, element) in self.enumerated() {
                currentChunk.append(element)
                if currentChunk.count == chunkSize || index == elementsCount - 1 {
                    let chunkToProcess = currentChunk
                    let startIndex = index - currentChunk.count + 1
                    group.addTask(priority: priority) {
                        var results: [T] = []
                        for element in chunkToProcess {
                            let result = try await taskOperation(element)
                            results.append(result)
                        }
                        return (startIndex: startIndex, results: results)
                    }
                    currentChunk = []
                }
            }
            
            var chunkedResults: [(startIndex: Int, results: [T])] = []
            for try await chunkResult in group {
                chunkedResults.append(chunkResult)
            }

            // startIndex でソート
            chunkedResults.sort { $0.startIndex < $1.startIndex }
            
            // 順序を保持して nextOperation を呼び出し
            for chunkResult in chunkedResults {
                for value in chunkResult.results {
                    nextOperation(value)
                }
            }
        }
    }
    
    /// 標準の ThrowingTaskGroup を利用（並行タスク数制限付き）
    public func pInternalForEach<T: Sendable>(
        numberOfConcurrentTasks: Int,
        chunkSize: Int? = nil,
        priority: TaskPriority? = nil,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: (T) -> ()
    ) async rethrows {
        try await withThrowingTaskGroup(of: (startIndex: Int, results: [T]).self) { group in
            var currentChunk: [Element] = []
            let elementsCount = Array(self).count
            let chunkSize: Int = chunkSize ?? (elementsCount / numberOfConcurrentTasks + 1)
            var availableConcurrentTasks = numberOfConcurrentTasks
            var pendingResults: [(startIndex: Int, results: [T])] = []
            var nextExpectedIndex = 0
            
            for (index, element) in self.enumerated() {
                currentChunk.append(element)
                if currentChunk.count == chunkSize || index == elementsCount - 1 {
                    
                    if availableConcurrentTasks == 0 {
                        if let chunkResult = try await group.next() {
                            pendingResults.append(chunkResult)
                            
                            // 順序を保持して処理可能な結果を nextOperation に渡す
                            pendingResults.sort { $0.startIndex < $1.startIndex }
                            while !pendingResults.isEmpty && pendingResults.first!.startIndex == nextExpectedIndex {
                                let result = pendingResults.removeFirst()
                                for value in result.results {
                                    nextOperation(value)
                                }
                                nextExpectedIndex += result.results.count
                            }
                        }
                    } else {
                        availableConcurrentTasks -= 1
                    }
                    
                    let chunkToProcess = currentChunk
                    let startIndex = index - currentChunk.count + 1
                    group.addTask(priority: priority) {
                        var results: [T] = []
                        for element in chunkToProcess {
                            let result = try await taskOperation(element)
                            results.append(result)
                        }
                        return (startIndex: startIndex, results: results)
                    }
                    currentChunk = []
                }
            }
            
            // 残りの結果を処理
            for try await chunkResult in group {
                pendingResults.append(chunkResult)
            }
            
            // 最終的な順序でソートして処理
            pendingResults.sort { $0.startIndex < $1.startIndex }
            for chunkResult in pendingResults {
                for value in chunkResult.results {
                    nextOperation(value)
                }
            }
        }
    }
    
    public func pOldInternalForEach<T: Sendable>(
        chunkSize: Int? = nil,
        priority: TaskPriority? = nil,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: (T) -> ()
    ) async rethrows {
        try await withThrowingTaskGroup(of: [(index: Int, result: T)].self) { group in
            var currentChunk: [(index: Int, element: Element)] = []
            let elementsCount = Array(self).count
            let chunkSize: Int = chunkSize ?? (elementsCount / numberOfConcurrentTasks + 1)
            
            for (index, element) in self.enumerated() {
                currentChunk.append((index: index, element: element))
                if currentChunk.count == chunkSize || index == elementsCount - 1 {
                    let chunkToProcess = currentChunk
                    group.addTask(priority: priority) {
                        var results: [(index: Int, result: T)] = []
                        for item in chunkToProcess {
                            let result = try await taskOperation(item.element)
                            results.append((index: item.index, result: result))
                        }
                        return results
                    }
                    currentChunk = []
                }
            }
            
            var allResults: [(index: Int, result: T)] = []
            for try await chunkResult in group {
                allResults.append(contentsOf: chunkResult)
            }

            // 全要素を index でソート（良くない実装）
            allResults.sort { $0.index < $1.index }
            
            // 順序を保持して nextOperation を呼び出し
            for item in allResults {
                nextOperation(item.result)
            }
        }
    }
    
    /// 標準の ThrowingTaskGroup を利用（並行タスク数制限付き）
    public func pOldInternalForEach<T: Sendable>(
        numberOfConcurrentTasks: Int,
        chunkSize: Int? = nil,
        priority: TaskPriority? = nil,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: (T) -> ()
    ) async rethrows {
        try await withThrowingTaskGroup(of: [(index: Int, result: T)].self) { group in
            var currentChunk: [(index: Int, element: Element)] = []
            let elementsCount = Array(self).count
            let chunkSize: Int = chunkSize ?? (elementsCount / numberOfConcurrentTasks + 1)
            var availableConcurrentTasks = numberOfConcurrentTasks
            var allResults: [(index: Int, result: T)] = []
            
            for (index, element) in self.enumerated() {
                currentChunk.append((index: index, element: element))
                if currentChunk.count == chunkSize || index == elementsCount - 1 {
                    
                    if availableConcurrentTasks == 0 {
                        if let chunkResult = try await group.next() {
                            allResults.append(contentsOf: chunkResult)
                        }
                    } else {
                        availableConcurrentTasks -= 1
                    }
                    
                    let chunkToProcess = currentChunk
                    group.addTask(priority: priority) {
                        var results: [(index: Int, result: T)] = []
                        for item in chunkToProcess {
                            let result = try await taskOperation(item.element)
                            results.append((index: item.index, result: result))
                        }
                        return results
                    }
                    currentChunk = []
                }
            }
            
            // 残りの結果を処理
            for try await chunkResult in group {
                allResults.append(contentsOf: chunkResult)
            }
            
            // 全要素を index でソート（良くない実装）
            allResults.sort { $0.index < $1.index }
            
            // 順序を保持して nextOperation を呼び出し
            for item in allResults {
                nextOperation(item.result)
            }
        }
    }
    
    
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
        let chunkSize: Int = chunkSize ?? (elementsCount / numberOfConcurrentTasks + 1)
        
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
    
    /// タスクの結果の取り出し順 == タスクの生成順
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
