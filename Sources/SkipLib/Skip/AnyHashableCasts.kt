// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: MPL-2.0
package skip.lib

import java.math.BigDecimal
import java.math.BigInteger

/** Numeric payload conversion for a statically known Swift AnyHashable cast.
 * The caller still performs its original as?/as!/is against the returned value.
 * This is not a conversion of arbitrary Any and never parses a user String.
 */
fun anyHashableCastValue(wrapper: AnyHashable?, targetSwiftType: String): Any? {
    val value = wrapper?.base ?: return null
    return when (targetSwiftType) {
        "Int", "Int32" -> castSigned(value, Int.MIN_VALUE.toLong(), Int.MAX_VALUE.toLong())?.toInt()
        "Int8" -> castSigned(value, Byte.MIN_VALUE.toLong(), Byte.MAX_VALUE.toLong())?.toByte()
        "Int16" -> castSigned(value, Short.MIN_VALUE.toLong(), Short.MAX_VALUE.toLong())?.toShort()
        "Int64" -> castSigned(value, Long.MIN_VALUE, Long.MAX_VALUE)
        "UInt", "UInt32" -> castUnsigned(value, 32)?.toLong()?.toUInt()
        "UInt8" -> castUnsigned(value, 8)?.toLong()?.toUByte()
        "UInt16" -> castUnsigned(value, 16)?.toLong()?.toUShort()
        "UInt64" -> castUnsigned(value, 64)?.toLong()?.toULong()
        "Double" -> castDouble(value)
        "Float" -> castFloat(value)
        "Bool" -> when (castInteger(value)) {
            BigInteger.ZERO -> false
            BigInteger.ONE -> true
            else -> null
        }
        else -> null
    }
}

private fun castUnsignedInteger(value: ULong): BigInteger {
    // Preserve all 64 bits without routing an unsigned value through Double or
    // decimal text. The high half fits a signed Long before shifting it back.
    return BigInteger.valueOf((value shr 1).toLong()).shiftLeft(1)
        .add(BigInteger.valueOf((value and 1uL).toLong()))
}

private fun castInteger(value: Any): BigInteger? = when (value) {
    is Boolean -> if (value) BigInteger.ONE else BigInteger.ZERO
    is Byte -> BigInteger.valueOf(value.toLong())
    is Short -> BigInteger.valueOf(value.toLong())
    is Int -> BigInteger.valueOf(value.toLong())
    is Long -> BigInteger.valueOf(value)
    is UByte -> BigInteger.valueOf(value.toLong())
    is UShort -> BigInteger.valueOf(value.toLong())
    is UInt -> BigInteger.valueOf(value.toLong())
    is ULong -> castUnsignedInteger(value)
    is Double -> if (value.isFinite()) try { BigDecimal(value).toBigIntegerExact() } catch (_: ArithmeticException) { null } else null
    is Float -> if (value.isFinite()) try { BigDecimal(value.toDouble()).toBigIntegerExact() } catch (_: ArithmeticException) { null } else null
    else -> null
}

private fun castSigned(value: Any, minimum: Long, maximum: Long): Long? {
    // Native AnyHashable's numeric bridge validates floating-to-signed casts by
    // a round trip, including its measured rounded Int64 upper endpoint: 2^63
    // casts to Int64.max, while an integral Int64.max cannot cast to Double.
    // Narrow bounds remain exact because they are checked before the round trip.
    if (value is Double) {
        if (!value.isFinite()) return null
        val converted = value.toLong()
        return if (converted >= minimum && converted <= maximum && converted.toDouble() == value) converted else null
    }
    if (value is Float) {
        if (!value.isFinite()) return null
        val converted = value.toLong()
        return if (converted >= minimum && converted <= maximum && converted.toFloat() == value) converted else null
    }
    val integer = castInteger(value) ?: return null
    if (integer < BigInteger.valueOf(minimum) || integer > BigInteger.valueOf(maximum)) return null
    return integer.toLong()
}

private fun castUnsigned(value: Any, bits: Int): BigInteger? {
    val integer = castInteger(value) ?: return null
    val maximum = BigInteger.ONE.shiftLeft(bits).subtract(BigInteger.ONE)
    return if (integer.signum() >= 0 && integer <= maximum) integer else null
}

private fun castDouble(value: Any): Double? {
    if (value is Double) return value // Same precision retains signed zero/NaN payload.
    if (value is Float) return if (value.isNaN()) Double.NaN else value.toDouble()
    val integer = castInteger(value) ?: return null
    val converted = integer.toDouble()
    return if (converted.isFinite() && BigDecimal(converted).compareTo(BigDecimal(integer)) == 0) converted else null
}

private fun castFloat(value: Any): Float? {
    if (value is Float) return value // Same precision retains signed zero/NaN payload.
    if (value is Double) {
        if (value.isNaN()) return Float.NaN // Native cross-precision NaN is canonical.
        val converted = value.toFloat()
        return if (converted.toDouble() == value) converted else null
    }
    val integer = castInteger(value) ?: return null
    val converted = integer.toFloat()
    return if (converted.isFinite() && BigDecimal(converted.toDouble()).compareTo(BigDecimal(integer)) == 0) converted else null
}
