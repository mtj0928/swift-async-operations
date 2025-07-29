//
//  Copyright © 2025 Taichone. All rights reserved.
//

import Foundation

public protocol SequenceChunksV2: Sendable {
    associatedtype Element: Sendable
    var chunks: [[Element]] { get }
    init(chunks: [[Element]])
}

public struct SequenceChunks<Element: Sendable>: SequenceChunksV2 {
    public let chunks: [[Element]]
    
    public init(chunks: [[Element]]) {
        self.chunks = chunks
    }
}
