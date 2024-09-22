extension Sequence where Element: Sendable {
    public func asyncForEach(
        numberOfConcurrentTasks: UInt = .max,
        priority: TaskPriority? = nil,
        _ body: @escaping @Sendable (Element) async throws -> Void
    ) async rethrows {
        try await withThrowingOrderedTaskGroup(of: Void.self) { group in
            try await internalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                taskOperation: body,
                nextOperation: { /* Do nothing */}
            )
        }
    }
}
