// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
import Testing

@Suite struct VDSStoredCollectionCowTests {
    @Test func storedAppendReusesUnsharedBackingStorage() {
        let holder = VDSCowArrayHolder()
        // Inspect the raw field: using the public getter here would itself create a value copy.
        // Keeping identities alive also makes this independent of GC and identity-hash collisions.
        // The new accessor has explicit storage; the old lowering used the property field itself.
        // SKIP INSERT: val field = holder.javaClass.declaredFields.first { it.name == "values" || it.name == "smodify_valuesstorage" }.apply { isAccessible = true }
        // SKIP INSERT: val stores = java.util.IdentityHashMap<Any, Boolean>()
        for index in 0..<256 {
            holder.values.append(index)
            // SKIP INSERT: stores[(field.get(holder) as skip.lib.Array<*>).collection] = true
        }
        #expect(holder.values.count == 256)
        #expect(holder.values.first == 0)
        #expect(holder.values.last == 255)
        #expect(holder.updates == 256)
        // Each replacement in the old implementation copied the entire growing list. Capacity
        // growth inside ArrayList is allowed; an ArrayList object per append is not.
        // SKIP INSERT: check(stores.size <= 2) { "Stored append replaced backing collection ${stores.size} times" }
    }

    @Test func storedIndexWritesDetachOnceFromExternalAlias() {
        let holder = VDSCowArrayHolder()
        holder.values = Array(repeating: 0, count: 256)
        let alias = holder.values
        holder.updates = 0
        // SKIP INSERT: val field = holder.javaClass.declaredFields.first { it.name == "values" || it.name == "smodify_valuesstorage" }.apply { isAccessible = true }
        // SKIP INSERT: val stores = java.util.IdentityHashMap<Any, Boolean>()
        for index in 0..<256 {
            holder.values[index] = index
            // SKIP INSERT: stores[(field.get(holder) as skip.lib.Array<*>).collection] = true
        }
        #expect(alias == Array(repeating: 0, count: 256))
        #expect(holder.values[255] == 255)
        #expect(holder.updates == 256)
        // SKIP INSERT: check(stores.size <= 2) { "Stored index write replaced backing collection ${stores.size} times" }
    }

    @Test func readsAndNestedWritebackKeepValueSemantics() {
        var original = VDSCowNestedValue()
        original.values = [1, 2]
        var copy = original
        let read = original.values
        copy.values.append(3)
        original.values[0] = 9
        #expect(read == [1, 2])
        #expect(copy.values == [1, 2, 3])
        #expect(original.values == [9, 2])
        let holder = VDSCowNestedHolder()
        holder.value = original
        let outside = holder.value
        holder.value.values.append(4)
        #expect(outside.values == [9, 2])
        #expect(holder.value.values == [9, 2, 4])
    }

    @Test func inoutAndThrowingWritebackPreserveAliases() {
        let holder = VDSCowArrayHolder()
        holder.values = [1]
        let alias = holder.values
        func append(_ values: inout [Int]) { values.append(2) }
        append(&holder.values)
        #expect(alias == [1])
        #expect(holder.values == [1, 2])
        enum Failure: Error { case expected }
        func mutateAndThrow(_ values: inout [Int]) throws {
            values.append(3)
            throw Failure.expected
        }
        do {
            try mutateAndThrow(&holder.values)
            #expect(false, "Expected mutation error")
        } catch {
            #expect(holder.values == [1, 2, 3])
            #expect(alias == [1])
        }
    }
}

final class VDSCowArrayHolder {
    var updates = 0
    var values = [Int]() {
        didSet { updates += 1 }
    }
}

struct VDSCowNestedValue {
    var values = [Int]()
}

final class VDSCowNestedHolder {
    var value = VDSCowNestedValue()
}
