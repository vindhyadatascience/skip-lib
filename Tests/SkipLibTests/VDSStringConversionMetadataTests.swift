// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: MPL-2.0
import Testing

@Suite struct VDSStringConversionMetadataTests {
    @Test func nestedNumericConversionSelectsElementContains() {
        let tokens = ["25", "100"]
        let stated: Int? = 25
        var matched = false
        if let stated { matched = tokens.contains(String(stated)) }
        #expect(matched)
        #expect(!tokens.contains(String(26)))
    }

    @Test func scalarConversionsKeepTheirConcreteValues() {
        let values = [String(Int8(-8)), String(Int16(-16)), String(Int32(-32)),
                      String(Int(-64)), String(Int64(-128)), String(UInt8(8)),
                      String(UInt16(16)), String(UInt32(32)), String(UInt(64)),
                      String(UInt64(128)), String(Float(1.5)), String(Double(2.5)),
                      String(true), String(false)]
        #expect(values == ["-8", "-16", "-32", "-64", "-128", "8", "16", "32", "64", "128", "1.5", "2.5", "true", "false"])
        let character: Character = "x"
        #expect(String(character) == "x")
        #expect(String("unchanged") == "unchanged")
    }

    @Test func genericConsumersAndHoistedValuesRetainStringType() {
        struct Count { let value: Int }
        let value = Count(value: 25)
        let tokens = ["25"]
        #expect(vdsConversionContains(tokens, String(value.value)))
        var evaluations = 0
        func next() -> Int { evaluations += 1; return 25 }
        let matched = tokens.contains(String(next()))
        #expect(matched)
        #expect(evaluations == 1)
    }
}

private func vdsConversionContains<T: Equatable>(_ values: [T], _ value: T) -> Bool {
    return values.contains(value)
}
