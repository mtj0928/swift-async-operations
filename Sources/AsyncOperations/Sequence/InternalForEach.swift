extension Sequence where Element: Sendable {
    func internalForEach<T: Sendable>(
        group: inout ThrowingTaskGroup<(T, Int), any Error>,
        numberOfConcurrentTasks: UInt,
        priority: TaskPriority?,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: (T) -> ()
    ) async throws {
        var currentIndex = 0
        var results: [Int: T] = [:]

        func doNextOperationIfNeeded() {
            while let result = results[currentIndex] {
                let index = currentIndex
                nextOperation(result)
                currentIndex += 1
                results.removeValue(forKey: index)
            }
        }

        for (index, element) in self.enumerated() {
            if numberOfConcurrentTasks <= index {
                if let (value, index) = try await group.next() {
                    results[index] = value
                    doNextOperationIfNeeded()
                }
            }
            group.addTask(priority: priority) {
                try await (taskOperation(element), index)
            }
        }

        for try await (value, index) in group {
            results[index] = value
            doNextOperationIfNeeded()
        }
    }
}
