// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: MPL-2.0
import Testing
#if !SKIP
import Foundation
#endif

@Suite(.serialized) struct VDSStringFormatLocaleTests {
    @Test func defaultFormattingUsesNeutralLocaleForBothOverloads() {
        #if SKIP
        let previous = java.util.Locale.getDefault()
        defer { java.util.Locale.setDefault(previous) }
        java.util.Locale.setDefault(java.util.Locale.GERMANY)
        #endif
        #expect(String(format: "%.2f", 1.5) == "1.50")
        #expect(String(format: "%.2f", arguments: [1.5]) == "1.50")
        #expect(String(format: "%2$@ %1$.2f", 1.5, "value") == "value 1.50")
        #expect(String(format: "%% %.2f", 1.5) == "% 1.50")
    }
}
