import AsyncOperations
import XCTest

final class SequenceAsyncForEachTests: XCTestCase {
    @MainActor 
    func testAsyncForEach() async throws {
        var results: [Int] = []
        await [0, 1, 2, 3, 4].asyncForEach { @MainActor number in
            await Task.yield()
            results.append(number)
        }
        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(Set(results), [0, 1, 2, 3, 4])
    }
}
