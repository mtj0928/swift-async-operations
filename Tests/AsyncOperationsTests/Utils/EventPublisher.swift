final actor EventPublisher {
    private var alreadyPublished: Set<Int> = []
    private var continuations: [Int: CheckedContinuation<Void, Never>] = [:]

    func send(_ key: Int) {
        alreadyPublished.insert(key)
        if let continuation = continuations[key] {
            continuation.resume()
            self.continuations[key] = nil
        }
    }

    func wait(for key: Int) async {
        await withCheckedContinuation { continuation in
            if alreadyPublished.contains(key) {
                continuation.resume()
            } else {
                continuations[key] = continuation
            }
        }
    }
}
