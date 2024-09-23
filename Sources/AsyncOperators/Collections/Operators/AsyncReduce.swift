extension Sequence where Element: Sendable {
    public func asyncReduce<Result>(
        _ initialResult: Result,
        _ nextPartialResult: (Result, Element) async throws -> Result
    ) async rethrows -> Result {
        var result = initialResult

        for element in self {
            result = try await nextPartialResult(result, element)
        }

        return result
    }

    public func asyncReduce<Result>(
        into initialResult: Result,
        _ updateAccumulatingResult: (inout Result, Element) async throws -> ()
    ) async rethrows -> Result {
        var result = initialResult

        for element in self {
            try await updateAccumulatingResult(&result, element)
        }

        return result
    }
}
