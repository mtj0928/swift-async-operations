extension Sequence where Element: Sendable, Self: Sendable {
    /// An async function of `allSatisfy` that processes elements in chunks.
    /// - Parameters:
    ///   - chunkSize: The number of elements to process in each chunk.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - predicate: A similar closure with `allSatisfy`'s one, but it's async.
    /// - Returns: `true` if all elements satisfy the `predicate`. `false` if not.
    public func pdslAllSatisfy(
        chunkSize: Int? = nil,
        priority: TaskPriority? = nil,
        _ predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Bool {
        let elements = Array(self)
        let elementsCount = elements.count
        let chunkSize = chunkSize ?? (elementsCount / numberOfConcurrentTasks + 1)
        let chunks = stride(from: 0, to: elementsCount, by: chunkSize).map {
            Array(elements[$0..<Swift.min($0 + chunkSize, elementsCount)])
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
}
