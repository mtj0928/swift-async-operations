extension Sequence where Element: Sendable {
    /// An async function of `allSatisfy` that processes elements in chunks.
    /// - Parameters:
    ///   - chunkSize: The number of elements to process in each chunk.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - predicate: A similar closure with `allSatisfy`'s one, but it's async.
    /// - Returns: `true` if all elements satisfy the `predicate`. `false` if not.
    public func pdslAllSatisfy(
        chunkSize: Int,
        priority: TaskPriority? = nil,
        _ predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Bool {
        let elements = Array(self)
        let chunks = stride(from: 0, to: elements.count, by: chunkSize).map {
            Array(elements[$0..<Swift.min($0 + chunkSize, elements.count)])
        }
        
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            for chunk in chunks {
                group.addTask(priority: priority) {
                    for element in chunk {
                        if !(try await predicate(element)) {
                            return false
                        }
                    }
                    return true
                }
            }
            
            for try await isSatisfy in group where !isSatisfy {
                group.cancelAll()
                return false
            }
            
            return true
        }
    }

    /// An async function of `allSatisfy` that processes elements in chunks and returns chunked result.
    /// - Parameters:
    ///   - chunkSize: The number of elements to process in each chunk.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - predicate: A similar closure with `allSatisfy`'s one, but it's async.
    /// - Returns: A chunked array containing the result. Since allSatisfy returns Bool, this returns a chunk with one Bool.
    public func pdslChunkedAllSatisfy(
        chunkSize: Int,
        priority: TaskPriority? = nil,
        _ predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> ChunkedArray<Bool> {
        let result = try await pdslAllSatisfy(chunkSize: chunkSize, priority: priority, predicate)
        return ChunkedArray(chunks: [[result]])
    }
}
