extension Sequence where Element: Sendable {
    /// チャンクサイズ指定可能な asyncFirst。
    /// - Parameters:
    ///   - chunkSize: 各チャンクで並列に処理する要素数。
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - predicate: async で判定する述語クロージャ。
    /// - Returns: 条件を満たす最初の要素。なければ nil。
    public func pdslFirst(
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

    /// チャンクサイズ指定可能な asyncFirst that returns chunked results。
    /// - Parameters:
    ///   - chunkSize: 各チャンクで並列に処理する要素数。
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - predicate: async で判定する述語クロージャ。
    /// - Returns: チャンクサイズでチャンクされた配列。ただし、firstの場合は条件を満たす最初の要素のみを含む単一のチャンクを返します。
    public func pdslChunkedFirst(
        chunkSize: Int,
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> ChunkedArray<Element> {
        if let firstElement = try await pdslFirst(chunkSize: chunkSize, priority: priority, where: predicate) {
            return ChunkedArray(chunks: [[firstElement]])
        } else {
            return ChunkedArray(chunks: [])
        }
    }
}
