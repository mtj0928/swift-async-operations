//
//  Copyright © 2025 Taichone. All rights reserved.
//
     

extension Sequence where Element: Sendable {
    public func internalForEach<T: Sendable, U: Sendable>(
        group: inout ThrowingOrderedTaskGroup<[T], any Error>,
        numberOfConcurrentTasks: UInt,
        priority: TaskPriority?,
        chunkSize: UInt,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        chunkOperation: @escaping @Sendable ([T]) async throws -> U,
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
                
                // チャンク全体を1つのタスクとして追加
                let chunkToProcess = currentChunk
                group.addTask(priority: priority) {
                    // チャンク内の各要素を処理し、結果を配列として返す
                    var results: [T] = []
                    for element in chunkToProcess {
                        let result = try await taskOperation(element)
                        results.append(result)
                    }

                    // ここに、 ([T]) -> U を入れる
                    return results
                }
                
                currentChunk = []  // チャンクをリセット
            }
        }
        
        // 残りの結果を処理
        for try await values: [T] in group {
            for value in values {
                nextOperation(value)
            }
        }
    }
}
