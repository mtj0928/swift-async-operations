import AsyncOperations
import Foundation

extension SequenceChunks {
    /// Executes a closure for each element in the sequence.
    /// - Parameters:
    ///   - numberOfConcurrentTasks: A number of concurrent tasks.
    ///   - priority: The priority of the operation task.
    ///   - body: A closure to execute for each element.
    public func pdslForEach(
        numberOfConcurrentTasks: UInt = sequenceChunksDefaultConcurrentTasks,
        priority: TaskPriority? = nil,
        _ body: @escaping @Sendable (Element) async throws -> Void
    ) async rethrows {
        try await withThrowingOrderedTaskGroup(of: Void.self) { group in
            for chunk in chunks {
                group.addTask(priority: priority) {
                    for element in chunk {
                        try await body(element)
                    }
                }
            }
            
            for try await _ in group {
                // Do nothing, just consume the results
            }
        }
    }
} 