//
//  Copyright © 2025 Taichone. All rights reserved.
//

import Foundation

public protocol SequenceChunksV2: Sendable {
    associatedtype Element: Sendable
    typealias StartIndex = Int
    
    var chunks: (startIndex: StartIndex, chunk: [Element]) { get }
}

public struct ChunksV2<Element: Sendable>: SequenceChunksV2 {
    public let chunks: (startIndex: StartIndex, chunk: [Element])
}
