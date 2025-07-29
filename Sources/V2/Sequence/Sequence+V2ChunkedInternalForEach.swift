//
//  Copyright © 2025 Taichone. All rights reserved.
//


extension Sequence where Element: Sendable, Self: Sendable {
    
    /// 並行タスク数無制限
    public func v2ChunkedInternalForEach<T: Sendable>(
        chunkSize: Int? = nil,
        priority: TaskPriority? = nil,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: ((startIndex: Int, chunk: [T])) -> ()
    ) async rethrows {
        try await withThrowingTaskGroup(of: (startIndex: Int, chunk: [T]).self) { group in
            var currentChunk: [Element] = []
            let elementsCount = Array(self).count
            let chunkSize: Int = chunkSize ?? (elementsCount / numberOfConcurrentTasks)
            
            for (index, element) in self.enumerated() {
                currentChunk.append(element)
                
                // chunkSize 溜まるか、最後の要素に到達した場合
                if currentChunk.count == chunkSize || index == elementsCount - 1 {
                    let sendableChunk = currentChunk // Sendable
                    let startIndex = index - currentChunk.count + 1
                    
                    // (startIndex, 処理後の chunk) を得る Task を TaskGroup に追加
                    group.addTask(priority: priority) {
                        var resultChunk: [T] = []
                        for element in sendableChunk {
                            let resultElement = try await taskOperation(element)
                            resultChunk.append(resultElement)
                        }
                        return (startIndex: startIndex, chunk: resultChunk)
                    }
                    
                    currentChunk = []
                }
            }
            
            // (startIndex, 処理後の chunk) を nextOperation に渡す
            for try await chunk in group {
                nextOperation(chunk)
            }
        }
    }
    
    /// 並行タスク数制限の機構あり
    public func v2ChunkedInternalForEach<T: Sendable>(
        numberOfConcurrentTasks: Int,
        chunkSize: Int? = nil,
        priority: TaskPriority? = nil,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: ((startIndex: Int, chunk: [T])) -> ()
    ) async rethrows {
        try await withThrowingTaskGroup(of: (startIndex: Int, chunk: [T]).self) { group in
            var currentChunk: [Element] = []
            let elementsCount = Array(self).count
            let chunkSize: Int = chunkSize ?? (elementsCount / numberOfConcurrentTasks + 1)
            var availableConcurrentTasks = numberOfConcurrentTasks
            
            for (index, element) in self.enumerated() {
                currentChunk.append(element)
                if currentChunk.count == chunkSize || index == elementsCount - 1 {
                    
                    if availableConcurrentTasks == 0 {
                        if let chunkResult = try await group.next() {
                            nextOperation(chunkResult)
                        }
                    } else {
                        availableConcurrentTasks -= 1
                    }
                    
                    let sendableChunk = currentChunk // Sendable
                    let startIndex = index - currentChunk.count + 1
                    
                    group.addTask(priority: priority) {
                        var resultChunk: [T] = []
                        for element in sendableChunk {
                            let resultElement = try await taskOperation(element)
                            resultChunk.append(resultElement)
                        }
                        return (startIndex: startIndex, chunk: resultChunk)
                    }
                    
                    currentChunk = []
                }
            }
            
            for try await chunk in group {
                nextOperation(chunk)
            }
        }
    }
}
