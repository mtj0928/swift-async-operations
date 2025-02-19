import AsyncOperations
import XCTest

final class SequenceAsyncAllSatisfyTests: XCTestCase {
    func testAsyncAllSatisfy() async throws {
        let satisfiedResult = await [0, 1, 2, 3, 4].asyncAllSatisfy { number in
            await Task.yield()
            return number < 5
        }
        XCTAssertTrue(satisfiedResult)

        let unsatisfiedResult = await [0, 1, 2, 3, 4].asyncAllSatisfy { number in
            await Task.yield()
            return number < 4
        }
        XCTAssertFalse(unsatisfiedResult)
    }
}
