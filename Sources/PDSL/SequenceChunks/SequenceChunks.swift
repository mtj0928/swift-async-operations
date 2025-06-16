import AsyncOperations
import Foundation

public protocol SequenceChunks: Sendable {
    associatedtype Element: Sendable
    var chunks: [[Element]] { get }
    init(chunks: [[Element]])
}

public struct ChunkedArray<Element: Sendable>: SequenceChunks {
    public let chunks: [[Element]]
    
    public init(chunks: [[Element]]) {
        self.chunks = chunks
    }
}

// SequenceChunks への デフォルトのconcurrentTasksの参照を提供
public let sequenceChunksDefaultConcurrentTasks: UInt = {
    let availableProcessors = ProcessInfo.processInfo.activeProcessorCount
    return UInt(max(1, availableProcessors))
}()
