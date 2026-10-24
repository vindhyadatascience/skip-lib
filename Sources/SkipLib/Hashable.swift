// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
// SKIP SYMBOLFILE

#if SKIP

public protocol Hashable: Equatable {
    var hashValue: Int { get }
}

// RNABrowser-fiea.30: AnyHashable stays a typealias. 1.4.4+vds.3 made it a Kotlin wrapper class,
// and collections from JSONSerialization, Kotlin maps and Firestore payloads hold raw keys, so
// every `[AnyHashable: Any]` read threw ClassCastException on the JVM.
typealias AnyHashable = Hashable

public struct Hasher {
    public init() {
    }

    public mutating func combine(_ value: Any?) {
    }

    public func finalize() -> Int {
        fatalError()
    }

    static func combine(result: Int, value: Any?) -> Int {
        fatalError()
    }
}

#endif
