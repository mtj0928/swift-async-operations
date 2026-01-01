import Testing
import AsyncOperations

struct OptionalAsyncMap {
    @Test
    func asyncMap() async throws {
        let nonSendable: NonSendable? = NonSendable()
        let result = await nonSendable.asyncMap { $0.number + 1 }
        #expect(result == 1)
    }

    @Test
    func asyncMapForNilCase() async throws {
        let nonSendable: NonSendable? = nil
        let result = await nonSendable.asyncMap { $0.number + 1 }
        #expect(result == nil)
    }

    @Test
    func asyncFlatMap() async throws {
        let nonSendable: NonSendable? = NonSendable()
        let result = await nonSendable.asyncFlatMap { $0.number + 1 }
        #expect(result == 1)
    }

    @Test
    func asyncFlatMapForNilCase() async throws {
        let nonSendable: NonSendable? = nil
        let result = await nonSendable.asyncFlatMap { $0.number + 1 }
        #expect(result == nil)
    }

    @Test
    func asyncFlatMapForNilNilCase() async throws {
        let nonSendable: NonSendable? = NonSendable()
        let result: Int? = await nonSendable.asyncFlatMap { _ in nil }
        #expect(result == nil)
    }
}


private class NonSendable {
    var number = 0
}
