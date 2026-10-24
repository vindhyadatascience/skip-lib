// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: MPL-2.0
import Testing

private final class NumericCastValueSource {
    var evaluations = 0
    let value: AnyHashable?
    init(value: AnyHashable?) { self.value = value }
    func next() -> AnyHashable? {
        evaluations += 1
        return value
    }
}

/// Expectations come from the retained native observation probes. Narrow-width
/// cases explicitly use Int32/UInt32, matching both native and Skip widths.
@Suite struct VDSAnyHashableNumericCastTests {
    @Test func measuredWholeNumberCrossCastsRecoverTheRequestedType() {
        let integer = AnyHashable(Int(7))
        let double = AnyHashable(Double(7))
        let float = AnyHashable(Float(7))
        let unsigned = AnyHashable(UInt64(7))
        #expect((integer as? Double) == 7.0)
        #expect((integer as? Float) == Float(7))
        #expect((double as? Int) == 7)
        #expect((float as? UInt64) == UInt64(7))
        #expect((unsigned as? Int) == 7)
        #expect((unsigned as? Double) == 7.0)
    }

    @Test func measuredBooleanAndZeroCastsFollowTheNativeReference() {
        let truth = AnyHashable(true)
        #expect((truth as? Int) == 1)
        #expect((truth as? Double) == 1.0)
        #expect((AnyHashable(Double(0.0)) as? Bool) == false)
        #expect((AnyHashable(Float(-0.0)) as? Bool) == false)
        #expect((AnyHashable(Int(7)) as? Bool) == nil)
    }

    @Test func measuredFloatingCastsRetainNegativeZeroAndNaN() {
        let negativeDouble = AnyHashable(Double(-0.0))
        let negativeFloat = AnyHashable(Float(-0.0))
        let recoveredFloat = negativeDouble as? Float
        let recoveredDouble = negativeFloat as? Double
        #expect(recoveredFloat != nil)
        #expect(recoveredDouble != nil)
        #expect(Float(1.0) / recoveredFloat! == -Float.infinity)
        #expect(Double(1.0) / recoveredDouble! == -Double.infinity)
        let widenedNaN = AnyHashable(Float.nan) as? Double
        let narrowedNaN = AnyHashable(Double.nan) as? Float
        #expect(widenedNaN?.isNaN == true)
        #expect(narrowedNaN?.isNaN == true)
    }

    @Test func fractionsAndLossyFloatingConversionsAreRefused() {
        let tenth = AnyHashable(Double(0.1))
        let half = AnyHashable(Double(0.5))
        let fraction = AnyHashable(Double(1.5))
        #expect((tenth as? Float) == nil)
        #expect((half as? Float) == Float(0.5))
        #expect((fraction as? Int) == nil)
        let integerCheck = fraction is Int
        let floatCheck = half is Float
        #expect(!integerCheck)
        #expect(floatCheck)
        let exactFloat = AnyHashable(Float(0.1))
        #expect((exactFloat as? Double) == Double(Float(0.1)))
    }

    @Test func narrowIntegerBoundsAndUnsignedRangesMatchNative() {
        #expect((AnyHashable(Int64(-129)) as? Int8) == nil)
        #expect((AnyHashable(Int64(-128)) as? Int8) == Int8.min)
        #expect((AnyHashable(Int64(127)) as? Int8) == Int8.max)
        #expect((AnyHashable(Int64(128)) as? Int8) == nil)
        #expect((AnyHashable(Int64(255)) as? UInt8) == UInt8.max)
        #expect((AnyHashable(Int64(256)) as? UInt8) == nil)
        #expect((AnyHashable(Int64(-1)) as? UInt64) == nil)
        let signedMaximum = AnyHashable(Int64(Int32.max))
        let aboveSigned = AnyHashable(Int64(Int32.max) + 1)
        #expect((signedMaximum as? Int32) == Int32.max)
        #expect((aboveSigned as? Int32) == nil)
        let unsignedMaximum = AnyHashable(UInt64(UInt32.max))
        let aboveUnsigned = AnyHashable(UInt64(UInt32.max) + 1)
        #expect((unsignedMaximum as? UInt32) == UInt32.max)
        #expect((aboveUnsigned as? UInt32) == nil)
    }

    @Test func wideIntegerPrecisionLossIsNotSilentlyRounded() {
        #expect((AnyHashable(Int64.max) as? Double) == nil)
        #expect((AnyHashable(UInt64.max) as? Double) == nil)
        #expect((AnyHashable(UInt64.max) as? Float) == nil)
        #expect((AnyHashable(Int64(16_777_217)) as? Float) == nil)
        #expect((AnyHashable(Int64(9_007_199_254_740_993)) as? Double) == nil)
    }

    @Test func roundedSigned64UpperEndpointMatchesMeasuredNativeBridge() {
        let roundedSigned = AnyHashable(Double(Int64.max))
        #expect((roundedSigned as? Int64) == Int64.max)
        let roundedUnsigned = AnyHashable(Double(UInt64.max))
        #expect((roundedUnsigned as? UInt64) == nil)
    }

    @Test func crossNumericSourcesAreEvaluatedOnceForCastsAndChecks() {
        let source = NumericCastValueSource(value: AnyHashable(Double(7)))
        let recovered = source.next() as? Int
        #expect(recovered == 7)
        #expect(source.evaluations == 1)
        let matches = source.next() is UInt64
        #expect(matches)
        #expect(source.evaluations == 2)
        let forced = source.next() as! Float
        #expect(forced == Float(7))
        #expect(source.evaluations == 3)
        let absent = NumericCastValueSource(value: nil)
        let missing = absent.next() as? Double
        #expect(missing == nil)
        #expect(absent.evaluations == 1)
    }
}
