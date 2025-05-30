import XCTest
@testable import PDSL

final class SequenceAsyncReduceChunkSizeTests: XCTestCase {
    func testAsyncReduceWithChunkSize() async throws {
        let array = Array(1...10)
        
        // 合計を計算
        let sum = await array.pdslReduce(0, chunkSize: 3) { result, element in
            await Task.yield()
            return result + element
        }
        XCTAssertEqual(sum, 55)
        
        // 文字列を連結
        let string = await array.pdslReduce("", chunkSize: 3) { result, element in
            await Task.yield()
            return result + String(element)
        }
        XCTAssertEqual(string, "12345678910")
    }
    
    func testAsyncReduceIntoWithChunkSize() async throws {
        let array = Array(1...10)
        
        // 配列に要素を追加
        let result = await array.pdslReduce(into: [Int](), chunkSize: 3) { result, element in
            await Task.yield()
            result.append(element * 2)
        }
        XCTAssertEqual(result, [2, 4, 6, 8, 10, 12, 14, 16, 18, 20])
    }
    
    func testAsyncReduceWithEmptySequence() async throws {
        let array: [Int] = []
        
        let sum = await array.pdslReduce(0, chunkSize: 3) { result, element in
            await Task.yield()
            return result + element
        }
        XCTAssertEqual(sum, 0)
        
        let result = await array.pdslReduce(into: [Int](), chunkSize: 3) { result, element in
            await Task.yield()
            result.append(element)
        }
        XCTAssertEqual(result, [])
    }
    
    func testAsyncReduceWithDifferentChunkSizes() async throws {
        let array = Array(1...100)
        
        // チャンクサイズが要素数より大きい場合
        let sum1 = await array.pdslReduce(0, chunkSize: 200) { result, element in
            await Task.yield()
            return result + element
        }
        XCTAssertEqual(sum1, 5050)
        
        // チャンクサイズが要素数より小さい場合
        let sum2 = await array.pdslReduce(0, chunkSize: 10) { result, element in
            await Task.yield()
            return result + element
        }
        XCTAssertEqual(sum2, 5050)
    }
    
    func testAsyncReduceWithThrowingPredicate() async throws {
        let array = Array(1...10)
        
        do {
            _ = try await array.pdslReduce(0, chunkSize: 3) { result, element in
                throw NSError(domain: "test", code: 1)
            }
            XCTFail("Should throw an error")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "test")
            XCTAssertEqual(nsError.code, 1)
        }
    }
    
    func testAsyncReduceWithPriority() async throws {
        let array = Array(1...10)
        
        let sum = await array.pdslReduce(
            0,
            chunkSize: 3,
            priority: .high
        ) { result, element in
            await Task.yield()
            return result + element
        }
        XCTAssertEqual(sum, 55)
    }
}
