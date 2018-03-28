//
//  SynchronizedArray.swift
//  App
//
//  Created by Koray Koska on 07.10.17.
//

import Foundation
#if os(Linux)
    import Dispatch
#endif

public final class SynchronizedArray<Element>: Sequence {

    private var internalArray: [Element] = []
    private let accessQueue = DispatchQueue(label: "SynchronizedArrayAccess", attributes: .concurrent)

    public var array: [Element] {
        get {
            var arrayCopy: [Element]?

            accessQueue.sync {
                arrayCopy = self.internalArray
            }

            return arrayCopy!
        }

        set {
            let arrayCopy = newValue

            accessQueue.async(flags: .barrier) {
                self.internalArray = arrayCopy
            }
        }
    }

    public init() {
    }

    public init(array: [Element]) {
        self.internalArray = array
    }

    public func append(_ newElement: Element) {
        self.accessQueue.async(flags: .barrier) {
            self.internalArray.append(newElement)
        }
    }

    public func remove(at index: Int) {
        self.accessQueue.async(flags: .barrier) {
            self.internalArray.remove(at: index)
        }
    }

    public var count: Int {
        var count = 0

        self.accessQueue.sync {
            count = self.internalArray.count
        }

        return count
    }

    public var isEmpty: Bool {
        var e: Bool!

        self.accessQueue.sync {
            e = self.internalArray.isEmpty
        }

        return e
    }

    public func first() -> Element? {
        var element: Element?

        self.accessQueue.sync {
            if !self.internalArray.isEmpty {
                element = self.internalArray[0]
            }
        }

        return element
    }

    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        // Get array copy
        let arrayCopy = array

        return try arrayCopy.map(transform)
    }

    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        // Get array copy
        let arrayCopy = array

        return try arrayCopy.filter(isIncluded)
    }

    public subscript(index: Int) -> Element {
        set {
            self.accessQueue.async(flags: .barrier) {
                self.internalArray[index] = newValue
            }
        }
        get {
            var element: Element!

            self.accessQueue.sync {
                element = self.internalArray[index]
            }

            return element
        }
    }

    public func makeIterator() -> Array<Element>.Iterator {
        var iterator: Array<Element>.Iterator!

        accessQueue.sync {
            iterator = self.internalArray.makeIterator()
        }

        return iterator
    }
}
