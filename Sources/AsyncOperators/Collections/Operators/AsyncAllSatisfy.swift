extension Sequence where Element: Sendable {
    public func asyncAllSatisfy(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        _ predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Bool {
        try await withThrowingOrderedTaskGroup(of: Bool.self) { group in

            for (index, element) in self.enumerated() {
                if index >= numberOfConcurrentTasks {
                    if let isSatisfy = try await group.next(),
                       !isSatisfy {
                        return false
                    }
                }

                group.addTask(priority: priority) {
                    try await predicate(element)
                }
            }

            for try await isSatisfy in group {
                if !isSatisfy {
                    return false
                }
            }

            return true
        }
    }
}
