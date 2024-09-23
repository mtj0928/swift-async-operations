import AsyncOperations
import Testing

@MainActor func asyncForEach() async throws {
    var results: [Int] = []
    await [0, 1, 2, 3, 4].asyncForEach { @MainActor number in
        await Task.yield()
        results.append(number)
    }
    print(results)
    #expect(results.count == 5)
    #expect(Set(results) == [0, 1, 2, 3, 4])
}
