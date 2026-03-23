package com.hypheng.telegram.kmp

import android.content.Context

private const val DEMO_SESSION_PREFS_NAME = "telegram_demo_session"
private const val DEMO_SESSION_PHONE_KEY = "normalized_phone_number"

internal class AndroidDemoSessionStore(
    context: Context,
) : DemoSessionStore {
    private val sharedPreferences = context.applicationContext.getSharedPreferences(
        DEMO_SESSION_PREFS_NAME,
        Context.MODE_PRIVATE,
    )

    override fun readSession(): PersistedDemoSession? {
        val normalizedPhoneNumber = sharedPreferences.getString(DEMO_SESSION_PHONE_KEY, null)
            ?: return null

        return PersistedDemoSession(
            normalizedPhoneNumber = normalizedPhoneNumber,
        )
    }

    override fun saveSession(session: PersistedDemoSession) {
        check(
            sharedPreferences
                .edit()
                .putString(DEMO_SESSION_PHONE_KEY, session.normalizedPhoneNumber)
                .commit(),
        ) {
            "Failed to persist the demo session."
        }
    }

    override fun clearSession() {
        check(
            sharedPreferences
                .edit()
                .remove(DEMO_SESSION_PHONE_KEY)
                .commit(),
        ) {
            "Failed to clear the demo session."
        }
    }
}
