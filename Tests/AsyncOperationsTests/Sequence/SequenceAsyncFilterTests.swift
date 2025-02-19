import AsyncOperations
import XCTest

final class SequenceAsyncFilterTests: XCTestCase {
    func testAsyncFilter() async throws {
        let filteredNumbers = await [0, 1, 2, 3, 4].asyncFilter { number in
            await Task.yield()
            return number.isMultiple(of: 2)
        }
        XCTAssertEqual(filteredNumbers, [0, 2, 4])
    }
}
