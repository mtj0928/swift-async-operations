import AsyncOperations
import XCTest


final class SequenceAsyncCompactMapTests: XCTestCase {
    func testAsyncCompactMapMultipleTasks() async throws {
        let results = await [0, 1, 2, 3, 4].asyncCompactMap { number in
            await Task.yield()
            return number % 2 == 0 ? nil : number * 2
        }

        XCTAssertEqual(results, [2, 6])
    }
}
