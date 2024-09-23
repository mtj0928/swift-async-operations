#if swift(>=6.0)
/// A wrapper function of `withThrowingTaskGroup`.
///
/// The main difference with `withThrowingTaskGroup` is that the group's next function returns the results in the order the tasks were added.
///
/// ```swift
/// let results = await try withThrowingOrderedTaskGroup(of: Int.self) { group in
///     (0..<5).forEach { number in
///         group.addTask {
///             if number > 10 {
///                 throw YourError()
///             }
///             try await Task.yield()
///             return number * 2
///         }
///     }
///     var results: [Int] = []
///     for try await number in group {
///         results.append(number)
///     }
///     return results
/// }
/// print(result) // [0, 2, 4, 6, 8, 10]
/// ```
public func withThrowingOrderedTaskGroup<ChildTaskResult: Sendable, GroupResult>(
    of childTaskResultType: ChildTaskResult.Type,
    returning returnType: GroupResult.Type = GroupResult.self,
    isolation: isolated (any Actor)? = #isolation,
    body: (inout ThrowingOrderedTaskGroup<ChildTaskResult, any Error>) async throws -> GroupResult
) async rethrows -> GroupResult {
    try await withThrowingTaskGroup(
        of: (Index, ChildTaskResult).self,
        returning: GroupResult.self
    ) { group in
        var throwingOrderedTaskGroup = ThrowingOrderedTaskGroup<ChildTaskResult, any Error>(group)
        return try await body(&throwingOrderedTaskGroup)
    }
}
#else
public func withThrowingOrderedTaskGroup<ChildTaskResult: Sendable, GroupResult>(
    of childTaskResultType: ChildTaskResult.Type,
    returning returnType: GroupResult.Type = GroupResult.self,
    body: (inout ThrowingOrderedTaskGroup<ChildTaskResult, any Error>) async throws -> GroupResult
) async rethrows -> GroupResult {
    try await withThrowingTaskGroup(
        of: (Index, ChildTaskResult).self,
        returning: GroupResult.self
    ) { group in
        var throwingOrderedTaskGroup = ThrowingOrderedTaskGroup<ChildTaskResult, any Error>(group)
        return try await body(&throwingOrderedTaskGroup)
    }
}

#endif

public struct ThrowingOrderedTaskGroup<ChildTaskResult: Sendable, Failure: Error> {
    private var internalGroup: ThrowingTaskGroup<(Index, ChildTaskResult), Failure>
    private var addedTaskIndex: Index = 0
    private var nextIndex: Index = 0
    private var unreturnedResults: [Index: Result<ChildTaskResult, Failure>] = [:]

    init(_ internalGroup: ThrowingTaskGroup<(Index, ChildTaskResult), Failure>) {
        self.internalGroup = internalGroup
    }

#if swift(>=6.0)
    public mutating func addTask(
        priority: TaskPriority? = nil,
        operation: sending @escaping @isolated(any) () async throws(Failure) -> ChildTaskResult
    ) {
        let currentIndex = addedTaskIndex
        internalGroup.addTask(priority: priority) {
            do throws(Failure) {
                let result = try await operation()
                return (currentIndex, result)
            } catch {
                throw InternalError(index: currentIndex, rawError: error)
            }
        }
        addedTaskIndex = addedTaskIndex.next()
    }
#else
    public mutating func addTask(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> ChildTaskResult
    ) {
        let currentIndex = addedTaskIndex
        internalGroup.addTask(priority: priority) {
            do {
                let result = try await operation()
                return (currentIndex, result)
            } catch {
                throw InternalError(index: currentIndex, rawError: error)
            }
        }
        addedTaskIndex = addedTaskIndex.next()
    }
#endif

    public mutating func waitForAll() async throws {
        do {
            try await internalGroup.waitForAll()
        } catch let error as InternalError<Failure> {
            throw error.rawError
        }
    }

    public func cancelAll() {
        internalGroup.cancelAll()
    }
}

extension ThrowingOrderedTaskGroup: AsyncSequence, AsyncIteratorProtocol where Failure: Error {
    public typealias Element = ChildTaskResult

    public func makeAsyncIterator() -> Self {
        self
    }

    public mutating func next() async throws -> ChildTaskResult? {
        if let result = unreturnedResults[nextIndex] {
            unreturnedResults.removeValue(forKey: nextIndex)
            nextIndex = nextIndex.next()
            return try result.get()
        }

        do {
            if let (index, result) = try await internalGroup.next() {
                unreturnedResults[index] = .success(result)
                return try await next()
            }
        } catch let error as InternalError<Failure> {
            unreturnedResults[error.index] = .failure(error.rawError)
            return try await next()
        }

        return nil
    }
}

private struct InternalError<Failure: Error>: Error {
    var index: Index
    var rawError: Failure
}
