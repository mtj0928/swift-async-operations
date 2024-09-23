extension Sequence where Element: Sendable {
    public func asyncFilter(
        numberOfConcurrentTasks: UInt = .max,
        priority: TaskPriority? = nil,
        _ isIncluded: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> [Element] {
        try await withThrowingOrderedTaskGroup(of: Element?.self) { group in
            var values: [Element] = []

            try await internalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                taskOperation: {
                    value in try await isIncluded(value) ? value : nil
                }
            ) { value in
                if let value {
                    values.append(value)
                }
            }

            return values
        }
    }
}
