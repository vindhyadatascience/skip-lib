// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: MPL-2.0
import Testing

/// RNABrowser-fiea.15: retrieving an equal custom member must use its hash lookup, not
/// scan the set. Counters are local to each test; these bounds measure comparisons,
/// not scheduler-dependent elapsed time. Copy-on-write costs remain a separate concern.
@Suite struct VDSCanonicalSetMemberTests {
    private func members(_ count: Int, counter: VDSCanonicalCounter) -> Set<VDSCanonicalObject> {
        var result = Set<VDSCanonicalObject>()
        for key in 0..<count {
            result.insert(VDSCanonicalObject(key: key, payload: "stored", counter: counter))
        }
        return result
    }

    @Test func duplicateCustomInsertUsesBoundedEqualityCalls() {
        let counter = VDSCanonicalCounter()
        var set = members(4_096, counter: counter)
        let probe = VDSCanonicalObject(key: 4_095, payload: "probe", counter: counter)
        counter.calls = 0
        for _ in 0..<64 {
            let result = set.insert(probe)
            #expect(!result.inserted)
            #expect(result.memberAfterInsert.payload == "stored")
        }
        #expect(counter.calls < 2_048, "existing custom members require hash lookups, not scans: \(counter.calls)")
    }

    @Test func customRemoveUsesBoundedEqualityCalls() {
        let counter = VDSCanonicalCounter()
        var set = members(4_096, counter: counter)
        let probe = VDSCanonicalObject(key: 4_095, payload: "probe", counter: counter)
        counter.calls = 0
        for _ in 0..<64 {
            let removed = set.remove(probe)
            #expect(removed?.payload == "stored")
            set.insert(VDSCanonicalObject(key: 4_095, payload: "stored", counter: counter))
        }
        #expect(counter.calls < 2_048, "custom remove requires hash lookup, not a member scan: \(counter.calls)")
    }

    @Test func customUpdateUsesBoundedEqualityCalls() {
        let counter = VDSCanonicalCounter()
        var set = members(4_096, counter: counter)
        counter.calls = 0
        for _ in 0..<64 {
            let old = set.update(with: VDSCanonicalObject(key: 4_095, payload: "updated", counter: counter))
            #expect(old != nil)
        }
        #expect(counter.calls < 2_048, "custom update requires hash lookup, not a member scan: \(counter.calls)")
    }

    @Test func equalObjectsKeepTheStoredInstanceUntilUpdate() {
        let counter = VDSCanonicalCounter()
        let first = VDSCanonicalObject(key: 7, payload: "first", counter: counter)
        let equal = VDSCanonicalObject(key: 7, payload: "equal", counter: counter)
        var set: Set<VDSCanonicalObject> = [first]
        let duplicate = set.insert(equal)
        #expect(!duplicate.inserted)
        #expect(duplicate.memberAfterInsert === first)
        #expect(set.update(with: equal) === first)
        #expect(set.insert(first).memberAfterInsert === equal)
        #expect(set.remove(first) === equal)
        #expect(set.isEmpty)
        #expect(set.remove(first) == nil)
        #expect(set.update(with: first) == nil)
        #expect(set.first === first)
    }

    @Test func looseStructEqualityKeepsPayloadAndValueCopies() {
        var set: Set<VDSCanonicalItem> = [VDSCanonicalItem(key: 1, payload: "original")]
        let equal = VDSCanonicalItem(key: 1, payload: "replacement")
        var returned = set.insert(equal).memberAfterInsert
        returned.payload = "changed outside the set"
        #expect(set.first?.payload == "original")
        #expect(set.update(with: equal)?.payload == "original")
        #expect(set.remove(VDSCanonicalItem(key: 1, payload: "ignored"))?.payload == "replacement")
        #expect(set.isEmpty)
    }

    @Test func collisionsDoNotConfuseCanonicalMembers() {
        let counter = VDSCanonicalCounter()
        let one = VDSCanonicalObject(key: 1, payload: "one", counter: counter, collide: true)
        let two = VDSCanonicalObject(key: 2, payload: "two", counter: counter, collide: true)
        let twoAgain = VDSCanonicalObject(key: 2, payload: "new two", counter: counter, collide: true)
        var set: Set<VDSCanonicalObject> = [one, two]
        #expect(set.insert(twoAgain).memberAfterInsert === two)
        #expect(set.update(with: twoAgain) === two)
        #expect(set.remove(two) === twoAgain)
        #expect(set.first === one)
    }

    @Test func nilMembersArePresentEvenWhenTheirStoredValueIsNil() {
        var set = Set<Int?>()
        #expect(set.insert(nil).inserted)
        #expect(!set.insert(nil).inserted)
        set.insert(3)
        #expect(set.contains(nil))
        #expect(set.contains(3))
        #expect(set.count == 2)
        _ = set.update(with: nil)
        #expect(set.count == 2)
        _ = set.remove(nil)
        #expect(!set.contains(nil))
        #expect(set.count == 1)
    }

    @Test func copiedSetsDetachTheirCanonicalMembersOnMutation() {
        let counter = VDSCanonicalCounter()
        let original = VDSCanonicalObject(key: 1, payload: "original", counter: counter)
        let replacement = VDSCanonicalObject(key: 1, payload: "replacement", counter: counter)
        var first: Set<VDSCanonicalObject> = [original]
        var copy = first
        #expect(copy.update(with: replacement) === original)
        #expect(first.insert(replacement).memberAfterInsert === original)
        #expect(copy.insert(original).memberAfterInsert === replacement)
        copy.removeAll()
        #expect(copy.isEmpty)
        #expect(first.first === original)
        let popped = first.popFirst()
        #expect(popped === original)
        #expect(first.isEmpty)
    }

    @Test func storedSetMutationsStillNotifyTheirOwnerAndLocalCopiesDoNot() {
        let holder = VDSCanonicalSetHolder()
        holder.members.insert(VDSCanonicalItem(key: 1, payload: "a"))
        #expect(holder.updates == 1)
        holder.members.update(with: VDSCanonicalItem(key: 1, payload: "b"))
        #expect(holder.updates == 2)
        var local = holder.members
        local.remove(VDSCanonicalItem(key: 1, payload: "ignored"))
        #expect(holder.updates == 2)
        #expect(holder.members.first?.payload == "b")
        holder.members.removeAll()
        #expect(holder.updates == 3)
        #expect(holder.members.isEmpty)
    }

    @Test func bulkAndIteratorRoutesKeepCanonicalMembersConsistent() {
        var set: Set<VDSCanonicalItem> = [VDSCanonicalItem(key: 1, payload: "first")]
        set.formUnion([VDSCanonicalItem(key: 1, payload: "ignored"), VDSCanonicalItem(key: 2, payload: "second")])
        #expect(set.insert(VDSCanonicalItem(key: 1, payload: "probe")).memberAfterInsert.payload == "first")
        set.subtract([VDSCanonicalItem(key: 2, payload: "probe")])
        #expect(set.count == 1)
        set.formSymmetricDifference([VDSCanonicalItem(key: 1, payload: "probe"), VDSCanonicalItem(key: 3, payload: "third")])
        #expect(set.count == 1)
        #expect(set.remove(VDSCanonicalItem(key: 3, payload: "probe"))?.payload == "third")
        #expect(set.isEmpty)
    }

    @Test func kotlinMutableViewAndIteratorShareTheCanonicalStore() {
        #if SKIP
        // Exercise the public Kotlin MutableSet view without a second test helper/module.
        // SKIP INSERT: val counter = VDSCanonicalCounter()
        // SKIP INSERT: val first = VDSCanonicalObject(key = 1, payload = "first", counter = counter)
        // SKIP INSERT: val equal = VDSCanonicalObject(key = 1, payload = "equal", counter = counter)
        // SKIP INSERT: val set = skip.lib.Set<VDSCanonicalObject?>()
        // SKIP INSERT: set.insert(first)
        // SKIP INSERT: set.insert(null)
        // SKIP INSERT: check(!set.insert(null)._e0)
        // SKIP INSERT: check(set.insert(null)._e1 == null)
        // SKIP INSERT: @Suppress("UNCHECKED_CAST")
        // SKIP INSERT: val sibling = set.scopy() as skip.lib.Set<VDSCanonicalObject?>
        // SKIP INSERT: @Suppress("UNCHECKED_CAST")
        // SKIP INSERT: val view = set.kotlin(nocopy = true) as MutableSet<VDSCanonicalObject?>
        // SKIP INSERT: check(!view.add(equal))
        // SKIP INSERT: check(set.remove(equal) === first)
        // SKIP INSERT: check(view.add(equal))
        // SKIP INSERT: val iterator = view.iterator()
        // SKIP INSERT: while (iterator.hasNext()) {
        // SKIP INSERT:     if (iterator.next() === equal) iterator.remove()
        // SKIP INSERT: }
        // SKIP INSERT: check(!set.contains(equal))
        // SKIP INSERT: check(set.contains(null))
        // SKIP INSERT: view.add(first)
        // SKIP INSERT: check(set.update(with = equal) === first)
        // SKIP INSERT: check(view.first { it != null } === equal)
        // SKIP INSERT: view.retainAll(listOf(equal))
        // SKIP INSERT: check(!set.contains(null))
        // SKIP INSERT: view.removeAll(listOf(equal))
        // SKIP INSERT: check(!set.contains(equal))
        // SKIP INSERT: view.add(first)
        // SKIP INSERT: view.clear()
        // SKIP INSERT: check(set.isEmpty)
        // SKIP INSERT: check(sibling.count == 2)
        // SKIP INSERT: check(sibling.insert(equal)._e1 === first)
        // SKIP INSERT: val foreign = kotlin.collections.linkedSetOf<VDSCanonicalObject?>(first, null)
        // SKIP INSERT: val imported = skip.lib.Set<VDSCanonicalObject?>(foreign, nocopy = true)
        // SKIP INSERT: check(imported.insert(equal)._e1 === first)
        // SKIP INSERT: check(imported.contains(null))
        #endif
    }
}

final class VDSCanonicalCounter {
    var calls = 0
}

final class VDSCanonicalObject: Hashable {
    let key: Int
    let payload: String
    let counter: VDSCanonicalCounter
    let collide: Bool

    init(key: Int, payload: String, counter: VDSCanonicalCounter, collide: Bool = false) {
        self.key = key
        self.payload = payload
        self.counter = counter
        self.collide = collide
    }

    static func ==(lhs: VDSCanonicalObject, rhs: VDSCanonicalObject) -> Bool {
        lhs.counter.calls += 1
        return lhs.key == rhs.key && lhs.collide == rhs.collide
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(collide ? 0 : key)
    }
}

struct VDSCanonicalItem: Hashable {
    let key: Int
    var payload: String

    static func ==(lhs: VDSCanonicalItem, rhs: VDSCanonicalItem) -> Bool {
        lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

final class VDSCanonicalSetHolder {
    var updates = 0
    var members = Set<VDSCanonicalItem>() {
        didSet { updates += 1 }
    }
}
