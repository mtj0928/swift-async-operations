import XCTest
@testable import PDSL


final class SequenceAsyncCompactMapChunkSizeTests: XCTestCase {
    func testAsyncCompactMapWithChunkSize() async throws {
        let results = await [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].pdslCompactMap(
            numberOfConcurrentTasks: 2,
            priority: nil,
            chunkSize: 3
        ) { number in
            await Task.yield()
            return number % 2 == 0 ? nil : number * 2
        }

        XCTAssertEqual(results, [2, 6, 10, 14, 18])
    }

    func testAsyncCompactMapWithChunkSizeAndSingleTask() async throws {
        let results = await [0, 1, 2, 3, 4].pdslCompactMap(
            numberOfConcurrentTasks: 1,
            priority: nil,
            chunkSize: 2
        ) { number in
            await Task.yield()
            return number % 2 == 0 ? nil : number * 2
        }

        XCTAssertEqual(results, [2, 6])
    }
}
