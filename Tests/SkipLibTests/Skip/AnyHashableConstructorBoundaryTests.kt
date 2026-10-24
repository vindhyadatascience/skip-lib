// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: MPL-2.0
package skip.lib

import org.junit.Assert.*
import org.junit.Test

/** Generic Kotlin T may be nullable even for a valid nonnil Swift payload. */
class AnyHashableConstructorBoundaryTests {
    private fun <T> erase(value: T): AnyHashable = AnyHashable(value)

    @Test fun nonnullGenericValuesKeepTheirOriginalBase() {
        assertEquals("retained", erase("retained").base)
        assertEquals(7, erase(7).base)
        val negativeZero = erase(-0.0).base as Double
        assertEquals(java.lang.Double.doubleToRawLongBits(-0.0), java.lang.Double.doubleToRawLongBits(negativeZero))
        val alreadyWrapped = AnyHashable("retained")
        assertEquals("retained", erase(alreadyWrapped).base)
    }

    @Test fun unknownGenericNilIsRefusedWhileTypedOptionalNilStillWorks() {
        val error = assertThrows(IllegalArgumentException::class.java) { erase<String?>(null) }
        assertTrue(error.message.orEmpty().contains("Optional.none"))
        assertTrue(error.message.orEmpty().contains("anyHashableOptional"))
        val absentInt = anyHashableOptional(null, type = "Int")
        val absentIntAgain = anyHashableOptional(null, type = "Int")
        val absentString = anyHashableOptional(null, type = "String")
        assertEquals(absentInt, absentIntAgain)
        assertNotEquals(absentInt, absentString)
        assertEquals(AnyHashable(7), anyHashableOptional(7, type = "Int"))
    }
}
