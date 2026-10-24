// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: LGPL-3.0-only
import Testing

@Suite struct CompilerGapSwiftTestingTests {
    @Test func compoundExpectationsAndBooleanInitializer() throws {
        let value = 1
        #expect(value >= 0 && value < 2)
        #expect(value < 0 || value == 1)
        try #require(value >= 0 && value < 2)
        let flag = true
        try #require(flag)
        let optional: Bool? = false
        let unwrapped = try #require(optional)
        #expect(unwrapped == false)
        #expect(Bool(false) == false)
        let qualifiedBoolean = Swift.Bool(true)
        #expect(qualifiedBoolean)
    }
}
