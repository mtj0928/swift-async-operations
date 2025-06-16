import AsyncOperations
import Foundation

extension SequenceChunks {
    /// Checks if all elements in the sequence satisfy the given predicate.
    /// - Parameters:
    ///   - priority: The priority of the operation task.
    ///   - predicate: A predicate closure.
    /// - Returns: true if all elements satisfy the predicate, false otherwise.
    public func pdslAllSatisfy(
        priority: TaskPriority? = nil,
        _ predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Bool {
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            for chunk in chunks {
                group.addTask(priority: priority) {
                    for element in chunk {
                        if !(try await predicate(element)) {
                            return false
                        }
                    }
                    return true
                }
            }
            
            for try await isSatisfy in group where !isSatisfy {
                group.cancelAll()
                return false
            }
            
            return true
        }
    }
} 