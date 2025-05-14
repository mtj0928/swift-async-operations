extension Sequence where Element: Sendable {
    /// チャンクサイズ指定可能な asyncFirst。
    /// - Parameters:
    ///   - chunkSize: 各チャンクで並列に処理する要素数。
    ///   - priority: タスクの優先度。
    ///   - predicate: async で判定する述語クロージャ。
    /// - Returns: 条件を満たす最初の要素。なければ nil。
    public func asyncFirst(
        chunkSize: Int,
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Element? {
        let elements = Array(self)
        let chunks = stride(from: 0, to: elements.count, by: chunkSize).map {
            Array(elements[$0..<Swift.min($0 + chunkSize, elements.count)])
        }
        
        return try await withThrowingTaskGroup(of: Element?.self) { group in
            for chunk in chunks {
                group.addTask(priority: priority) {
                    for element in chunk {
                        if try await predicate(element) {
                            return element
                        }
                    }
                    return nil
                }
            }
            
            for try await result in group where result != nil {
                group.cancelAll()
                return result
            }
            
            return nil
        }
    }
} 