import AsyncOperations

extension SequenceChunks {
    public func v1InternalForEach<T: Sendable>(
        group: inout ThrowingOrderedTaskGroup<[T], any Error>,
        priority: TaskPriority?,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: (T) -> ()
    ) async throws {
        for chunk in chunks {
            group.addTask(priority: priority) {
                var results: [T] = []
                for element in chunk {
                    let result = try await taskOperation(element)
                    results.append(result)
                }
                return results
            }
        }
        for try await values: [T] in group {
            for value in values {
                nextOperation(value)
            }
        }
    }

    public func v1ChunkedInternalForEach<T: Sendable>(
        group: inout ThrowingOrderedTaskGroup<[T], any Error>,
        priority: TaskPriority?,
        taskOperation: @escaping @Sendable (Element) async throws -> T,
        nextOperation: ([T]) -> ()
    ) async throws {
        for chunk in chunks {
            group.addTask(priority: priority) {
                var results: [T] = []
                for element in chunk {
                    let result = try await taskOperation(element)
                    results.append(result)
                }
                return results
            }
        }
        for try await chunk: [T] in group {
            nextOperation(chunk)
        }
    }
}
