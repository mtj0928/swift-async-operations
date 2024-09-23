import AsyncOperations
import Testing

@Test("asyncAllSatisfy")
func asyncAllSatisfy() async throws {
    let satisfiedResult = await [0, 1, 2, 3, 4].asyncAllSatisfy { number in
        await Task.yield()
        return number < 5
    }
    #expect(satisfiedResult)

    let unsatisfiedResult = await [0, 1, 2, 3, 4].asyncAllSatisfy { number in
        await Task.yield()
        return number < 4
    }
    #expect(!unsatisfiedResult)
}
