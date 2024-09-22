extension Sequence where Element: Sendable {
    public func asyncMap<T: Sendable>(
        numberOfConcurrentTasks: UInt = .max,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        try await withThrowingOrderedTaskGroup(of: T.self) { group in
            var values: [T] = []

            for (index, element) in self.enumerated() {
                if index >= numberOfConcurrentTasks {
                    if let value = try await group.next() {
                        values.append(value)
                    }
                }
                group.addTask(priority: priority) {
                    try await transform(element)
                }
            }

            for try await value in group {
                values.append(value)
            }
            return values
        }
    }
}
