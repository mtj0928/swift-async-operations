extension Sequence where Element: Sendable {
    public func asyncFlatMap<T: Sendable>(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> [T]
    ) async rethrows -> [T] {
        try await withThrowingOrderedTaskGroup(of: [T].self) { group in
            var values: [T] = []

            try await internalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                taskOperation: transform
            ) { results in
                values.append(contentsOf: results)
            }

            return values
        }
    }
}
