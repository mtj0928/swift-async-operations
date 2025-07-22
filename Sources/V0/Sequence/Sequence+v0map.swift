//
//  Copyright © 2025 Taichone. All rights reserved.
//
     
extension Sequence where Element: Sendable, Self: Sendable {
    /// 標準の ThrowingTaskGroup を利用
    public func oldMap<T: Sendable>(
        numberOfConcurrentTasks: Int,
        priority: TaskPriority? = nil,
        chunkSize: Int? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        var values: [T] = []

        try await pOldInternalForEach(
            numberOfConcurrentTasks: numberOfConcurrentTasks,
            chunkSize: chunkSize,
            priority: priority,
            taskOperation: transform
        ) { value in
            values.append(value)
        }

        return values
    }
}
