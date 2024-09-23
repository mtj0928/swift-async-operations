extension Sequence where Element: Sendable {
    /// An async function of `contains`.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `predicate` closure run in parallel when the value is 2 or more.
    ///   - priority: A priority of the giving closure.
    ///   - predicate: A similar closure with `contains`'s one, but it's async.
    /// - Returns: `true` if this array contains an element satisfies the given predicate. `false` if not.
    public func asyncContains(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Bool {
        try await withThrowingTaskGroup(of: Bool.self) { group in
            for (index, element) in self.enumerated() {
                if index >= numberOfConcurrentTasks {
                    if let contain = try await group.next(),
                       contain {
                        group.cancelAll()
                        return true
                    }
                }

                group.addTask(priority: priority) {
                    try await predicate(element)
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
