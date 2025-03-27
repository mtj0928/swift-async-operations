# swift-async-operations
A library extending the capability of async operations.

## Motivation
Swift concurrency is powerful language feature, but there are not APIs operating an array for swift concurrency.
A developer is required to write redundant code.
```swift
var results: [Int] = [] // ☹️ var is required.
for await element in [0, 1, 2, 3, 4] {
    let newElement = try await twice(element)
    result.append(newElement)
}
print(results) // [0, 2, 4, 6, 8]
```

In a case where the loop needs to run concurrently, a developer is required to write more redundant code.
```swift
 // ☹️ Long redundant code
let array = [0, 1, 2, 3, 4]
let results = try await withThrowingTaskGroup(of: (Int, Int).self) { group in
    for (index, number) in array.enumerated() {
        group.addTask {
            (index, try await twice(number))
        }
    }
    var results: [Int: Int] = [:]
    for try await (index, result) in group {
        results[index] = result
    }
    // ☹️ Need to take the order into account.
    return results.sorted(by: { $0.key < $1.key }).map(\.value)
}
print(results) // [0, 2, 4, 6, 8]
```

## Solution
This library provides async functions as extensions of `Sequence` like `asyncMap`.
```swift
let converted = try await [0, 1, 2, 3, 4].asyncMap { number in
    try await twice(number)
}
print(converted) // [0, 2, 4, 6, 8]
```
The closure runs sequentially by default.
And by specifying a max number of tasks, the closure can also run concurrently.

```swift
let converted = try await [0, 1, 2, 3, 4].asyncMap(numberOfConcurrentTasks: 8) { number in
    try await twice(number)
}
print(converted) // [0, 2, 4, 6, 8]
```

## Feature Details
The library provides two features.
1. Async functions of `Sequence`.
2. Ordered Task Group

### Async functions of `Sequence`
This library provides async operations like `asyncForEach` and `asyncMap`.

```swift
try await [1, 2, 3].asyncForEach { number in
    print("Start: \(number)")
    try await doSomething(number)
    print("End: \(number)")
}
```

The closure runs sequential by default.

```
Start: 1
End: 1
Start: 2
End: 2
Start: 3
End: 3
```

As an advanced usage, `numberOfConcurrentTasks` can be specified and the closure can run in parallel if the value is 2 or more.
```swift
try await [1, 2, 3].asyncForEach(numberOfConcurrentTasks: 3) { number in
    print("Start: \(number)")
    try await doSomething(number)
    print("End: \(number)")
}
```

```
Start: 2
End: 2
Start: 1
Start: 3
End: 3
End: 1
```

The extended functions perform parallel execution even for order-sensitive functions like `map` function, 
transforming the array while preserving the original order.
```swift
let result = try await [1, 2, 3].asyncMap(numberOfConcurrentTasks: 3) { number in
    print("Start: \(number)")
    let result = try await twice(number)
    print("End: \(number)")
    return result
}
print(result)
```

```
Start: 1
Start: 3
End: 3
End: 1
Start: 2
End: 2
[2, 4, 6]
```
This library provides
- Sequence
    - [asyncForEach](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/swift/sequence/asyncforeach(numberofconcurrenttasks:priority:_:))
    - [asyncMap](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/swift/sequence/asyncmap(numberofconcurrenttasks:priority:_:))
    - [asyncFlatMap](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/swift/sequence/asyncflatmap(numberofconcurrenttasks:priority:_:))
    - [asyncCompactMap](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/swift/sequence/asynccompactmap(numberofconcurrenttasks:priority:_:))
    - [asyncFilter](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/swift/sequence/asyncfilter(numberofconcurrenttasks:priority:_:))
    - [asyncFirst](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/swift/sequence/asyncfirst(numberofconcurrenttasks:priority:where:))
    - [asyncAllSatisfy](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/swift/sequence/asyncallsatisfy(numberofconcurrenttasks:priority:_:))
    - [asyncContains](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/swift/sequence/asynccontains(numberofconcurrenttasks:priority:where:))
    - [asyncReduce](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/swift/sequence/asyncreduce(into:_:))
- AsyncSequence
    - [asyncForEach](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/_concurrency/asyncsequence/asyncforeach(numberofconcurrenttasks:priority:_:))

### Ordered Task Group
The original utility function `withTaskGroup` and `withThrowingTaskGroup` don't ensure the order of `for await`.
```swift
let results = await withTaskGroup(of: Int.self) { group in
    (0..<5).forEach { number in
        group.addTask {
            await Task.yield()
            return number * 2
        }
    }
    var results: [Int] = []
    for await number in group {
        results.append(number)
    }
    return results
}
print(results) // ☹️ [0, 4, 2, 6, 10, 8]
```

However, ordered `for await` is required in some of situations like converting an array to a new array.

[withOrderedTaskGroup](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/withorderedtaskgroup(of:returning:isolation:body:)) and [withThrowingOrderedTaskGroup](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/withthrowingorderedtaskgroup(of:returning:isolation:body:)) satisfy such requirements.
```swift
let results = await withOrderedTaskGroup(of: Int.self) { group in
    (0..<5).forEach { number in
        group.addTask {
            await Task.yield()
            return number * 2
        }
    }
    var results: [Int] = []
    for await number in group {
        results.append(number)
    }
    return results
}
print(results) // 😁 [0, 2, 4, 6, 8, 10]
```

They are also used for async functions of `Sequence`.

## Requirements
Swift 5.10 or later.

## Installation
You can install the library via Swift Package Manager.
```swift
dependencies: [
  .package(url: "https://github.com/mtj0928/swift-async-operations", from: "0.1.0")
]
```

## Documentations
Please see [the DocC pages](https://mtj0928.github.io/swift-async-operations/documentation/asyncoperations/)
