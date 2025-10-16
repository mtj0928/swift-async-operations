import AsyncOperations
import Testing

@Suite
struct SequenceAsyncForEachTests {
    @Test
    @MainActor
    func asyncForEach() async throws {
        var results: [Int] = []
        try await [0, 1, 2, 3, 4].asyncForEach { @MainActor number in
            try await Task.sleep(for: .milliseconds(100 * (5 - number)))
            results.append(number)
        }
        #expect(results == [0, 1, 2, 3, 4])
    }

    @Test(.timeLimit(.minutes(1)))
    @MainActor
    func asyncForEachConcurrently() async throws {
        var events: [ConcurrentTaskEvent] = []
        let numberOfElements = 10
        let numberOfConcurrentTasks = 3
        let publisher = EventPublisher()

        Task {
            let publishOrder = [2, 1, 0, 3, 7, 5, 8, 6, 9, 4]
            for number in publishOrder {
                await publisher.send(number)
                try await Task.sleep(for: .milliseconds(100))
            }
        }

        await (0..<numberOfElements).asyncForEach(numberOfConcurrentTasks: UInt(numberOfConcurrentTasks)) { @MainActor number in
            events.append(.start)
            await publisher.wait(for: number)
            events.append(.end)
        }

        #expect(Array(events.prefix(numberOfConcurrentTasks)) == Array(repeating: .start, count: numberOfConcurrentTasks))
        #expect(
            events[numberOfConcurrentTasks..<(2 * numberOfElements - numberOfConcurrentTasks)].map { $0 }
            ==
            Array(repeating: [ConcurrentTaskEvent.end, .start], count: numberOfElements - numberOfConcurrentTasks).flatMap { $0 }
        )
        #expect(Array(events.suffix(Int(numberOfConcurrentTasks))) == Array(repeating: .end, count: Int(numberOfConcurrentTasks)))
    }
}

private final actor EventPublisher {
    private var alreadyPublished: Set<Int> = []
    private var continuations: [Int: CheckedContinuation<Void, Never>] = [:]

    func send(_ key: Int) {
        alreadyPublished.insert(key)
        if let continuation = continuations[key] {
            continuation.resume()
            self.continuations[key] = nil
        }
    }

    func wait(for key: Int) async {
        await withCheckedContinuation { continuation in
            if alreadyPublished.contains(key) {
                continuation.resume()
            } else {
                continuations[key] = continuation
            }
        }
    }
}
