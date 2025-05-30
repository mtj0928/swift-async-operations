import XCTest
@testable import PDSL

final class SequenceAsyncMapChunkSizeTests: XCTestCase {
    func testAsyncMapWithChunkSize() async throws {
        let numbers = [1, 2, 3, 4, 5]
        let result = await numbers.pdslMap(chunkSize: 2) { number in
            await Task.yield()
            return number * 2
        }
        XCTAssertEqual(result, [2, 4, 6, 8, 10])
    }
    
    func testAsyncMapWithDifferentChunkSizes() async throws {
        let numbers = [1, 2, 3]
        
        // チャンクサイズが要素数より大きい場合
        let result1 = await numbers.pdslMap(chunkSize: 5) { number in
            await Task.yield()
            return number * 2
        }
        XCTAssertEqual(result1, [2, 4, 6])
        
        // チャンクサイズが1の場合（個別処理と同等）
        let result2 = await numbers.pdslMap(chunkSize: 1) { number in
            await Task.yield()
            return number * 2
        }
        XCTAssertEqual(result2, [2, 4, 6])
    }
}
