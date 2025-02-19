import AsyncOperations
import XCTest

final class SequenceAsyncContainsTests: XCTestCase {
    func testAsyncContains() async throws {
        let containsResult = await [1, 2, 3].asyncContains { number in
            XCTAssertNotEqual(number, 3)
            return number == 2
        }
        XCTAssertTrue(containsResult)

        let notContainsResult = await [1, 2, 3].asyncContains { number in
            return number == 4
        }
        XCTAssertFalse(notContainsResult)
    }
}
