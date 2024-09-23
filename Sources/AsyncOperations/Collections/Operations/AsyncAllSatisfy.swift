extension Sequence where Element: Sendable {
    /// An async function of `allSatisfy`.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `predicate` closure run in parallel when the value is 2 or more.
    ///   - priority: A priority of the giving closure.
    ///   - predicate: A similar closure with `allSatisfy`'s one, but it's async.
    /// - Returns: `true` if all elements satisfy the `predicate`. `false` if not.
    public func asyncAllSatisfy(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        _ predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Bool {
        try await withThrowingTaskGroup(of: Bool.self) { group in
            for (index, element) in self.enumerated() {
                if index >= numberOfConcurrentTasks {
                    if let isSatisfy = try await group.next(),
                       !isSatisfy {
                        group.cancelAll()
                        return false
                    }
                }

                group.addTask(priority: priority) {
                    try await predicate(element)
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
