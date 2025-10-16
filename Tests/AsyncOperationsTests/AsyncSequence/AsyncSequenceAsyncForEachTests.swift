import AsyncOperations
import XCTest

final class AsyncSequenceAsyncForEachTests: XCTestCase {
    @MainActor
    func testAsyncForEach() async throws {
        var results: [Int] = []
        var events: [ConcurrentTaskEvent] = []

        let asyncSequence = AsyncStream { c in
            (0..<5).forEach { c.yield($0) }
            c.finish()
        }

        try await asyncSequence.asyncForEach(numberOfConcurrentTasks: 3) { @MainActor number in
            events.append(.start)
            try await Task.sleep(for: .milliseconds(100 * (5 - number)))
            events.append(.end)
            results.append(number)
        }
        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(Set(results), [0, 1, 2, 3, 4])
        XCTAssertEqual(events, [.start, .start, .start, .end, .start, .end, .start, .end, .end, .end])
    }
}
