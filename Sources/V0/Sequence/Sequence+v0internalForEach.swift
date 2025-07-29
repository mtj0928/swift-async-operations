//
//  Copyright © 2025 Taichone. All rights reserved.
//

extension Sequence where Element: Sendable, Self: Sendable {
    public func v0InternalForEach<T: Sendable>(
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
    public func v0internalForEach<T: Sendable>(
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
}
