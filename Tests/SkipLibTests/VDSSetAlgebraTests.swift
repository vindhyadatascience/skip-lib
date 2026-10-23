// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: MPL-2.0
import Testing

@Suite struct VDSSetAlgebraTests {
    @Test func setSymmetricDifferenceCancelsANilMember() {
        let left = Set<Int?>([nil, 1])
        let right = Set<Int?>([nil, 2])
        #expect(left.symmetricDifference(right) == Set<Int?>([1, 2]))
        #expect(right.symmetricDifference(left) == Set<Int?>([1, 2]))
        #expect(left.symmetricDifference(left).isEmpty)
        #expect(left == Set<Int?>([nil, 1]))
        #expect(right == Set<Int?>([nil, 2]))
    }

    @Test func sequenceSymmetricDifferenceCancelsNilAndKeepsUnmatchedMembers() {
        let onlyNil = Set<Int?>([nil])
        let same: [Int?] = [nil]
        let disjoint: [Int?] = [2]
        #expect(onlyNil.symmetricDifference(same).isEmpty)
        #expect(onlyNil.symmetricDifference(disjoint) == Set<Int?>([nil, 2]))
        #expect(onlyNil.symmetricDifference([Int?]()) == onlyNil)
        let noNil = Set<Int?>([1])
        #expect(noNil.symmetricDifference(same) == Set<Int?>([nil, 1]))
    }
}
