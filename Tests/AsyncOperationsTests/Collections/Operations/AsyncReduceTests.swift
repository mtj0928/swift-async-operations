import AsyncOperations
import Testing

@Test("asyncReduce")
func asyncReduceTests() async throws {
    let results = await [1, 2, 3, 4, 5].asyncReduce(0) { result, element in
        await Task.yield()
        return result + element
    }
    #expect(results == 15)
}

@Test("asyncReduce + into")
func asyncReduceIntoTests() async throws {
    let results = await [1, 2, 3, 4, 5].asyncReduce(into: 0) { result, element in
        await Task.yield()
        result += element
    }
    #expect(results == 15)
}
