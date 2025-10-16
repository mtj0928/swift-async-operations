import AsyncOperations
import Foundation
import Testing

struct SequenceAsyncMapTests {

    @Test
    func asyncMapMultipleTasks() async throws {
        let startTime = Date()
        let results = try await [0, 1, 2, 3, 4].asyncMap(numberOfConcurrentTasks: 8) { number in
            try await Task.sleep(for: .seconds(1))
            return number * 2
        }

        let endTime = Date()
        let difference = endTime.timeIntervalSince(startTime)

        #expect(results == [0, 2, 4, 6, 8])
        #expect(difference < 2)
    }

    @Test
    func asyncMapMultipleTasksWithNumberOfConcurrentTasks() async throws {
        let counter = Counter()
        let results = await [0, 1, 2, 3, 4].asyncMap(numberOfConcurrentTasks: 2) { number in
            await counter.increment()
            let numberOfConcurrentTasks = await counter.number
            #expect(numberOfConcurrentTasks <= 2)
            await counter.decrement()
            return number * 2
        }

        #expect(results == [0, 2, 4, 6, 8])
    }
}

// MARK: - private

private actor Counter {
    private(set) var number = 0

    func increment() {
        number += 1
    }

    func decrement() {
        number -= 1
    }
}
