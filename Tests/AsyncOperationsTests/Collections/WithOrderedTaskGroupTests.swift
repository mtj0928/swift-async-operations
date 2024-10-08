import AsyncOperations
import XCTest

final class WithOrderedTaskGroupTests: XCTestCase {
    func testWithOrderedTaskGroup() async throws {
        let results = await withOrderedTaskGroup(of: Int.self) { group in
            (0..<10).forEach { number in
                group.addTask {
                    await Task.yield()
                    return number
                }
            }
            var results: [Int] = []
            for await number in group {
                results.append(number)
            }
            return results
        }

        XCTAssertEqual(results, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    }
}
