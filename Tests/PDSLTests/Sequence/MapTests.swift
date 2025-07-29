//
//  Copyright © 2025 Taichone. All rights reserved.
//
     

import Foundation
import Testing
@testable import V0
@testable import V1
@testable import V2

@Test func test_map_元の配列の順序が保持されること() async throws {
    let array: [Int] = Array(1...100)
    let mapOperation = { @Sendable (element: Int) -> Int in
        var sum = 0
        for i in 0..<(500 % element) {
            sum += i ^ element
        }
        return sum
    }
    
    // 標準Sequence処理
    let standardResult = array.map(mapOperation)
    
    // AsyncOperations
    let asyncMapResult = await array.asyncMap(
        numberOfConcurrentTasks: 3,
        mapOperation
    )
    
    let v0mapResult = await array.v0map(mapOperation)
    let v0mapLimitedResult = await array.v0Map(
        numberOfConcurrentTasks: 3,
        mapOperation
    )
    let v1mapLimitedResult = await array.v1Map(
        numberOfConcurrentTasks: 3,
        mapOperation
    )
    let v1mapResult = await array.v1Map(mapOperation)
    
    let v2mapResult = await array.v2Map(mapOperation)
    let v2mapLimitedResult = await array.v2Map(
        numberOfConcurrentTasks: 3,
        mapOperation
    )
    
    // 各実装の結果が標準Sequence処理の結果と一致するかテスト
    #expect(asyncMapResult == standardResult, "asyncMap_並行タスク制限3 asyncMap の結果が標準Sequence処理と一致しません")
    
    #expect(v0mapResult == standardResult, "v0Map の結果が標準Sequence処理と一致しません")
    #expect(v0mapLimitedResult == standardResult, "v0Map_並行タスク3 の結果が標準Sequence処理と一致しません")
    #expect(v1mapResult == standardResult, "v1Map の結果が標準Sequence処理と一致しません")
    #expect(v1mapLimitedResult == standardResult, "v1Map_並行タスク制限3 の結果が標準Sequence処理と一致しません")
    #expect(v2mapResult == standardResult, "v2Map の結果が標準Sequence処理と一致しません")
    #expect(v2mapLimitedResult == standardResult, "v2Map_並行タスク3 の結果が標準Sequence処理と一致しません")
}
