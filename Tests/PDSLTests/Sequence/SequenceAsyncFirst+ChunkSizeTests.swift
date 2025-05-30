import XCTest
@testable import PDSL

actor ExecutionOrderTracker {
    private var order: [Int] = []
    
    func append(_ number: Int) {
        order.append(number)
    }
    
    func getOrder() -> [Int] {
        return order
    }
}

final class SequenceAsyncFirstChunkSizeTests: XCTestCase {
    func testAsyncFirstWithChunkSize() async throws {
        let array = [1, 2, 3, 4, 5]
        
        // 条件を満たす要素が存在する場合
        let result1 = await array.pdslFirst(chunkSize: 2) { number in
            await Task.yield()
            return number == 3
        }
        XCTAssertEqual(result1, 3)
        
        // 条件を満たす要素が存在しない場合
        let result2 = await array.pdslFirst(chunkSize: 2) { number in
            await Task.yield()
            return number == 6
        }
        XCTAssertNil(result2)
    }
    
    func testAsyncFirstWithEmptySequence() async throws {
        let array: [Int] = []
        
        let result = await array.pdslFirst(chunkSize: 2) { number in
            await Task.yield()
            return number == 1
        }
        XCTAssertNil(result)
    }
    
    func testAsyncFirstWithLargeSequence() async throws {
        let array = Array(1...100)
        
        // チャンクサイズが要素数より小さい場合
        let result1 = await array.pdslFirst(chunkSize: 10) { number in
            await Task.yield()
            return number == 50
        }
        XCTAssertEqual(result1, 50)
        
        // チャンクサイズが要素数より大きい場合
        let result2 = await array.pdslFirst(chunkSize: 200) { number in
            await Task.yield()
            return number == 75
        }
        XCTAssertEqual(result2, 75)
    }
    
    func testAsyncFirstWithDifferentChunkSizes() async throws {
        let array = Array(1...100)
        
        // チャンクサイズが1の場合（逐次処理に近い）
        let result1 = await array.pdslFirst(chunkSize: 1) { number in
            await Task.yield()
            return number == 25
        }
        XCTAssertEqual(result1, 25)
        
        // チャンクサイズが要素数と同じ場合（並列処理）
        let result2 = await array.pdslFirst(chunkSize: array.count) { number in
            await Task.yield()
            return number == 50
        }
        XCTAssertEqual(result2, 50)
    }
    
    func testAsyncFirstWithThrowingPredicate() async throws {
        let array = Array(1...100)
        
        do {
            _ = try await array.pdslFirst(chunkSize: 20) { element in
                throw NSError(domain: "test", code: 1)
            }
            XCTFail("Should throw an error")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "test")
            XCTAssertEqual(nsError.code, 1)
        }
    }
    
    func testAsyncFirstWithPriority() async throws {
        let array = Array(1...100)
        
        let result = await array.pdslFirst(
            chunkSize: 10,
            priority: .high
        ) { element in
            await Task.yield()
            return element == 50
        }
        XCTAssertEqual(result, 50)
    }
    
    func testAsyncFirstWithConcurrentExecution() async throws {
        let array = Array(1...100)
        let tracker = ExecutionOrderTracker()
        
        let result = await array.pdslFirst(chunkSize: 10) { number in
            await Task.yield()
            await tracker.append(number)
            return number == 50
        }
        
        XCTAssertEqual(result, 50)
        // 実行順序が保証されていないことを確認
        let executionOrder = await tracker.getOrder()
        XCTAssertNotEqual(executionOrder, Array(1...50))
    }
} 
