import AsyncOperations
import XCTest

final class AsyncReduceTests: XCTestCase {
    func asyncReduce() async throws {
        let results = await [1, 2, 3, 4, 5].asyncReduce(0) { result, element in
            await Task.yield()
            return result + element
        }
        XCTAssertEqual(results, 15)
    }


    func testAsyncReduceInto() async throws {
        let results = await [1, 2, 3, 4, 5].asyncReduce(into: 0) { result, element in
            await Task.yield()
            result += element
        }
        XCTAssertEqual(results, 15)
    }
}
