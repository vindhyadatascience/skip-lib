// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: LGPL-3.0-only
import XCTest

private enum CompilerGapInner { case number(Int); case text(String) }
private enum CompilerGapOuter { case box(CompilerGapInner); case empty }
private enum CompilerGapError: Error { case value(Int); case other }
private struct CompilerGapInitialized {
    let value: Int
    init(_ value: Int) { self.value = value }
}
private struct CompilerGapTestData { static func testValue() -> Int { 42 } }

private struct CompilerGapGenericOuter<T> {
    struct Inner<U> {
        let outer: T
        let inner: U
    }
}

final class CompilerGapRuntimeTests: XCTestCase {
    func testExplicitSynchronousDetachedBodies() async {
        let number = await Task.detached { () -> Int in 42 }.value
        XCTAssertEqual(number, 42)
        let result: Void = await Task.detached { () -> Void in }.value
        let marker = await Task.detached { () -> Int in
            let value = 7
            return value * 6
        }.value
        _ = result
        XCTAssertEqual(marker, 42)
        let continued = await withCheckedContinuation { (continuation: CheckedContinuation<Int, Never>) in
            continuation.resume(returning: 42)
        }
        XCTAssertEqual(continued, 42)
    }

    func testUnicodeScalarEscapeContents() {
        XCTAssertEqual("a\u{1F98A}\u{10FFFF}", "a🦊􏿿")
        XCTAssertEqual("\u{41}\u{00000042}", "AB")
        XCTAssertEqual("\\u{1F98A}", "\\u{1F98A}")
    }

    func testCharacterLiteralsAppendThroughTypedCharacters() {
        let letter: Character = "q"
        let accented: Character = "\u{00E9}"
        var word = "a"
        word.append(letter)
        word.append(accented)
        XCTAssertEqual(word, "aqé")
    }

    func testNestedAssociatedPatternsAndCatchWhere() {
        func number(_ value: CompilerGapOuter) -> Int {
            switch value {
            case .box(.number(let value)): return value
            case .box(.text(let value)): return value.count
            case .empty: return -1
            }
        }
        XCTAssertEqual(number(.box(.number(42))), 42)
        XCTAssertEqual(number(.box(.text("abc"))), 3)
        XCTAssertEqual(number(.empty), -1)
        var result = 0
        do {
            throw CompilerGapError.value(42)
        } catch CompilerGapError.value(let code) where code < 0 {
            result = -1
        } catch CompilerGapError.value(let code) where code > 0 {
            result = code
        } catch {
            result = -2
        }
        XCTAssertEqual(result, 42)
    }

    func testLocalTypesLabeledTuplesAndStoredLetInitialization() {
        struct Local {
            let value: Int
            static func doubled(_ value: Int) -> Int { value * 2 }
        }
        let local = Local(value: Local.doubled(21))
        let tuple = (answer: local.value, label: "ok")
        XCTAssertEqual(tuple.answer, 42)
        XCTAssertEqual(tuple.label, "ok")
        XCTAssertEqual(CompilerGapInitialized(42).value, 42)
        XCTAssertEqual(CompilerGapTestData.testValue(), 42)
    }

    func testTrailingClosureBeforeDefaultedCallback() {
        func row(value: Int, label: () -> String, onEditingChanged: (Bool) -> Void = { _ in }) -> String {
            label() + String(value)
        }
        XCTAssertEqual(row(value: 42) { "count:" }, "count:42")
    }
    func testGenericNestedTypesRetainBothArguments() {
        let value = CompilerGapGenericOuter<Int>.Inner<String>(outer: 42, inner: "ok")
        XCTAssertEqual(value.outer, 42)
        XCTAssertEqual(value.inner, "ok")
    }

}
