package com.hypheng.telegram.kmp

internal data class PersistedDemoSession(
    val normalizedPhoneNumber: String,
)

internal interface DemoSessionStore {
    fun readSession(): PersistedDemoSession?

    fun saveSession(session: PersistedDemoSession)

    fun clearSession()
}

internal object NoOpDemoSessionStore : DemoSessionStore {
    override fun readSession(): PersistedDemoSession? = null

    override fun saveSession(session: PersistedDemoSession) = Unit

    override fun clearSession() = Unit
}

internal object DemoSessionManager {
    fun determineInitialRoute(
        sessionStore: DemoSessionStore,
        authenticatedRoute: String,
    ): AppRoute {
        if (
            authenticatedRoute != AppRoute.AuthenticatedPlaceholder.route &&
            authenticatedRoute != AppRoute.Home.route
        ) {
            clearSessionQuietly(sessionStore)
            return AppRoute.Login
        }

        val restoredSession = runCatching { sessionStore.readSession() }
            .getOrElse {
                clearSessionQuietly(sessionStore)
                return AppRoute.Login
            }
            ?: return AppRoute.Login

        if (!DemoLoginFlow.isValidPhoneNumber(restoredSession.normalizedPhoneNumber)) {
            clearSessionQuietly(sessionStore)
            return AppRoute.Login
        }

        return if (authenticatedRoute == AppRoute.Home.route) {
            AppRoute.Home
        } else {
            AppRoute.AuthenticatedPlaceholder
        }
    }

    fun persistAuthenticatedSession(
        sessionStore: DemoSessionStore,
        normalizedPhoneNumber: String,
    ) {
        if (!DemoLoginFlow.isValidPhoneNumber(normalizedPhoneNumber)) {
            return
        }

        runCatching {
            sessionStore.saveSession(
                PersistedDemoSession(
                    normalizedPhoneNumber = normalizedPhoneNumber,
                ),
            )
        }
    }

    private fun clearSessionQuietly(sessionStore: DemoSessionStore) {
        runCatching { sessionStore.clearSession() }
    }
}
