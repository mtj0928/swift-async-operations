extension Sequence where Element: Sendable {
    public func asyncFirst(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Element? {
        try await withThrowingOrderedTaskGroup(of: Element?.self) { group in
            for (index, element) in self.enumerated() {
                if index >= numberOfConcurrentTasks {
                    if let result = try await group.next(), result != nil  {
                        group.cancelAll()
                        return result
                    }
                }

                group.addTask(priority: priority) {
                    try await predicate(element) ? element : nil
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
