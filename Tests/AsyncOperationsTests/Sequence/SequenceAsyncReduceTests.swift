import AsyncOperations
import Testing

@Suite
struct SequenceAsyncReduceTests {
    @Test
    func asyncReduce() async throws {
        let results = await [1, 2, 3, 4, 5].asyncReduce(0) { result, element in
            await Task.yield()
            return result + element
        }
        #expect(results == 15)
    }


    @Test
    func asyncReduceInto() async throws {
        let results = await [1, 2, 3, 4, 5].asyncReduce(into: 0) { result, element in
            await Task.yield()
            result += element
        }
        #expect(results == 15)
    }
}
