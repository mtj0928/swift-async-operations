import AsyncOperators
import Testing

@Test("asyncFlatMap")
func asyncFlatMapTests() async throws {
    let results = await [0, 1, 2, 3, 4].asyncFlatMap { number in
        await Task.yield()
        return [number, number * 2]
    }
    #expect(results == [0, 0, 1, 2, 2, 4, 3, 6, 4, 8])
}
