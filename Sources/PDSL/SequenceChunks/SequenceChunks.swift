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
