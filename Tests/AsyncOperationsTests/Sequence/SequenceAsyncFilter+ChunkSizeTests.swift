import AsyncOperations
import XCTest

final class SequenceAsyncFilterChunkSizeTests: XCTestCase {
    func testAsyncFilterWithChunkSize() async throws {
        let filteredNumbers = await [0, 1, 2, 3, 4].asyncFilter(
            chunkSize: 2
        ) { number in
            await Task.yield()
            return number.isMultiple(of: 2)
        }
        XCTAssertEqual(filteredNumbers, [0, 2, 4])
    }
    
    func testAsyncFilterWithDifferentChunkSizes() async throws {
        // チャンクサイズが要素数より大きい場合
        let result1 = await [0, 1, 2].asyncFilter(
            chunkSize: 5
        ) { number in
            await Task.yield()
            return number.isMultiple(of: 2)
        }
        XCTAssertEqual(result1, [0, 2])
        
        // チャンクサイズが1の場合（個別処理と同等）
        let result2 = await [0, 1, 2].asyncFilter(
            chunkSize: 1
        ) { number in
            await Task.yield()
            return number.isMultiple(of: 2)
        }
        XCTAssertEqual(result2, [0, 2])
    }
}
