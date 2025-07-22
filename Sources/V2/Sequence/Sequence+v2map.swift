//
//  Copyright © 2025 Taichone. All rights reserved.
//
     

extension Sequence where Element: Sendable, Self: Sendable {
    /// 標準の ThrowingTaskGroup を利用
    public func v2map<T: Sendable>(
        priority: TaskPriority? = nil,
        chunkSize: Int? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        var values: [T] = []

        try await v2internalForEach(
            chunkSize: chunkSize,
            priority: priority,
            taskOperation: transform
        ) { value in
            values.append(value)
        }

        return values
    }
    
    /// 標準の ThrowingTaskGroup を利用
    public func v2map<T: Sendable>(
        numberOfConcurrentTasks: Int,
        priority: TaskPriority? = nil,
        chunkSize: Int? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        var values: [T] = []

        try await v2internalForEach(
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
