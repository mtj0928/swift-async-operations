import AsyncOperations
import XCTest

final class SequenceAsyncForEachChunkSizeTests: XCTestCase {
    private actor ProcessedNumbers {
        private var numbers: [Int] = []
        
        func append(_ number: Int) {
            numbers.append(number)
        }
        
        func removeAll() {
            numbers.removeAll()
        }
        
        func getNumbers() -> [Int] {
            numbers
        }
    }
    
    func testAsyncForEachWithChunkSize() async throws {
        let numbers = [1, 2, 3, 4, 5]
        let processedNumbers = ProcessedNumbers()
        
        await numbers.asyncForEach(chunkSize: 2) { number in
            await Task.yield()
            await processedNumbers.append(number)
        }
        
        let result = await processedNumbers.getNumbers()
        XCTAssertEqual(result, [1, 2, 3, 4, 5])
    }
    
    func testAsyncForEachWithDifferentChunkSizes() async throws {
        let numbers = [1, 2, 3]
        let processedNumbers = ProcessedNumbers()
        
        // チャンクサイズが要素数より大きい場合
        await numbers.asyncForEach(chunkSize: 5) { number in
            await Task.yield()
            await processedNumbers.append(number)
        }
        let result1 = await processedNumbers.getNumbers()
        XCTAssertEqual(result1, [1, 2, 3])
        
        await processedNumbers.removeAll()
        
        // チャンクサイズが1の場合（個別処理と同等）
        await numbers.asyncForEach(chunkSize: 1) { number in
            await Task.yield()
            await processedNumbers.append(number)
        }
        let result2 = await processedNumbers.getNumbers()
        XCTAssertEqual(result2, [1, 2, 3])
    }
}
