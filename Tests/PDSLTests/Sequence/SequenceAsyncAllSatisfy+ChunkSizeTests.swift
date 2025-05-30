import XCTest
@testable import PDSL

final class SequenceAsyncAllSatisfyChunkSizeTests: XCTestCase {
    func testAsyncAllSatisfyWithChunkSize() async throws {
        let satisfiedResult = await [0, 1, 2, 3, 4].pdslAllSatisfy(chunkSize: 2) { number in
            await Task.yield()
            return number < 5
        }
        XCTAssertTrue(satisfiedResult)
        
        let unsatisfiedResult = await [0, 1, 2, 3, 4].pdslAllSatisfy(chunkSize: 2) { number in
            await Task.yield()
            return number < 4
        }
        XCTAssertFalse(unsatisfiedResult)
    }
    
    func testAsyncAllSatisfyWithDifferentChunkSizes() async throws {
        // チャンクサイズが要素数より大きい場合
        let result1 = await [0, 1, 2].pdslAllSatisfy(chunkSize: 5) { number in
            await Task.yield()
            return number < 3
        }
        XCTAssertTrue(result1)
        
        // チャンクサイズが1の場合（個別処理と同等）
        let result2 = await [0, 1, 2].pdslAllSatisfy(chunkSize: 1) { number in
            await Task.yield()
            return number < 3
        }
        XCTAssertTrue(result2)
    }
}
