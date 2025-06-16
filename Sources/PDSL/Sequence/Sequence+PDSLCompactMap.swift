import AsyncOperations

extension Sequence where Element: Sendable {
    /// An async function of `compactMap` with chunk size control.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks. the given `transform` closure run in parallel when the value is 2 or more.
    ///   - priority: The priority of the operation task.
    ///     Omit this parameter or pass `.unspecified`
    ///     to set the child task's priority to the priority of the group.
    ///   - chunkSize: A size of chunk for processing elements.
    ///   - transform: A similar closure with `compactMap`'s one, but it's async.
    /// - Returns: A transformed array which doesn't contain `nil`.
    ///
    
    
    public func pdslCompactMap<T: Sendable>(
        numberOfConcurrentTasks: UInt = numberOfConcurrentTasks,
        priority: TaskPriority? = nil,
        chunkSize: UInt,
        _ transform: @escaping @Sendable (Element) async throws -> T?
    ) async rethrows -> [T] {
        try await withThrowingOrderedTaskGroup(of: [T?].self) { group in
            var values: [T] = []
            
            try await pdslInternalForEach(
                group: &group,
                numberOfConcurrentTasks: numberOfConcurrentTasks,
                priority: priority,
                chunkSize: chunkSize,
                taskOperation: transform
            ) { value in
                guard let value else { return }
                values.append(value)
            }
            return values
        }
    }

    
    /// An async function of `compactMap` with chunk size control.
    /// No limit on the number of concurrent tasks.
    /// - Parameters:
    ///   - priority: A priority of the giving closure.
    ///   - chunkSize: A size of chunk for processing elements.
    ///   - transform: A similar closure with `compactMap`'s one, but it's async.
    /// - Returns: A transformed array which doesn't contain `nil`.
    ///
    public func pdslCompactMap<T: Sendable>(
        priority: TaskPriority? = nil,
        chunkSize: UInt,
        _ transform: @escaping @Sendable (Element) async throws -> T?
    ) async rethrows -> [T] {
        try await withThrowingOrderedTaskGroup(of: [T?].self) { group in
            var values: [T] = []
            
            try await pdslInternalForEach(
                group: &group,
                priority: priority,
                chunkSize: chunkSize,
                taskOperation: transform
            ) { value in
                guard let value else { return }
                values.append(value)
            }
            return values
        }
    }
}
