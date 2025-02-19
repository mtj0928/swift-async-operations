extension Sequence where Element: Sendable {
    func internalForEach<T: Sendable>(
        group: inout ThrowingOrderedTaskGroup<T, any Error>,
        numberOfConcurrentTasks: UInt,
        priority: TaskPriority?,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: (T) -> ()
    ) async throws {
        for (index, element) in self.enumerated() {
            if index >= numberOfConcurrentTasks {
                if let value = try await group.next() {
                    nextOperation(value)
                }
            }
            group.addTask(priority: priority) {
                try await taskOperation(element)
            }
        }

        for try await value in group {
            nextOperation(value)
        }
    }
}
