import AsyncOperations
import Foundation

extension SequenceChunks {
    /// Checks if the sequence contains an element that satisfies the given predicate.
    /// - Parameters:
    ///   - priority: The priority of the operation task.
    ///   - predicate: A predicate closure.
    /// - Returns: true if an element satisfies the predicate, false otherwise.
    public func pdslContains(
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Bool {
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            for chunk in chunks {
                group.addTask(priority: priority) {
                    for element in chunk {
                        if try await predicate(element) {
                            return true
                        }
                    }
                    return false
                }
            }
            
            for try await contain in group where contain {
                group.cancelAll()
                return true
            }
            
            return false
        }
    }
}
