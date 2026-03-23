package com.hypheng.telegram.kmp

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge

internal const val STARTUP_DEBUG_HOOK_EXTRA = "startup_debug_hook"
internal const val STARTUP_DEBUG_HOOK_FORCE_FAILURE_VALUE = "force_failure"
internal const val HOME_DEBUG_STATE_EXTRA = "home_debug_state"

/**
 * Debug-only acceptance hook for issue #45.
 *
 * Example:
 * adb shell am start -n com.hypheng.telegram.kmp/.MainActivity \
 *   --es startup_debug_hook force_failure
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        val startupRuntimeHook = resolveStartupRuntimeHook(
            intent = intent,
            isDebuggable = isDebuggableBuild(),
        )
        val chatListDebugState = resolveChatListDebugState(
            intent = intent,
            isDebuggable = isDebuggableBuild(),
        )
        setContent {
            TelegramDemoApp(
                startupRuntimeHook = startupRuntimeHook,
                sessionStore = AndroidDemoSessionStore(applicationContext),
                chatListDebugState = chatListDebugState,
            )
        }
    }
}

internal fun resolveStartupRuntimeHook(
    intent: Intent?,
    isDebuggable: Boolean,
): StartupRuntimeHook = resolveStartupRuntimeHook(
    hookValue = intent?.getStringExtra(STARTUP_DEBUG_HOOK_EXTRA),
    isDebuggable = isDebuggable,
)

internal fun resolveStartupRuntimeHook(
    hookValue: String?,
    isDebuggable: Boolean,
): StartupRuntimeHook {
    if (!isDebuggable) {
        return StartupRuntimeHook.None
    }

    return when (hookValue) {
        STARTUP_DEBUG_HOOK_FORCE_FAILURE_VALUE -> StartupRuntimeHook.ForceFailure
        else -> StartupRuntimeHook.None
    }
}

internal fun resolveChatListDebugState(
    intent: Intent?,
    isDebuggable: Boolean,
): ChatListDebugState {
    if (!isDebuggable) {
        return ChatListDebugState.Default
    }
    return when (intent?.getStringExtra(HOME_DEBUG_STATE_EXTRA)) {
        "loading" -> ChatListDebugState.Loading
        "empty" -> ChatListDebugState.Empty
        "error" -> ChatListDebugState.Error
        else -> ChatListDebugState.Default
    }
}

private fun ComponentActivity.isDebuggableBuild(): Boolean {
    return (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
}
