import AsyncOperations
import Foundation

extension SequenceChunks {
    /// Finds the first element that satisfies the given predicate.
    /// - Parameters:
    ///   - priority: The priority of the operation task.
    ///   - predicate: A predicate closure.
    /// - Returns: The first element that satisfies the predicate, or nil if none is found.
    public func pdslFirst(
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async rethrows -> Element? {
        return try await withThrowingTaskGroup(of: Element?.self) { group in
            for chunk in chunks {
                group.addTask(priority: priority) {
                    for element in chunk {
                        if try await predicate(element) {
                            return element
                        }
                    }
                    return nil
                }
            }
            
            for try await result in group where result != nil {
                group.cancelAll()
                return result
            }
            
            return nil
        }
    }
}
