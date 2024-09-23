import AsyncOperations
import XCTest

final class AsyncFirstTests: XCTestCase {
    func testAsyncFirst() async throws {
        let containResult = await [0, 1, 2, 3, 4].asyncFirst(numberOfConcurrentTasks: 8) { number in
            await Task.yield()
            return number % 2 == 1
        }
        XCTAssertEqual(containResult, 1)

        let notContainResult = await [0, 1, 2, 3, 4].asyncFirst { number in
            await Task.yield()
            return number == 5
        }
        XCTAssertNil(notContainResult)
    }
}
