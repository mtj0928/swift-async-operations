import XCTest
@testable import PDSL

final class ChunkedOperationsTest: XCTestCase {
    
    func testChunkedMapChain() async throws {
        let array = [1, 2, 3, 4, 5]
        
        // チェーン可能な操作のテスト
        let result1 = try await array.pdslChunkedCompactMap(chunkSize: 2) { element in
            element * 3
        }.pdslChunkedCompactMap { element in
            element * 3
        }.pdslChunkedFilter { element in
            element % 2 == 0
        }.pdslCompactMap { element in
            element + 2
        }
        
        XCTAssertEqual(result1, [29, 38, 47])
    }
    
    func testChunkedToTerminalOperation() async throws {
        let array = [1, 2, 3, 4, 5]
        
        // 終端操作のテスト
        let result2 = try await array.pdslChunkedCompactMap(chunkSize: 2) { element in
            element * 3
        }.pdslChunkedFilter { element in
            element % 2 == 0
        }.pdslFirst { element in
            element > 2
        }
        
        XCTAssertEqual(result2, 6)
    }
    
    func testChunkedReduce() async throws {
        let array = [1, 2, 3, 4, 5]
        
        let result = try await array.pdslChunkedReduce(chunkSize: 2, 0) { acc, element in
            acc + element
        }
        
        // reduceは終端操作なので、結果は単一値を含むチャンク
        XCTAssertEqual(result.chunks, [[15]])
    }
} 