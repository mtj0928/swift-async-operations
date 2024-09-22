extension Sequence where Element: Sendable {

    public func asyncCompactMap<T: Sendable>(
        numberOfConcurrentTasks: UInt = .max,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T?
    ) async rethrows -> [T] {
        try await withThrowingOrderedTaskGroup(of: T?.self) { group in
            var values: [T] = []

            try await internalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                taskOperation: transform
            ) { value in
                guard let value else { return }
                values.append(value)
            }
            return values
        }
    }
}
