import XCTest
@testable import PDSL

final class SequenceAsyncFlatMapChunkSizeTests: XCTestCase {
    func testAsyncFlatMapWithChunkSize() async throws {
        let numbers = [1, 2, 3]
        let result = await numbers.pdslFlatMap(chunkSize: 2) { number in
            await Task.yield()
            return [number, number * 2]
        }
        XCTAssertEqual(result, [1, 2, 2, 4, 3, 6])
    }
    
    func testAsyncFlatMapWithDifferentChunkSizes() async throws {
        let numbers = [1, 2, 3]
        
        // チャンクサイズが要素数より大きい場合
        let result1 = await numbers.pdslFlatMap(chunkSize: 5) { number in
            await Task.yield()
            return [number, number * 2]
        }
        XCTAssertEqual(result1, [1, 2, 2, 4, 3, 6])
        
        // チャンクサイズが1の場合（個別処理と同等）
        let result2 = await numbers.pdslFlatMap(chunkSize: 1) { number in
            await Task.yield()
            return [number, number * 2]
        }
        XCTAssertEqual(result2, [1, 2, 2, 4, 3, 6])
    }
}
