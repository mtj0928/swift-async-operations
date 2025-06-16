//
//  Copyright © 2025 Taichone. All rights reserved.
//

import Foundation

public let numberOfConcurrentTasks: Int = {
    let processorCount = ProcessInfo.processInfo.processorCount
    return Int(max(1, processorCount))
}()
