import XCTest
@testable import PDSL

final class SequenceAsyncContainsChunkSizeTests: XCTestCase {
    func testAsyncContainsWithChunkSize() async throws {
        let containsResult = await [1, 2, 3].pdslContains(chunkSize: 2) { number in
            return number == 2
        }
        XCTAssertTrue(containsResult)

        let notContainsResult = await [1, 2, 3].pdslContains(chunkSize: 2) { number in
            return number == 4
        }
        XCTAssertFalse(notContainsResult)
    }
    
    func testAsyncContainsWithEmptySequence() async throws {
        let result = await [Int]().pdslContains(chunkSize: 2) { number in
            return number == 1
        }
        XCTAssertFalse(result)
    }
    
    func testAsyncContainsWithLargeSequence() async throws {
        let array = Array(1...100)
        
        let containsResult = await array.pdslContains(chunkSize: 10) { number in
            return number == 50
        }
        XCTAssertTrue(containsResult)
        
        let notContainsResult = await array.pdslContains(chunkSize: 10) { number in
            return number == 101
        }
        XCTAssertFalse(notContainsResult)
    }
    
    func testAsyncContainsWithDifferentChunkSizes() async throws {
        let array = Array(1...100)
        
        // チャンクサイズが要素数より大きい場合
        let result1 = await array.pdslContains(chunkSize: 200) { number in
            return number == 50
        }
        XCTAssertTrue(result1)
        
        // チャンクサイズが要素数より小さい場合
        let result2 = await array.pdslContains(chunkSize: 10) { number in
            return number == 75
        }
        XCTAssertTrue(result2)
    }
    
    func testAsyncContainsWithThrowingPredicate() async throws {
        let array = Array(1...100)
        
        do {
            _ = try await array.pdslContains(chunkSize: 20) { element in
                throw NSError(domain: "test", code: 1)
            }
            XCTFail("Should throw an error")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "test")
            XCTAssertEqual(nsError.code, 1)
        }
    }
    
    func testAsyncContainsWithPriority() async throws {
        let array = Array(1...100)
        
        let result = await array.pdslContains(
            chunkSize: 10,
            priority: .high
        ) { element in
            await Task.yield()
            return element == 50
        }
        XCTAssertTrue(result)
    }
} 
