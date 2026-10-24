// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: MPL-2.0
import Testing

/// Read-only wrapper copies may share an array; an ephemeral scalar read must not
/// make every subsequent stored mutation detach that array again.
@Suite struct VDSStoredCollectionReadCowTests {
    @Test func readOnlyStructLocalsKeepTheSameArrayBacking() {
        let original = VDSReadCowValue(values: Array(repeating: 7, count: 256))
        // Inspect raw fields; using the generated getter would create another wrapper.
        // Keep identities alive so the assertion is independent of GC/hash collisions.
        // SKIP INSERT: val field = original.javaClass.declaredFields.first { it.name == "values" || it.name == "smodify_valuesstorage" }.apply { isAccessible = true }
        // SKIP INSERT: val stores = java.util.IdentityHashMap<Any, Boolean>()
        // SKIP INSERT: stores[(field.get(original) as skip.lib.Array<*>).collection] = true
        var sum = 0
        for index in 0..<256 {
            let local = original
            sum += local.values[index]
            // SKIP INSERT: stores[(field.get(local) as skip.lib.Array<*>).collection] = true
        }
        #expect(sum == 1792)
        #expect(original.values == Array(repeating: 7, count: 256))
        // Wrapper copies are permitted; copying all array elements for each local is not.
        // SKIP INSERT: check(stores.size == 1) { "Read-only struct locals used ${stores.size} backing collections" }
    }

    @Test func countReadThenAppendReusesUnsharedBacking() {
        let holder = VDSReadCowArrayHolder()
        // SKIP INSERT: val field = holder.javaClass.declaredFields.first { it.name == "values" || it.name == "smodify_valuesstorage" }.apply { isAccessible = true }
        // SKIP INSERT: val stores = java.util.IdentityHashMap<Any, Boolean>()
        // SKIP INSERT: stores[(field.get(holder) as skip.lib.Array<*>).collection] = true
        for index in 0..<256 {
            #expect(holder.values.count == index)
            #expect(holder.updates == index) // A scalar read must not run didSet.
            holder.values.append(index)
            #expect(holder.updates == index + 1)
            // SKIP INSERT: stores[(field.get(holder) as skip.lib.Array<*>).collection] = true
        }
        #expect(holder.values.count == 256)
        #expect(holder.values.first == 0)
        #expect(holder.values.last == 255)
        // Initial empty storage plus its first mutable backing are allowed.
        // SKIP INSERT: check(stores.size <= 2) { "Count-read append replaced backing collection ${stores.size} times" }
    }

    @Test func isEmptyReadThenAppendReusesUnsharedBacking() {
        let holder = VDSReadCowArrayHolder()
        // SKIP INSERT: val field = holder.javaClass.declaredFields.first { it.name == "values" || it.name == "smodify_valuesstorage" }.apply { isAccessible = true }
        // SKIP INSERT: val stores = java.util.IdentityHashMap<Any, Boolean>()
        // SKIP INSERT: stores[(field.get(holder) as skip.lib.Array<*>).collection] = true
        for index in 0..<256 {
            #expect(holder.values.isEmpty == (index == 0))
            #expect(holder.updates == index)
            holder.values.append(index)
            #expect(holder.updates == index + 1)
            // SKIP INSERT: stores[(field.get(holder) as skip.lib.Array<*>).collection] = true
        }
        #expect(holder.values.count == 256)
        #expect(holder.values.last == 255)
        // SKIP INSERT: check(stores.size <= 2) { "IsEmpty-read append replaced backing collection ${stores.size} times" }
    }

    @Test func scalarReadsAndIndexWritesDetachOnceFromRetainedAlias() {
        let holder = VDSReadCowArrayHolder()
        holder.values = Array(repeating: 0, count: 256)
        let alias = holder.values
        holder.updates = 0
        // SKIP INSERT: val field = holder.javaClass.declaredFields.first { it.name == "values" || it.name == "smodify_valuesstorage" }.apply { isAccessible = true }
        // SKIP INSERT: val stores = java.util.IdentityHashMap<Any, Boolean>()
        // SKIP INSERT: stores[(field.get(holder) as skip.lib.Array<*>).collection] = true
        for index in 0..<256 {
            #expect(holder.values.count == 256)
            #expect(!holder.values.isEmpty)
            #expect(holder.updates == index)
            holder.values[index] = index
            #expect(holder.updates == index + 1)
            // SKIP INSERT: stores[(field.get(holder) as skip.lib.Array<*>).collection] = true
        }
        #expect(alias == Array(repeating: 0, count: 256))
        #expect(holder.values[255] == 255)
        #expect(holder.updates == 256)
        // Only the real escaping alias justifies detachment; temporary scalar
        // reads must not force a fresh array for every following assignment.
        // SKIP INSERT: check(stores.size <= 2) { "Scalar-read index write replaced backing collection ${stores.size} times" }
    }
}

private struct VDSReadCowValue {
    var values: [Int]
}

private final class VDSReadCowArrayHolder {
    var updates = 0
    var values = [Int]() {
        didSet { updates += 1 }
    }
}
