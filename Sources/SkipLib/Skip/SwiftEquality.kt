// Copyright 2026 Skip
// SPDX-License-Identifier: MPL-2.0
package skip.lib

/// Swift floating-point Equatable uses IEEE equality, including through generic/optional values.
/// Do not use an identity shortcut here: even the same boxed NaN is unequal to itself.
fun swiftEquatableEquals(lhs: Any?, rhs: Any?): Boolean = when (lhs) {
    is Double -> rhs is Double && lhs.toDouble() == rhs.toDouble()
    is Float -> rhs is Float && lhs.toFloat() == rhs.toFloat()
    else -> lhs == rhs
}

/// Equal positive and negative zeros must land in the same hash bucket.
fun swiftEquatableHash(value: Any?): Int = when (value) {
    is Double -> if (value == 0.0) 0 else value.hashCode()
    is Float -> if (value == 0.0f) 0 else value.hashCode()
    else -> value?.hashCode() ?: 0
}

/// Swift's exact cross-numeric Hashable equality (`AnyHashable(1) == AnyHashable(1.0)`), for runtime
/// code that compares erased identities. AnyHashable itself stays a typealias (RNABrowser-fiea.30).
fun swiftAnyHashableEquals(lhs: Any, rhs: Any): Boolean {
    val left = exactNumericValue(lhs)
    val right = exactNumericValue(rhs)
    if (left != null && right != null) return left.compareTo(right) == 0
    // Infinities have no BigDecimal representation, but compare across Float/Double.
    if (lhs is Double && rhs is Float) return lhs == rhs.toDouble()
    if (lhs is Float && rhs is Double) return lhs.toDouble() == rhs
    return swiftEquatableEquals(lhs, rhs)
}

// BigDecimal(Double), unlike valueOf(Double), preserves the exact binary value. This avoids
// equating a rounded Double with a neighboring Int64, or Float(0.1) with Double(0.1).
private fun exactNumericValue(value: Any): java.math.BigDecimal? = when (value) {
    is Byte -> java.math.BigDecimal.valueOf(value.toLong())
    is Short -> java.math.BigDecimal.valueOf(value.toLong())
    is Int -> java.math.BigDecimal.valueOf(value.toLong())
    is Long -> java.math.BigDecimal.valueOf(value)
    is UByte -> java.math.BigDecimal(value.toString())
    is UShort -> java.math.BigDecimal(value.toString())
    is UInt -> java.math.BigDecimal(value.toString())
    is ULong -> java.math.BigDecimal(value.toString())
    is Float -> if (value.isFinite()) java.math.BigDecimal(value.toDouble()) else null
    is Double -> if (value.isFinite()) java.math.BigDecimal(value) else null
    else -> null
}

/// Map keys use Swift equality while the public keys/entries preserve original types and values.
/// Fresh lookup wrappers intentionally avoid HashMap's key-identity shortcut for NaN.
internal class SwiftHashableMap<K, V>() : AbstractMutableMap<K, V>() {
    private class Key(val value: Any?) {
        override fun equals(other: Any?): Boolean = other is Key && swiftEquatableEquals(value, other.value)
        override fun hashCode(): Int = swiftEquatableHash(value)
    }
    private class Entry<K, V>(override val key: K, private var storedValue: V) : MutableMap.MutableEntry<K, V> {
        override val value: V get() = storedValue
        override fun setValue(newValue: V): V {
            val previous = value
            storedValue = newValue
            return previous
        }
        override fun equals(other: Any?): Boolean = other is Map.Entry<*, *> &&
            swiftEquatableEquals(key, other.key) && swiftEquatableEquals(value, other.value)
        override fun hashCode(): Int = swiftEquatableHash(key) xor swiftEquatableHash(value)
        override fun toString(): String = "$key=$value"
    }
    private val members = LinkedHashMap<Key, Entry<K, V>>()

    constructor(source: Map<K, V>) : this() {
        for ((key, value) in source) put(key, value)
    }

    override val size: Int get() = members.size
    override fun containsKey(key: K): Boolean = members.containsKey(Key(key))
    override fun containsValue(value: V): Boolean = members.values.any { swiftEquatableEquals(it.value, value) }
    override fun get(key: K): V? = members[Key(key)]?.value
    override fun put(key: K, value: V): V? {
        val lookup = Key(key)
        val previous = members[lookup]
        if (previous != null) return previous.setValue(value)
        members[lookup] = Entry(key, value)
        return null
    }
    override fun remove(key: K): V? = members.remove(Key(key))?.value
    override fun clear() = members.clear()

    override val entries: MutableSet<MutableMap.MutableEntry<K, V>>
        get() = object : AbstractMutableSet<MutableMap.MutableEntry<K, V>>() {
            override val size: Int get() = members.size
            override fun add(element: MutableMap.MutableEntry<K, V>): Boolean = throw UnsupportedOperationException()
            override fun contains(element: MutableMap.MutableEntry<K, V>): Boolean {
                val entry = members[Key(element.key)] ?: return false
                return swiftEquatableEquals(entry.value, element.value)
            }
            override fun remove(element: MutableMap.MutableEntry<K, V>): Boolean {
                if (!contains(element)) return false
                members.remove(Key(element.key))
                return true
            }
            override fun clear() = members.clear()
            override fun removeAll(elements: kotlin.collections.Collection<MutableMap.MutableEntry<K, V>>): Boolean =
                filterEntries { entry -> !elements.any { entry == it } }
            override fun retainAll(elements: kotlin.collections.Collection<MutableMap.MutableEntry<K, V>>): Boolean =
                filterEntries { entry -> elements.any { entry == it } }
            override fun iterator(): MutableIterator<MutableMap.MutableEntry<K, V>> {
                val iterator = members.values.iterator()
                return object : MutableIterator<MutableMap.MutableEntry<K, V>> {
                    override fun hasNext(): Boolean = iterator.hasNext()
                    override fun next(): MutableMap.MutableEntry<K, V> = iterator.next()
                    override fun remove() = iterator.remove()
                }
            }
        }

    override val keys: MutableSet<K>
        get() = object : AbstractMutableSet<K>() {
            override val size: Int get() = members.size
            override fun add(element: K): Boolean = throw UnsupportedOperationException()
            override fun contains(element: K): Boolean = containsKey(element)
            override fun remove(element: K): Boolean {
                if (!containsKey(element)) return false
                this@SwiftHashableMap.remove(element)
                return true
            }
            override fun clear() = members.clear()
            override fun iterator(): MutableIterator<K> {
                val iterator = members.values.iterator()
                return object : MutableIterator<K> {
                    override fun hasNext(): Boolean = iterator.hasNext()
                    override fun next(): K = iterator.next().key
                    override fun remove() = iterator.remove()
                }
            }
            override fun removeAll(elements: kotlin.collections.Collection<K>): Boolean =
                filterEntries { entry -> !elements.any { swiftEquatableEquals(entry.key, it) } }
            override fun retainAll(elements: kotlin.collections.Collection<K>): Boolean =
                filterEntries { entry -> elements.any { swiftEquatableEquals(entry.key, it) } }
            override fun hashCode(): Int = sumOf { swiftEquatableHash(it) }
        }

    override val values: kotlin.collections.MutableCollection<V>
        get() = object : AbstractMutableCollection<V>() {
            override val size: Int get() = members.size
            override fun add(element: V): Boolean = throw UnsupportedOperationException()
            override fun contains(element: V): Boolean = containsValue(element)
            override fun remove(element: V): Boolean {
                val iterator = members.values.iterator()
                while (iterator.hasNext()) {
                    if (swiftEquatableEquals(iterator.next().value, element)) {
                        iterator.remove()
                        return true
                    }
                }
                return false
            }
            override fun clear() = members.clear()
            override fun iterator(): MutableIterator<V> {
                val iterator = members.values.iterator()
                return object : MutableIterator<V> {
                    override fun hasNext(): Boolean = iterator.hasNext()
                    override fun next(): V = iterator.next().value
                    override fun remove() = iterator.remove()
                }
            }
            override fun removeAll(elements: kotlin.collections.Collection<V>): Boolean =
                filterEntries { entry -> !elements.any { swiftEquatableEquals(entry.value, it) } }
            override fun retainAll(elements: kotlin.collections.Collection<V>): Boolean =
                filterEntries { entry -> elements.any { swiftEquatableEquals(entry.value, it) } }
        }

    private fun filterEntries(retain: (MutableMap.MutableEntry<K, V>) -> Boolean): Boolean {
        var changed = false
        val iterator = members.values.iterator()
        while (iterator.hasNext()) {
            if (!retain(iterator.next())) {
                iterator.remove()
                changed = true
            }
        }
        return changed
    }

    override fun equals(other: Any?): Boolean {
        if (other === this) return true
        if (other !is Map<*, *> || size != other.size) return false
        @Suppress("UNCHECKED_CAST")
        val map = other as Map<K, V>
        return entries.all { map.containsKey(it.key) && swiftEquatableEquals(it.value, map[it.key]) }
    }
    override fun hashCode(): Int = entries.sumOf { it.hashCode() }
}
