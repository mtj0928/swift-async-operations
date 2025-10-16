import AsyncOperations
import Testing

struct WithThrowingOrderedTaskGroupTests {
    @Test
    func testWithThrowingOrderedTaskGroup() async throws {
        let results = try await withThrowingOrderedTaskGroup(of: Int.self) { group in
            (0..<10).forEach { number in
                group.addTask {
                    await Task.yield()
                    return number
                }
            }
            var results: [Int] = []
            for try await number in group {
                results.append(number)
            }
            return results
        }

        #expect(results == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }

    @Test
    func withThrowingOrderedTaskGroupOnFailure() async throws {
        await #expect(throws: DummyError.self) {
            _ = try await withThrowingOrderedTaskGroup(of: Int.self) { group in
                (0..<10).forEach { number in
                    group.addTask {
                        await Task.yield()
                        if number == 5 { throw DummyError() }
                        return number
                    }
                }
                var results: [Int] = []
                for try await number in group {
                    results.append(number)
                }
                return results
            }
        }
    }

    @Test
    func withThrowingOrderedTaskGroupByIgnoreError() async throws {
        let results = try await withThrowingOrderedTaskGroup(of: Int.self) { group in
            (0..<10).forEach { number in
                group.addTask {
                    await Task.yield()
                    if number == 5 { throw DummyError() }
                    return number
                }
            }
            var results: [Int] = []
            do {
                for try await number in group {
                    results.append(number)
                }
            } catch is DummyError {
                // Expected
            }
            return results
        }
        #expect(results == [0, 1, 2, 3, 4])
    }
}

private struct DummyError: Error {}
