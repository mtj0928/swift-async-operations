extension Sequence where Element: Sendable {
    /// An async function of `contains` that processes elements in chunks.
    /// - Parameters:
    ///   - chunkSize: The number of elements to process in each chunk.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - predicate: A similar closure with `contains`'s one, but it's async.
    /// - Returns: `true` if this array contains an element satisfies the given predicate. `false` if not.
    public func pdslContains(
        chunkSize: Int,
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Bool {
        let elements = Array(self)
        let chunks = stride(from: 0, to: elements.count, by: chunkSize).map {
            Array(elements[$0..<Swift.min($0 + chunkSize, elements.count)])
        }
        
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            for chunk in chunks {
                group.addTask(priority: priority) {
                    for element in chunk {
                        if try await predicate(element) {
                            return true
                        }
                    }
                    return false
                }
            }
            
            for try await contain in group where contain {
                group.cancelAll()
                return true
            }
            
            return false
        }
    }
}
