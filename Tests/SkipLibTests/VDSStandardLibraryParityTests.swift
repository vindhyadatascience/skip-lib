// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Testing

@Suite struct VDSStandardLibraryParityTests {
    @Test func signedZeroCollectionKeysAndNestedValues() {
        var set: Set<Double> = [-0.0]
        let insertion = set.insert(0.0)
        #expect(!insertion.inserted)
        #expect(1.0 / insertion.memberAfterInsert == -Double.infinity)
        #expect(set.count == 1)
        #expect(set.contains(0.0))
        #expect(set == Set([0.0]))
        #expect(Set([-0.0]).intersection(Set([0.0])).count == 1)
        #expect(Set([-0.0]).subtracting(Set([0.0])).isEmpty)
        var dictionary: [Double: String] = [-0.0: "first"]
        dictionary[0.0] = "updated"
        #expect(dictionary.count == 1)
        #expect(dictionary[-0.0] == "updated")
        #expect(1.0 / dictionary.keys.first! == -Double.infinity)
        #expect([-0.0] == [0.0])
        #expect(["value": [-0.0]] == ["value": [0.0]])
        #expect(Set([[-0.0], [0.0]]).count == 1)
        #expect(Set<Float>([-0.0, 0.0]).count == 1)
    }

    @Test func nanMembershipAndIndependentContainers() {
        let nan = Double.nan
        let first = [nan]
        let shared = first
        let independent = [nan]
        #expect(first == shared)
        #expect(!(first == independent))
        #expect(!first.elementsEqual(shared))
        #expect(!first.contains(nan))
        #expect(first.firstIndex(of: nan) == nil)
        #expect(first.lastIndex(of: nan) == nil)
        let set = Set([nan])
        #expect(!set.contains(nan))
        #expect(set == set)
        #expect(!(set == Set([nan])))
        #expect(Set([nan, nan]).count == 2)
        #expect(set.union(set).count == 2)
        #expect(set.intersection(set).isEmpty)
        #expect(set.symmetricDifference(set).count == 2)
        #expect(set.subtracting(set).count == 1)
        var selfUnion = set
        selfUnion.formUnion(selfUnion)
        #expect(selfUnion.count == 2)
        var selfDifference = set
        selfDifference.formSymmetricDifference(selfDifference)
        #expect(selfDifference.count == 2)
        var ordinary = Set([1, 2])
        ordinary.formSymmetricDifference(ordinary)
        #expect(ordinary.isEmpty)
        let dictionary = ["value": nan]
        let sharedDictionary = dictionary
        #expect(dictionary == sharedDictionary)
        #expect(!(dictionary == ["value": nan]))
    }

    @Test func nullableDictionaryAndKotlinMutableViews() {
        var dictionary: [Int?: String?] = [nil: nil, 1: "one"]
        #expect(dictionary.count == 2)
        #expect(dictionary.keys.contains(nil))
        #expect(dictionary.values.contains(nil))
        var copy = dictionary
        dictionary.removeValue(forKey: nil)
        #expect(dictionary.count == 1)
        #expect(copy.keys.contains(nil))
        copy[1] = "changed"
        #expect(dictionary[1] == "one")
        var values = [1]
        var arrays = [String: [Int]]()
        arrays.updateValue(values, forKey: "key")
        values.append(2)
        #expect(arrays["key"] == [1])
        let arraysCopy = arrays
        var removed = arrays.removeValue(forKey: "key")!
        removed.append(3)
        #expect(arraysCopy["key"] == [1])
        #if SKIP
        // Direct runtime routes do not depend on compiler equality/AnyHashable lowering.
        // SKIP INSERT: check(skip.lib.swiftEquatableEquals(-0.0, 0.0))
        // SKIP INSERT: check(!skip.lib.swiftEquatableEquals(Double.NaN, Double.NaN))
        // SKIP INSERT: check(!skip.lib.swiftEquatableEquals(1, 1.0))
        // SKIP INSERT: val erased = skip.lib.AnyHashable(1.0f)
        // SKIP INSERT: check(erased.base is Float)
        // SKIP INSERT: check(erased == skip.lib.AnyHashable(1))
        // SKIP INSERT: val set = skip.lib.setOf(-0.0)
        // SKIP INSERT: @Suppress("UNCHECKED_CAST")
        // SKIP INSERT: val view = set.kotlin(nocopy = true) as MutableSet<Double>
        // SKIP INSERT: check(!view.add(0.0))
        // SKIP INSERT: check(!view.retainAll(listOf(0.0)))
        // SKIP INSERT: check(view.size == 1)
        // SKIP INSERT: check(view.removeAll(listOf(0.0)))
        // SKIP INSERT: check(set.isEmpty)
        // SKIP INSERT: val map = skip.lib.dictionaryOf(skip.lib.Tuple2(-0.0, "first"))
        // SKIP INSERT: @Suppress("UNCHECKED_CAST")
        // SKIP INSERT: val mutable = map.kotlin(nocopy = true) as MutableMap<Double, String>
        // SKIP INSERT: mutable[0.0] = "updated"
        // SKIP INSERT: check(mutable.size == 1 && mutable[-0.0] == "updated")
        // SKIP INSERT: check(1.0 / mutable.keys.first() == Double.NEGATIVE_INFINITY)
        // SKIP INSERT: check(mutable.keys.removeAll(listOf(0.0)))
        // SKIP INSERT: check(map.isEmpty)
        // SKIP INSERT: mutable[Double.NaN] = "nan"
        // SKIP INSERT: mutable[Double.NaN] = "second nan"
        // SKIP INSERT: check(mutable.size == 2 && !mutable.containsKey(Double.NaN))
        // SKIP INSERT: val iterator = mutable.entries.iterator()
        // SKIP INSERT: iterator.next()
        // SKIP INSERT: iterator.remove()
        // SKIP INSERT: check(mutable.size == 1)
        #endif
    }

    @Test func anyHashableNumericIdentityAndBase() {
        #expect(AnyHashable(Int(1)) == AnyHashable(Double(1)))
        #expect(AnyHashable(Float(1)) == AnyHashable(Double(1)))
        #expect(AnyHashable(Float(-0.0)) == AnyHashable(Double(0.0)))
        #expect(AnyHashable(Float(0.1)) != AnyHashable(Double(0.1)))
        #expect(AnyHashable(true) != AnyHashable(Int(1)))
        #expect(AnyHashable(Int64(9_007_199_254_740_993)) != AnyHashable(Double(9_007_199_254_740_993)))
        #expect(AnyHashable(Double.nan) != AnyHashable(Double.nan))
        let wrapped = AnyHashable(Float(1))
        #expect(wrapped.base as? Float == Float(1))
        #expect(wrapped.base as? Double == nil)
        #expect(Set([AnyHashable(Int(1)), AnyHashable(Float(1)), AnyHashable(Double(1))]).count == 1)
        #expect([AnyHashable(Int(1)): "one"][AnyHashable(Double(1))] == "one")
        #expect([AnyHashable(-0.0)] == [AnyHashable(0.0)])
    }

    @Test func anyHashableTypedOptionalErasure() {
        let absentInteger: Int? = nil
        let absentString: String? = nil
        let presentInteger: Int? = 1
        let erasedNil = AnyHashable(absentInteger)
        let erasedNilAgain = AnyHashable(absentInteger)
        #expect(erasedNil == erasedNilAgain)
        #expect(erasedNil != AnyHashable(absentString))
        #expect(AnyHashable(presentInteger) == AnyHashable(1.0))
        let absentWrapper: AnyHashable? = nil
        let presentNilWrapper: AnyHashable? = erasedNil
        #expect(absentWrapper == nil)
        #expect(presentNilWrapper != nil)
        #expect(Set([erasedNil, erasedNilAgain, AnyHashable(absentString)]).count == 2)
        #if SKIP
        // SKIP INSERT: check(skip.lib.anyHashableOptional(null, type = "Int") == skip.lib.anyHashableOptional(null, type = "Int"))
        // SKIP INSERT: check(skip.lib.anyHashableOptional(null, type = "Int") != skip.lib.anyHashableOptional(null, type = "String"))
        // SKIP INSERT: check(skip.lib.anyHashableOptional(1, type = "Int") == skip.lib.AnyHashable(1.0))
        #endif
    }

    @Test func exactIntegerAndSquareRoot() {
        #expect(Int(exactly: Double(42)) == 42)
        #expect(Int(exactly: Float(-42)) == -42)
        #expect(Int(exactly: Double(0.5)) == nil)
        #expect(Int(exactly: Double.infinity) == nil)
        #expect(Int(exactly: Double.nan) == nil)
        #expect(Int(exactly: -0.0) == 0)
        #expect(Int(exactly: Double(Int.min)) == Int.min)
        // Parse at runtime: Int.max rounds to 2^63 as a Double. Keep the exact
        // boundary check out of the compiler's constant-conversion evaluator.
        let upperBoundary = Double(String(Int.max))! + 1.0
        #expect(Int(exactly: upperBoundary) == nil)
        #expect(Int(exactly: Int8(-7)) == -7)
        #expect(Int(exactly: UInt16(7)) == 7)
        #expect(Int(exactly: Int64(Int.min)) == Int.min)
        #expect(Int(exactly: Int64(Int.max)) == Int.max)
        #expect(Int(exactly: UInt64(Int.max) + 1) == nil)
        #expect(Int(exactly: UInt64.max) == nil)
        #expect(Double(9).squareRoot() == 3)
        #expect(Float(9).squareRoot() == 3)
        #expect(Double(-1).squareRoot().isNaN)
        #expect(1.0 / Double(-0.0).squareRoot() == -Double.infinity)
    }

    @available(macOS 15, iOS 18, tvOS 18, watchOS 11, *)
    @Test func exactIntegerFrom128BitIntegers() {
        #expect(Int(exactly: Int128(42)) == 42)
        #expect(Int(exactly: UInt128(42)) == 42)
    }

    @Test func groupingPreservesOrderAndPropagatesErrors() throws {
        var calls = 0
        let result = Dictionary(grouping: [1, 2, 3, 4, 5]) { value in
            calls += 1
            return value % 2
        }
        #expect(calls == 5)
        #expect(result[0] == [2, 4])
        #expect(result[1] == [1, 3, 5])
        let empty = Dictionary(grouping: [Int](), by: { $0 % 2 })
        #expect(empty.isEmpty)
        let nullableValues: [Int?] = [nil, 1, nil]
        let nullable = Dictionary(grouping: nullableValues, by: { $0 })
        #expect(nullable[nil]?.count == 2)
        #expect(nullable[1] == [1])
        enum Failure: Error { case expected }
        do {
            _ = try Dictionary(grouping: [1, 2, 3]) { value -> Int in
                if value == 2 { throw Failure.expected }
                return value
            }
            #expect(false, "Grouping must propagate the closure error")
        } catch Failure.expected {
        }
    }

    @Test func stringAppendWritesBack() {
        var text = "A"
        let character: Character = "é"
        text.append(character)
        text.append("BC")
        text.append(contentsOf: "🦊")
        #expect(text == "AéBC🦊")
        struct Value { var text = "start" }
        var value = Value()
        value.text.append(" end")
        #expect(value.text == "start end")
        let copy = value
        value.text.append("!")
        #expect(copy.text == "start end")
        #expect(value.text == "start end!")
    }

    @Test func stringAppendEvaluatesAddressesOnceAndNilLazily() {
        let holder = VDSAppendHolder()
        var receiverCalls = 0
        func receiver() -> VDSAppendHolder {
            receiverCalls += 1
            return holder
        }
        receiver().text.append("B")
        #expect(receiverCalls == 1)
        #expect(holder.reads == 1)
        #expect(holder.writes == 1)
        #expect(holder.stored == "AB")
        var indexCalls = 0
        func index() -> Int {
            indexCalls += 1
            return 0
        }
        var words = ["start"]
        words[index()].append(" end")
        #expect(indexCalls == 1)
        #expect(words == ["start end"])
        let absent: VDSAppendHolder? = nil
        var suffixCalls = 0
        func suffix() -> String {
            suffixCalls += 1
            return "unused"
        }
        absent?.text.append(suffix())
        #expect(suffixCalls == 0)
        var optionalText: String? = nil
        optionalText?.append(suffix())
        #expect(suffixCalls == 0)
        var characters = ""
        let suffixCharacters: [Character] = ["é", "A"]
        characters.append(contentsOf: suffixCharacters)
        characters.append(contentsOf: "🦊🦊")
        #expect(characters == "éA🦊🦊")
    }
}

final class VDSAppendHolder {
    var reads = 0
    var writes = 0
    var stored = "A"
    var text: String {
        get {
            reads += 1
            return stored
        }
        set {
            writes += 1
            stored = newValue
        }
    }
}
