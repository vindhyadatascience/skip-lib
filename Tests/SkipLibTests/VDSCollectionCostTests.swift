// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: MPL-2.0
import Testing

/// VDS fork (vds.1): Set.insert/remove/update use hash lookups, and Array.last indexes the backing
/// list. Semantics run on both runtimes; the cost ratios run on the JVM, where the bugs were.
@Suite struct VDSCollectionCostTests {
    @Test func insertReturnsStoredMemberForStructWithLooseEquality() {
        var set = Set<VDSLooseItem>()
        #expect(set.insert(VDSLooseItem(key: 1, payload: "first")).inserted)
        let again = set.insert(VDSLooseItem(key: 1, payload: "second"))
        #expect(!again.inserted)
        #expect(again.memberAfterInsert.payload == "first")
        #expect(set.count == 1)
    }

    @Test func insertReturnsStoredInstanceForClass() {
        let stored = VDSLooseObject(key: 7)
        let probe = VDSLooseObject(key: 7)
        var set: Set<VDSLooseObject> = [stored]
        let result = set.insert(probe)
        #expect(!result.inserted)
        #expect(result.memberAfterInsert === stored)
    }

    @Test func removeAndUpdateReturnOldMember() {
        var set = Set<VDSLooseItem>()
        set.insert(VDSLooseItem(key: 1, payload: "a"))
        set.insert(VDSLooseItem(key: 2, payload: "b"))
        #expect(set.update(with: VDSLooseItem(key: 1, payload: "a2"))?.payload == "a")
        #expect(set.update(with: VDSLooseItem(key: 3, payload: "c")) == nil)
        #expect(set.first { $0.key == 1 }?.payload == "a2")
        #expect(set.remove(VDSLooseItem(key: 2, payload: "ignored"))?.payload == "b")
        #expect(set.remove(VDSLooseItem(key: 9, payload: "none")) == nil)
        #expect(set.count == 2)

        var strings: Set<String> = ["x", "y"]
        #expect(strings.insert("x") == (false, "x"))
        #expect(strings.insert("z") == (true, "z"))
        #expect(strings.remove("y") == "y")
        #expect(strings.remove("q") == nil)
        #expect(strings.update(with: "x") == "x")
        #expect(strings.count == 2)
    }

    @Test func lastOfArray() {
        let array = [10, 20, 30, 40, 50]
        #expect(array.last == 50)
        #expect(array.first == 10)
        #expect([Int]().last == nil)

        var structs = [VDSLooseItem(key: 1, payload: "a"), VDSLooseItem(key: 2, payload: "b")]
        var last = structs.last!
        last.payload = "changed"
        #expect(structs.last?.payload == "b")
        structs.append(last)
        #expect(structs.last?.payload == "changed")
    }

    @Test func setInsertIsLinearOnJVM() {
        #if SKIP
        _ = vdsBestOf3 { vdsBuildSet(2_000) }
        let small = vdsBestOf3 { vdsBuildSet(4_000) }
        let large = vdsBestOf3 { vdsBuildSet(64_000) }
        // 16x the elements: linear is ~16x, the old indexOf scan was ~256x.
        let ratio = Double(large) / Double(max(small, Int64(1)))
        #expect(ratio < 80.0, "Set.insert 64k/4k cost ratio \(ratio)")
        #endif
    }

    @Test func arrayLastIsConstantOnJVM() {
        #if SKIP
        let small = Array(0..<1_000)
        let large = Array(0..<128_000)
        _ = vdsBestOf3 { vdsReadLast(small, times: 2_000) }
        let smallCost = vdsBestOf3 { vdsReadLast(small, times: 20_000) }
        let largeCost = vdsBestOf3 { vdsReadLast(large, times: 20_000) }
        // 128x the elements: constant is ~1x, the old iterator walk was ~128x.
        let ratio = Double(largeCost) / Double(max(smallCost, Int64(1)))
        #expect(ratio < 10.0, "Array.last 128k/1k cost ratio \(ratio)")
        #endif
    }
}

struct VDSLooseItem: Hashable {
    let key: Int
    var payload: String

    static func ==(lhs: VDSLooseItem, rhs: VDSLooseItem) -> Bool {
        return lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

final class VDSLooseObject: Hashable {
    let key: Int

    init(key: Int) {
        self.key = key
    }

    static func ==(lhs: VDSLooseObject, rhs: VDSLooseObject) -> Bool {
        return lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

#if SKIP
private func vdsBestOf3(_ body: () -> Int) -> Int64 {
    var best = Int64.max
    var sink = 0
    for _ in 0..<3 {
        let start = java.lang.System.nanoTime()
        sink += body()
        let elapsed = java.lang.System.nanoTime() - start
        if elapsed < best {
            best = elapsed
        }
    }
    if sink == -1 {
        print("unreachable")
    }
    return best
}

private func vdsBuildSet(_ n: Int) -> Int {
    var set = Set<Int>()
    for i in 0..<n {
        set.insert(i)
    }
    return set.count
}

private func vdsReadLast(_ xs: [Int], times: Int) -> Int {
    var sum = 0
    for _ in 0..<times {
        sum += xs.last ?? 0
    }
    return sum
}
#endif
