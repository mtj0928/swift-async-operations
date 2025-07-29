//
//  Copyright © 2025 Taichone. All rights reserved.
//

import Foundation

let numberOfConcurrentTasks: Int = {
    let processorCount = ProcessInfo.processInfo.processorCount
    print("Processor Count: \(processorCount)")
    return Int(max(1, processorCount))
}()
