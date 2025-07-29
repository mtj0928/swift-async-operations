import AsyncOperations
import Foundation

public protocol SequenceChunksV1: Sendable {
    associatedtype Element: Sendable
    var chunks: [[Element]] { get }
    init(chunks: [[Element]])
}

public struct ChunkedArray<Element: Sendable>: SequenceChunksV1 {
    public let chunks: [[Element]]
    
    public init(chunks: [[Element]]) {
        self.chunks = chunks
    }
}
