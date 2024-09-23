import AsyncOperators
import Testing

@Test("AsyncFilter")
func asyncFilter() async throws {
    let filteredNumbers = await [0, 1, 2, 3, 4].asyncFilter { number in
        await Task.yield()
        return number.isMultiple(of: 2)
    }
    #expect(filteredNumbers == [0, 2, 4])
}
