import AsyncOperations
import XCTest

final class AsyncSequenceAsyncForEachTests: XCTestCase {
    @MainActor
    func testAsyncForEach() async throws {
        var results: [Int] = []

        let asyncSequence = AsyncStream { c in
            (0..<5).forEach { c.yield($0) }
            c.finish()
        }

        await asyncSequence.asyncForEach(numberOfConcurrentTasks: 3) { @MainActor number in
            await Task.yield()
            results.append(number)
        }
        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(Set(results), [0, 1, 2, 3, 4])
    }
}
