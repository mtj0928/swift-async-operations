//
//  Copyright © 2025 Taichone. All rights reserved.
//
     
extension Sequence where Element: Sendable, Self: Sendable {
    public func v0Map<T: Sendable>(
        numberOfConcurrentTasks: Int,
        priority: TaskPriority? = nil,
        chunkSize: Int? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        var values: [T] = []

        try await v0internalForEach(
            numberOfConcurrentTasks: numberOfConcurrentTasks,
            chunkSize: chunkSize,
            priority: priority,
            taskOperation: transform
        ) { value in
            values.append(value)
        }

        return values
    }
    
    /// 並行タスク数制限の機構なし
    public func v0map<T: Sendable>(
        priority: TaskPriority? = nil,
        chunkSize: Int? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        var values: [T] = []

        try await v0InternalForEach(
            chunkSize: chunkSize,
            priority: priority,
            taskOperation: transform
        ) { value in
            values.append(value)
        }

        return values
    }
}
