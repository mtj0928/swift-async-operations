extension Sequence where Element: Sendable {
    public func asyncContains(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Bool {
        try await withThrowingOrderedTaskGroup(of: Bool.self) { group in
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
