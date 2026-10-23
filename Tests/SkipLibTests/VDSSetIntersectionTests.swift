// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: MPL-2.0
import Testing

/// Same assertions run against native Swift Set and the transpiled SkipLib implementation.
@Suite struct VDSSetIntersectionTests {
    @Test func setOverloadRetainsCommonMembers() {
        var value = Set([1, 2, 3])
        value.formIntersection(Set([2, 4]))
        #expect(value == Set([2]))
    }

    @Test func sequenceOverloadIgnoresDuplicatesAndRetainsCommonMembers() {
        var value = Set([1, 2, 3])
        value.formIntersection([2, 2, 4])
        #expect(value == Set([2]))
    }

    @Test func emptyAndDisjointOperandsProduceEmptyIntersections() {
        var value = Set([1, 2, 3])
        value.formIntersection(Set<Int>())
        #expect(value.isEmpty)
        var disjoint = Set([1, 2, 3])
        disjoint.formIntersection([4, 5])
        #expect(disjoint.isEmpty)
        var empty = Set<Int>()
        empty.formIntersection([1, 2])
        #expect(empty.isEmpty)
    }

    @Test func selfIntersectionKeepsEveryMember() {
        var value = Set([1, 2, 3])
        value.formIntersection(value)
        #expect(value == Set([1, 2, 3]))
    }

    @Test func mutationDoesNotChangeACopiedSet() {
        let original = Set([1, 2, 3])
        var changed = original
        changed.formIntersection([2, 4])
        #expect(changed == Set([2]))
        #expect(original == Set([1, 2, 3]))
    }

    @Test func intersectionKeepsTheOriginalEqualMember() {
        var value = Set([VDSIntersectionItem(key: 1, payload: "original"),
                         VDSIntersectionItem(key: 2, payload: "removed")])
        value.formIntersection([VDSIntersectionItem(key: 1, payload: "probe")])
        #expect(value.count == 1)
        #expect(value.first?.payload == "original")
    }

    @Test func storedPropertyMutationPublishesTheIntersection() {
        let holder = VDSIntersectionHolder()
        holder.members.formIntersection([2, 4])
        #expect(holder.members == Set([2]))
        #expect(holder.writes > 0)
    }
}

struct VDSIntersectionItem: Hashable {
    let key: Int
    let payload: String
    static func == (left: VDSIntersectionItem, right: VDSIntersectionItem) -> Bool {
        left.key == right.key
    }
    func hash(into hasher: inout Hasher) { hasher.combine(key) }
}

final class VDSIntersectionHolder {
    var writes = 0
    var members = Set([1, 2, 3]) { didSet { writes += 1 } }
}
