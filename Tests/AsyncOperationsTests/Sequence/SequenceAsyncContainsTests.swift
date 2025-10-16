import AsyncOperations
import Testing

struct SequenceAsyncContainsTests {

    @Test
    func asyncContains() async throws {
        let containsResult = await [1, 2, 3].asyncContains { number in
            #expect(number != 3)
            return number == 2
        }
        #expect(containsResult)

        let notContainsResult = await [1, 2, 3].asyncContains { number in
            return number == 4
        }
        #expect(!notContainsResult)
    }
}
