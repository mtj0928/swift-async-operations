#if compiler(>=6.0)
/// A wrapper function of `withTaskGroup`.
///
/// The main difference with `withTaskGroup` is that the group's next function returns the results in the order the tasks were added.
///
/// ```swift
/// let results = await withOrderedTaskGroup(of: Int.self) { group in
///     (0..<5).forEach { number in
///         group.addTask {
///             await Task.yield()
///             return number * 2
///         }
///     }
///     var results: [Int] = []
///     for await number in group {
///         results.append(number)
///     }
///     return results
/// }
/// print(result) // [0, 2, 4, 6, 8, 10]
/// ```
public func withOrderedTaskGroup<ChildTaskResult: Sendable, GroupResult>(
    of childTaskResultType: ChildTaskResult.Type,
    returning returnType: GroupResult.Type = GroupResult.self,
    isolation: isolated (any Actor)? = #isolation,
    body: (inout OrderedTaskGroup<ChildTaskResult>) async -> GroupResult
) async -> GroupResult {
    await withTaskGroup(of: (Index, ChildTaskResult).self, returning: returnType) { group in
        var orderedTaskGroup = OrderedTaskGroup<ChildTaskResult>(group)
        return await body(&orderedTaskGroup)
    }
}
#else
public func withOrderedTaskGroup<ChildTaskResult: Sendable, GroupResult>(
    of childTaskResultType: ChildTaskResult.Type,
    returning returnType: GroupResult.Type = GroupResult.self,
    body: (inout OrderedTaskGroup<ChildTaskResult>) async -> GroupResult
) async -> GroupResult {
    await withTaskGroup(of: (Index, ChildTaskResult).self, returning: returnType) { group in
        var orderedTaskGroup = OrderedTaskGroup<ChildTaskResult>(group)
        return await body(&orderedTaskGroup)
    }
}
#endif

public struct OrderedTaskGroup<ChildTaskResult: Sendable> {
    private var internalGroup: TaskGroup<(Index, ChildTaskResult)>
    private var addedTaskIndex: Index = 0
    private var nextIndex: Index = 0
    private var unreturnedResults: [Index: ChildTaskResult] = [:]

    fileprivate init(_ internalGroup: TaskGroup<(Index, ChildTaskResult)>) {
        self.internalGroup = internalGroup
    }

#if compiler(>=6.0)
    public mutating func addTask(
        priority: TaskPriority? = nil,
        operation: sending @escaping @isolated(any) () async -> ChildTaskResult
    ) {
        let currentIndex = addedTaskIndex
        internalGroup.addTask(priority: priority) {
            let result = await operation()
            return (currentIndex, result)
        }
        addedTaskIndex = addedTaskIndex.next()
    }
#else
    public mutating func addTask(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> ChildTaskResult
    ) {
        let currentIndex = addedTaskIndex
        internalGroup.addTask(priority: priority) {
            let result = await operation()
            return (currentIndex, result)
        }
        addedTaskIndex = addedTaskIndex.next()
    }
#endif

    public mutating func waitForAll() async {
        await internalGroup.waitForAll()
    }

    public func cancelAll() {
        internalGroup.cancelAll()
    }
}

extension OrderedTaskGroup: AsyncSequence, AsyncIteratorProtocol {
    public typealias Element = ChildTaskResult
    public typealias Failure = Never

    public func makeAsyncIterator() -> Self {
        self
    }

    public mutating func next() async -> ChildTaskResult? {
        if let result = unreturnedResults[nextIndex] {
            unreturnedResults.removeValue(forKey: nextIndex)
            nextIndex = nextIndex.next()
            return result
        }

        if let (index, result) = await internalGroup.next() {
            unreturnedResults[index] = result
            return await next()
        }

        return nil
    }
}
