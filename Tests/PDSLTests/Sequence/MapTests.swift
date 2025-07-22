//
//  Copyright © 2025 Taichone. All rights reserved.
//
     

import Foundation
import Testing
@testable import V
@testable import V2


@Test func test_map_元の配列の順序が保持されること() async throws {
    let array: [Int] = Array(1...11)
    let mapOperations = { @Sendable (element: Int) -> Int in
        if element % 5 == 0 {
            sleep(1)
        }
        var sum = 0
        for i in 0..<500 {
            sum += i ^ element
        }
        return sum
    }
    
    // 標準Sequence処理の結果を基準として取得
    let standardResult = array.map(mapOperation)
    
    // 各実装の結果を取得
    let oldMapResult = await array.oldMap(mapOperation)
    let oldMapLimitedResult = await array.oldMap(
        numberOfConcurrentTasks: 3,
        mapOperation
    )
    let asyncMapResult = await array.asyncMap(
        numberOfConcurrentTasks: 3,
        mapOperation
    )
    let pdslMapLimitedResult = await array.pdslMap(
        numberOfConcurrentTasks: 3,
        mapOperation
    )
    let pdslMapResult = await array.pdslMap(mapOperation)
    
    let pMapResult = await array.pMap(mapOperation)
    let pMapLimitedResult = await array.pMap(
        numberOfConcurrentTasks: 3,
        mapOperation
    )
    
    // 各実装の結果が標準Sequence処理の結果と一致するかテスト
    #expect(oldMapResult == standardResult, "v0Map の結果が標準Sequence処理と一致しません")
    #expect(oldMapLimitedResult == standardResult, "v0Map_並行タスク3 の結果が標準Sequence処理と一致しません")
    #expect(asyncMapResult == standardResult, "asyncMap_並行タスク制限3 asyncMap の結果が標準Sequence処理と一致しません")
    #expect(pdslMapLimitedResult == standardResult, "v1Map_並行タスク制限3 pdslMap の結果が標準Sequence処理と一致しません")
    #expect(pdslMapResult == standardResult, "v1Map の結果が標準Sequence処理と一致しません")
    #expect(pMapResult == standardResult, "v2Mapの結果が標準Sequence処理と一致しません")
    #expect(pMapLimitedResult == standardResult, "一時実装 v2Map_並行タスク3 の結果が標準Sequence処理と一致しません")
}
