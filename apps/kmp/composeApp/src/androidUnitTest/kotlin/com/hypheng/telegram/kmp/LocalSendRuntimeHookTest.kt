package com.hypheng.telegram.kmp

import kotlin.test.Test
import kotlin.test.assertEquals

class LocalSendRuntimeHookTest {
    @Test
    fun defaultLaunchDoesNotEnableLocalSendFailureHook() {
        assertEquals(
            LocalSendRuntimeHook.None,
            resolveLocalSendRuntimeHook(intent = null, isDebuggable = true),
        )
    }

    @Test
    fun debugLaunchCanForceNextLocalSendFailure() {
        assertEquals(
            LocalSendRuntimeHook.FailNextSend,
            resolveLocalSendRuntimeHook(
                hookValue = LOCAL_SEND_DEBUG_HOOK_FAIL_NEXT_SEND_VALUE,
                isDebuggable = true,
            ),
        )
    }

    @Test
    fun nonDebuggableBuildIgnoresLocalSendHook() {
        assertEquals(
            LocalSendRuntimeHook.None,
            resolveLocalSendRuntimeHook(
                hookValue = LOCAL_SEND_DEBUG_HOOK_FAIL_NEXT_SEND_VALUE,
                isDebuggable = false,
            ),
        )
    }
}
