extension Sequence where Element: Sendable {
    public func asyncFirst(where predicate: @escaping (Element) async throws -> Bool) async rethrows -> Element? {
        for element in self {
            if try await predicate(element) {
                return element
            }
        }

        return nil
    }
}
