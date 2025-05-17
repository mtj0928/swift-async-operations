extension Sequence where Element: Sendable {
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
            
            // チャンクサイズに達した or 最後の要素: addTask
            if currentChunk.count == chunkSize || index == elementsCount - 1 {
                // タスク数が上限に達している場合は、1つの結果が出るのを待ってから
                if availableConcurrentTasks == 0 {
                    if let values = try await group.next() {
                        for value in values {
                            nextOperation(value)
                        }
                    }
                } else {
                    availableConcurrentTasks -= 1
                }
                
                let chunkToProcess = currentChunk // Sendable
                group.addTask(priority: priority) {
                    // chunk 内は同期処理
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
        
        // 残りの結果を処理
        for try await values: [T] in group {
            // TODO: 将来的には配列のまま接続するオプションも検討
            for value in values {
                nextOperation(value)
            }
        }
    }
}
