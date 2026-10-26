// Copyright 2026 Vindhya Data Science
// SPDX-License-Identifier: MPL-2.0
package skip.lib

import java.io.ByteArrayOutputStream
import java.io.PrintStream
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.shadows.ShadowLog

@RunWith(RobolectricTestRunner::class)
class TaskFailureLoggingTests {
    private fun <T> captureStderr(operation: () -> T): kotlin.Pair<T, String> {
        val original = System.err
        val bytes = ByteArrayOutputStream()
        val capture = PrintStream(bytes, true, "UTF-8")
        try {
            System.setErr(capture)
            val result = operation()
            return kotlin.Pair(result, bytes.toString("UTF-8"))
        } finally {
            System.setErr(original)
            capture.close()
        }
    }

    private fun assertOriginalCause(expected: Throwable, actual: Throwable) {
        // Coroutine stack-trace recovery may copy an awaited exception and retain its cause.
        val seen = java.util.Collections.newSetFromMap(java.util.IdentityHashMap<Throwable, Boolean>())
        var current: Throwable? = actual
        while (current != null && seen.add(current)) {
            if (current === expected) return
            current = current.cause
        }
        fail("Awaited failure lost its original cause: $actual")
    }

    @Test fun fireAndForgetPlatformThrowableIsLoggedOnJvm() {
        withMessagePolicy("true") {
            val failure = AssertionError("fire-forget-jvm")
            val captured = captureStderr {
                runBlocking {
                    // join waits for completion without observing the Deferred's exception.
                    Task<Unit> { throw failure }.deferred.join()
                }
            }
            assertTrue(captured.second.contains("SkipLib.Task"))
            assertTrue(captured.second.contains("java.lang.AssertionError: fire-forget-jvm"))
            assertTrue(captured.second.contains("TaskFailureLoggingTests"))
        }
    }

    @Test fun androidPlatformThrowableUsesErrorLogWithOriginalCause() {
        withMessagePolicy("true") {
            val failure = IllegalStateException("fire-forget-android")
            val originalVm = System.getProperty("java.vm.name")
            ShadowLog.clear()
            try {
                // ART and Dalvik both identify their VM as Dalvik. This is a JVM-local fixture.
                System.setProperty("java.vm.name", "Dalvik")
                runBlocking { Task<Unit> { throw failure }.deferred.join() }
                val entries = ShadowLog.getLogsForTag("SkipLib.Task")
                assertEquals(1, entries.size)
                assertEquals(android.util.Log.ERROR, entries[0].type)
                assertSame(failure, entries[0].throwable)
            } finally {
                if (originalVm == null) System.clearProperty("java.vm.name")
                else System.setProperty("java.vm.name", originalVm)
            }
        }
    }

    @Test fun awaitingPlatformFailurePreservesTheOriginalCause() {
        withMessagePolicy("true") {
            val failure = IllegalArgumentException("awaited-platform")
            val captured = captureStderr {
                runBlocking {
                    val task = Task<Unit> { throw failure }
                    try {
                        task.value()
                        fail("Expected platform failure")
                    } catch (caught: IllegalArgumentException) {
                        assertOriginalCause(failure, caught)
                    }
                }
            }
            assertTrue(captured.second.contains("awaited-platform"))
        }
    }

    @Test fun swiftErrorsCancellationAndSuccessfulTasksKeepTheirSemantics() {
        val failure = ErrorException("expected-swift-error")
        val captured = captureStderr {
            runBlocking {
                val swiftFailure = Task<Unit> { throw failure }
                try {
                    swiftFailure.value()
                    fail("Expected Swift error")
                } catch (caught: ErrorException) {
                    assertOriginalCause(failure, caught)
                }
                val cancelled = Task<Unit> { throw CancellationException("expected-cancellation") }
                try {
                    cancelled.value()
                    fail("Expected cancellation")
                } catch (caught: CancellationError) {
                    assertTrue(cancelled.isCancelled)
                }
                assertEquals(42, Task<Int> { 42 }.value())
            }
        }
        assertFalse(captured.second.contains("SkipLib.Task"))
    }

    @Test fun brokenLogSinkDoesNotReplaceTheAwaitedFailure() {
        val failure = IllegalArgumentException("original-platform-failure")
        val original = System.err
        val broken = object : PrintStream(ByteArrayOutputStream()) {
            override fun println(message: String?) { throw IllegalStateException("broken-sink") }
        }
        try {
            System.setErr(broken)
            runBlocking {
                try {
                    Task<Unit> { throw failure }.value()
                    fail("Expected original failure")
                } catch (caught: IllegalArgumentException) {
                    assertOriginalCause(failure, caught)
                }
            }
        } finally {
            System.setErr(original)
            broken.close()
        }
    }
    private val messagePolicyProperty = "skip.lib.taskFailureLogging.includeMessages"

    private fun <T> withMessagePolicy(value: String?, operation: () -> T): T {
        val previous = System.getProperty(messagePolicyProperty)
        try {
            if (value == null) System.clearProperty(messagePolicyProperty)
            else System.setProperty(messagePolicyProperty, value)
            return operation()
        } finally {
            if (previous == null) System.clearProperty(messagePolicyProperty)
            else System.setProperty(messagePolicyProperty, previous)
        }
    }

    private fun sensitiveFailure(): IllegalStateException {
        val root = IllegalStateException("PRIVATE_5rai_root_filename", IllegalArgumentException("PRIVATE_5rai_cause_gene_list"))
        root.addSuppressed(AssertionError("PRIVATE_5rai_suppressed_identifier"))
        root.stackTrace = kotlin.arrayOf(StackTraceElement("fixture.TaskFailure", "run", "TaskFailure.kt", 42))
        return root
    }

    @Test fun defaultAndReleaseJvmLogsOmitEveryMessageAndKeepFrames() {
        for (policy in listOf<String?>(null, "false", "unknown")) {
            val failure = sensitiveFailure()
            val captured = withMessagePolicy(policy) {
                captureStderr { runBlocking { Task<Unit> { throw failure }.deferred.join() } }
            }
            assertTrue(captured.second.contains("SkipLib.Task"))
            assertTrue(captured.second.contains("java.lang.IllegalStateException"))
            assertTrue(captured.second.contains("fixture.TaskFailure.run(TaskFailure.kt:42)"))
            assertFalse(captured.second.contains("PRIVATE_5rai_"))
        }
    }

    @Test fun releaseAndroidLogContainsNoThrowableOrMessages() {
        val originalVm = System.getProperty("java.vm.name")
        val failure = sensitiveFailure()
        ShadowLog.clear()
        try {
            System.setProperty("java.vm.name", "Dalvik")
            withMessagePolicy("false") { runBlocking { Task<Unit> { throw failure }.deferred.join() } }
            val entries = ShadowLog.getLogsForTag("SkipLib.Task")
            assertEquals(1, entries.size)
            assertEquals(android.util.Log.ERROR, entries[0].type)
            assertNull(entries[0].throwable)
            assertTrue(entries[0].msg.contains("java.lang.IllegalStateException"))
            assertTrue(entries[0].msg.contains("fixture.TaskFailure.run(TaskFailure.kt:42)"))
            assertFalse(entries[0].msg.contains("PRIVATE_5rai_"))
        } finally {
            if (originalVm == null) System.clearProperty("java.vm.name")
            else System.setProperty("java.vm.name", originalVm)
        }
    }

    @Test fun explicitDebugPolicyKeepsMessagesAndReleaseAwaitKeepsOriginalFailure() {
        val failure = sensitiveFailure()
        val debug = withMessagePolicy("true") {
            captureStderr { runBlocking { Task<Unit> { throw failure }.deferred.join() } }
        }
        assertTrue(debug.second.contains("PRIVATE_5rai_root_filename"))
        assertTrue(debug.second.contains("PRIVATE_5rai_cause_gene_list"))
        assertTrue(debug.second.contains("PRIVATE_5rai_suppressed_identifier"))
        assertTrue(debug.second.contains("fixture.TaskFailure.run(TaskFailure.kt:42)"))
        val release = withMessagePolicy("false") {
            captureStderr {
                runBlocking {
                    try {
                        Task<Unit> { throw failure }.value()
                        fail("Expected the original platform failure")
                    } catch (caught: IllegalStateException) {
                        assertOriginalCause(failure, caught)
                    }
                }
            }
        }
        assertFalse(release.second.contains("PRIVATE_5rai_"))
    }

}
