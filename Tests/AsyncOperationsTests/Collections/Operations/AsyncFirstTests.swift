import AsyncOperations
import Testing

@Test("asyncFirst")
func asyncFirstTests() async throws {
    let containResult = await [0, 1, 2, 3, 4].asyncFirst(numberOfConcurrentTasks: 8) { number in
        await Task.yield()
        return number % 2 == 1
    }
    #expect(containResult == 1)

    let notContainResult = await [0, 1, 2, 3, 4].asyncFirst { number in
        await Task.yield()
        return number == 5
    }
    #expect(notContainResult == nil)
}
