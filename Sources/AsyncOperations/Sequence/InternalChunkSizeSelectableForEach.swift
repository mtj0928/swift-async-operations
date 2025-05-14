//
//  Copyright © 2025 Taichone. All rights reserved.
//
     

extension Sequence where Element: Sendable {
    public func internalForEach<T: Sendable>(
        group: inout ThrowingOrderedTaskGroup<[T], any Error>,
        numberOfConcurrentTasks: UInt,
        priority: TaskPriority?,
        chunkSize: UInt,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: (T) -> ()
    ) async throws {
        // チャンクに分割して処理
        var currentChunk: [Element] = []
        
        for (index, element) in self.enumerated() {
            currentChunk.append(element)
            
            // チャンクサイズに達したか、最後の要素の場合
            if currentChunk.count == chunkSize || index == Array(self).count - 1 {
                // タスク数が上限を超えているなら、結果を処理
                if index >= numberOfConcurrentTasks {
                    if let values = try await group.next() {
                        for value in values {
                            nextOperation(value)
                        }
                    }
                }
                
                let chunkToProcess = currentChunk // Sendable
                group.addTask(priority: priority) {
                    // chunk 内を同期処理
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
