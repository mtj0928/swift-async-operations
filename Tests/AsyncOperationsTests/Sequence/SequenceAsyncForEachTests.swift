import AsyncOperations
import XCTest

final class SequenceAsyncForEachTests: XCTestCase {
    @MainActor 
    func testAsyncForEach() async throws {
        var results: [Int] = []
        try await [0, 1, 2, 3, 4].asyncForEach { @MainActor number in
            try await Task.sleep(for: .milliseconds(100 * (5 - number)))
            results.append(number)
        }
        XCTAssertEqual(results, [0, 1, 2, 3, 4])
    }

    @MainActor
    func testAsyncForEachConcurrently() async throws {
        var events: [ConcurrentTaskEvent] = []
        let numberOfElements = 10
        let numberOfConcurrentTasks = 3
        // An offset to stagger iteration timings.
        let randomOffsets: [Double] = [
            2,
            1,
            0,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
        ]
        try await (0..<numberOfElements).asyncForEach(numberOfConcurrentTasks: UInt(numberOfConcurrentTasks)) { @MainActor number in
            events.append(.start)
            let offsets = randomOffsets[number]
            try await Task.sleep(for: .milliseconds(10 * offsets))
            events.append(.end)
        }
        XCTAssertEqual(Array(events.prefix(numberOfConcurrentTasks)), Array(repeating: .start, count: numberOfConcurrentTasks))
        XCTAssertEqual(
            events[numberOfConcurrentTasks..<(2 * numberOfElements - numberOfConcurrentTasks)].map { $0 },
            Array(repeating: [ConcurrentTaskEvent.end, .start], count: numberOfElements - numberOfConcurrentTasks).flatMap { $0 }
        )
        XCTAssertEqual(Array(events.suffix(Int(numberOfConcurrentTasks))), Array(repeating: .end, count: Int(numberOfConcurrentTasks)))
    }
}
