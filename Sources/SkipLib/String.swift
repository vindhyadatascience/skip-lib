// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
// SKIP SYMBOLFILE

#if SKIP

public struct String: RandomAccessCollection {
    public typealias Element = Character
    public typealias Index = Int

    public init() {
    }

    public init(_ string: String) {
    }

    // These concrete Swift conversions already use the positional Kotlin
    // String(describing: Any?) implementation. Keep source matching narrower
    // than Any so arbitrary objects still require String(describing:).
    public init(_ value: Bool) {
    }

    public init(_ value: Character) {
    }

    public init(_ value: Int) {
    }

    public init(_ value: Int8) {
    }

    public init(_ value: Int16) {
    }

    public init(_ value: Int32) {
    }

    public init(_ value: Int64) {
    }

    public init(_ value: Int128) {
    }

    public init(_ value: UInt) {
    }

    public init(_ value: UInt8) {
    }

    public init(_ value: UInt16) {
    }

    public init(_ value: UInt32) {
    }

    public init(_ value: UInt64) {
    }

    public init(_ value: UInt128) {
    }

    public init(_ value: Float) {
    }

    public init(_ value: Double) {
    }

    public init(_ substring: Substring) {
    }

    public init(describing instance: Any?) {
    }

    public init(repeating: String, count: Int) {
    }

    public func lowercased() -> String {
        fatalError()
    }

    public func uppercased() -> String {
        fatalError()
    }

    public mutating func append(_ other: Character) {
    }

    public mutating func append(_ other: String) {
    }

    public mutating func append(contentsOf newElements: any Sequence<Character>) {
    }

    public func hasPrefix(_ prefix: String) -> Bool {
        fatalError()
    }

    public func hasSuffix(_ suffix: String) -> Bool {
        fatalError()
    }

    public func contains(_ string: String) -> Bool {
        fatalError()
    }

    public func dropFirst(_ k: Int = 1) -> String {
        fatalError()
    }

    public func dropLast(_ k: Int = 1) -> String {
        fatalError()
    }

    public subscript(bounds: Range<Index>) -> Substring {
        fatalError()
    }

    // Support in String although it is not yet supported in Collection
    public func split(separator: String, maxSplits: Int = Int.max, omittingEmptySubsequences: Bool = true) -> [String] {
        fatalError()
    }

    public func matches(of r: Regex) -> [Regex.Match] {
        fatalError()
    }

    public func replacing(_ other: String, with: String) -> String {
        fatalError()
    }

    public func replacing(_ regex: Regex, with: String) -> String {
        fatalError()
    }

    public func replacing(_ regex: Regex, maxReplacements: Int = Int.max, with replacement: (Regex.Match) throws -> String) rethrows -> String {
        fatalError()
    }
}

public struct Substring: RandomAccessCollection {
    public typealias Element = Character

    public func lowercased() -> String {
        fatalError()
    }
    
    public func uppercased() -> String {
        fatalError()
    }

    public func hasPrefix(_ prefix: String) -> Bool {
        fatalError()
    }

    public func hasSuffix(_ suffix: String) -> Bool {
        fatalError()
    }

    public func contains(_ string: String) -> Bool {
        fatalError()
    }

    public func dropFirst(_ k: Int = 1) -> String {
        fatalError()
    }

    public func dropLast(_ k: Int = 1) -> String {
        fatalError()
    }

    public func filter(_ isIncluded: (Character) throws -> Bool) rethrows -> String {
        fatalError()
    }

    public subscript(bounds: Range<Index>) -> Substring {
        fatalError()
    }

    // Support in String although it is not yet supported in Collection
    public func split(separator: String, maxSplits: Int = Int.max, omittingEmptySubsequences: Bool = true) -> [String] {
        fatalError()
    }
}

/// String(format:) constructor.
public func String(format: String, _ args: Any...) -> String {
    fatalError()
}

/// String(format:) constructor.
public func String(format: String, arguments: [Any]) -> String {
    fatalError()
}

public struct Character {
    public init(_ character: Character) {
    }

    public init(_ string: String) {
    }

    public var isASCII: Bool {
        fatalError()
    }

    public var asciiValue: UInt8? {
        fatalError()
    }

    public var isWhitespace: Bool {
        fatalError()
    }

    public var isNewline: Bool {
        fatalError()
    }

    @available(*, unavailable)
    public var isNumber: Bool {
        fatalError()
    }

    @available(*, unavailable)
    public var isWholeNumber: Bool {
        fatalError()
    }

    @available(*, unavailable)
    public var wholeNumberValue: Int? {
        fatalError()
    }

    @available(*, unavailable)
    public var isHexDigit: Bool {
        fatalError()
    }

    @available(*, unavailable)
    public var hexDigitValue: Int? {
        fatalError()
    }

    @available(*, unavailable)
    public var isLetter: Bool {
        fatalError()
    }

    public func uppercased() -> String {
        fatalError()
    }

    public func lowercased() -> String {
        fatalError()
    }

    public var isUppercase: Bool {
        fatalError()
    }

    public var isLowercase: Bool {
        fatalError()
    }

    @available(*, unavailable)
    public var isCased: Bool {
        fatalError()
    }

    @available(*, unavailable)
    public var isSymbol: Bool {
        fatalError()
    }

    @available(*, unavailable)
    public var isMathSymbol: Bool {
        fatalError()
    }

    @available(*, unavailable)
    public var isCurrencySymbol: Bool {
        fatalError()
    }

    @available(*, unavailable)
    public var isPunctuation: Bool {
        fatalError()
    }
}

public typealias CChar = Character

public typealias StaticString = String

#endif
