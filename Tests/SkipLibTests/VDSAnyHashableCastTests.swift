// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: MPL-2.0
import Testing

private struct DynamicCastToken: Hashable {
    let identifier: Int
    let label: String
}

private func eraseCastValue<T: Hashable>(_ value: T) -> AnyHashable {
    AnyHashable(value)
}

private final class CastValueSource {
    var evaluations = 0
    let value: AnyHashable?
    init(value: AnyHashable?) { self.value = value }
    func next() -> AnyHashable? {
        evaluations += 1
        return value
    }
}

@Suite struct VDSAnyHashableCastTests {
    @Test func knownWrapperScalarSuccessAndWrongTypes() {
        let integer: AnyHashable = AnyHashable(42)
        let text: AnyHashable = AnyHashable("retained")
        let qualified: Swift.AnyHashable = AnyHashable(23)
        #expect((qualified as? Int) == 23)
        #expect((integer as? Int) == 42)
        #expect((text as? String) == "retained")
        #expect((integer as? String) == nil)
        #expect((text as? Int) == nil)
    }

    @Test func optionalWrapperPresenceAndAbsence() {
        let integer: AnyHashable? = AnyHashable(42)
        let text: AnyHashable? = AnyHashable("retained")
        let absent: AnyHashable? = nil
        #expect((integer as? Int) == 42)
        #expect((text as? String) == "retained")
        #expect((integer as? String) == nil)
        #expect((text as? Int) == nil)
        #expect((absent as? Int) == nil)
        #expect((absent as? String) == nil)
    }

    @Test func sideEffectingOptionalWrapperSourceIsEvaluatedOnce() {
        let present = CastValueSource(value: AnyHashable(42))
        let found = present.next() as? Int
        #expect(found == 42)
        #expect(present.evaluations == 1)
        let absent = CastValueSource(value: nil)
        let missing = absent.next() as? Int
        #expect(missing == nil)
        #expect(absent.evaluations == 1)
        let wrongType = CastValueSource(value: AnyHashable("text"))
        let refused = wrongType.next() as? Int
        #expect(refused == nil)
        #expect(wrongType.evaluations == 1)
    }

    @Test func genericWrappingCanRecoverConcreteCustomHashable() {
        let original = DynamicCastToken(identifier: 19, label: "retained")
        let boxed: AnyHashable = eraseCastValue(original)
        let recovered = boxed as? DynamicCastToken
        #expect(recovered?.identifier == 19)
        #expect(recovered?.label == "retained")
        #expect((boxed as? String) == nil)
        // The base cast is an independent positive control: it proves the
        // underlying value/type survived generic wrapping before box recovery.
        let base = boxed.base as? DynamicCastToken
        #expect(base?.identifier == 19)
        #expect(base?.label == "retained")
    }

    @Test func ordinaryAnyScalarCastsRemainOrdinaryCasts() {
        let integer: Any = 42
        let text: Any = "retained"
        #expect((integer as? Int) == 42)
        #expect((text as? String) == "retained")
        #expect((integer as? String) == nil)
        #expect((text as? Int) == nil)
    }

    @Test func forcedCastsSucceedForMatchingKnownPayloads() {
        let integer: AnyHashable = AnyHashable(42)
        let text: AnyHashable? = AnyHashable("retained")
        let number = integer as! Int
        let string = text as! String
        #expect(number == 42)
        #expect(string == "retained")
        let source = CastValueSource(value: AnyHashable(42))
        let once = source.next() as! Int
        #expect(once == 42)
        #expect(source.evaluations == 1)
    }

    @Test func typeChecksInspectKnownPayloadAndEvaluateSourceOnce() {
        let source = CastValueSource(value: AnyHashable(42))
        let matches = source.next() is Int
        #expect(matches)
        #expect(source.evaluations == 1)
        let wrongType = source.next() is String
        #expect(!wrongType)
        #expect(source.evaluations == 2)
        let absent = CastValueSource(value: nil)
        let absentMatches = absent.next() is Int
        #expect(!absentMatches)
        #expect(absent.evaluations == 1)
    }

    @Test func anyAnyHashableAndProtocolTargetsRetainTheirWrapper() {
        let integer: AnyHashable = AnyHashable(42)
        let opaque = integer as Any
        let same = integer as AnyHashable
        let optional: AnyHashable? = integer
        let sameOptional = optional as? AnyHashable
        #expect(type(of: opaque) == AnyHashable.self)
        #expect(type(of: same) == AnyHashable.self)
        #expect((sameOptional?.base as? Int) == 42)
        let hashable = integer as any Hashable
        let equatable = integer as any Equatable
        #expect(type(of: hashable) == AnyHashable.self)
        #expect(type(of: equatable) == AnyHashable.self)
    }
}
