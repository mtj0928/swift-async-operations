import XCTest
@testable import PDSL

final class MapFilterFirstTests: XCTestCase {
    
    private let array: [Int] = Array(1...1000) // テスト用に要素数を減らす
    
    private let mapOperation = { @Sendable (element: Int) -> Int in
        var sum = 0
        for i in 0..<1000 { // テスト用に計算量を減らす
            sum += i ^ element
        }
        return sum
    }
    
    private let filterOperation = { @Sendable (element: Int) -> Bool in
        return element % 2 == 0
    }
    
    private let firstOperation = { @Sendable (element: Int) -> Bool in
        element > 10000
    }
    
    func testMapFilterFirstResultsAreConsistent() async throws {
        // 標準Sequence処理
        let standardResult = array
            .map(mapOperation)
            .filter(filterOperation)
            .first(where: firstOperation)
        
        // 改良実装
        let pdslResult = await array
            .pdslMap(mapOperation)
            .pdslFilter(filterOperation)
            .pdslFirst(where: firstOperation)
        
        // 改良実装_チャンク
        let pdslChunkedResult = await array
            .pdslChunkedMap(mapOperation)
            .pdslChunkedFilter(filterOperation)
            .pdslFirst(where: firstOperation)
        
        // 結果が一致することを確認
        XCTAssertEqual(standardResult, pdslResult, "標準Sequence処理とPDSLの結果が一致しません")
        XCTAssertEqual(standardResult, pdslChunkedResult, "標準Sequence処理とPDSLチャンクの結果が一致しません")
        XCTAssertEqual(pdslResult, pdslChunkedResult, "PDSLとPDSLチャンクの結果が一致しません")
    }
    
    func testMapFilterFirstWithDifferentData() async throws {
        // 異なるデータセットでもテスト
        let testArray = Array(1...500)
        
        let standardResult = testArray
            .map(mapOperation)
            .filter(filterOperation)
            .first(where: firstOperation)
        
        let pdslResult = await testArray
            .pdslMap(mapOperation)
            .pdslFilter(filterOperation)
            .pdslFirst(where: firstOperation)
        
        let pdslChunkedResult = await testArray
            .pdslChunkedMap(mapOperation)
            .pdslChunkedFilter(filterOperation)
            .pdslFirst(where: firstOperation)
        
        XCTAssertEqual(standardResult, pdslResult)
        XCTAssertEqual(standardResult, pdslChunkedResult)
        XCTAssertEqual(pdslResult, pdslChunkedResult)
    }
    
    func testMapFilterFirstWithNoMatch() async throws {
        // マッチしない条件でのテスト
        let smallArray = Array(1...10)
        
        let impossibleCondition = { @Sendable (element: Int) -> Bool in
            element > 1_000_000 // 絶対にマッチしない条件
        }
        
        let standardResult = smallArray
            .map(mapOperation)
            .filter(filterOperation)
            .first(where: impossibleCondition)
        
        let pdslResult = await smallArray
            .pdslMap(mapOperation)
            .pdslFilter(filterOperation)
            .pdslFirst(where: impossibleCondition)
        
        let pdslChunkedResult = await smallArray
            .pdslChunkedMap(mapOperation)
            .pdslChunkedFilter(filterOperation)
            .pdslFirst(where: impossibleCondition)
        
        // 全てnilであることを確認
        XCTAssertNil(standardResult)
        XCTAssertNil(pdslResult)
        XCTAssertNil(pdslChunkedResult)
    }
    
    func testMapFilterFirstWithEmptyArray() async throws {
        // 空配列でのテスト
        let emptyArray: [Int] = []
        
        let standardResult = emptyArray
            .map(mapOperation)
            .filter(filterOperation)
            .first(where: firstOperation)
        
        let pdslResult = await emptyArray
            .pdslMap(mapOperation)
            .pdslFilter(filterOperation)
            .pdslFirst(where: firstOperation)
        
        let pdslChunkedResult = await emptyArray
            .pdslChunkedMap(mapOperation)
            .pdslChunkedFilter(filterOperation)
            .pdslFirst(where: firstOperation)
        
        // 全てnilであることを確認
        XCTAssertNil(standardResult)
        XCTAssertNil(pdslResult)
        XCTAssertNil(pdslChunkedResult)
    }
}
