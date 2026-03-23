package com.hypheng.telegram.kmp

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class DemoSessionManagerTest {
    @Test
    fun missingSessionFallsBackToLogin() {
        val sessionStore = FakeDemoSessionStore()

        val route = DemoSessionManager.determineInitialRoute(
            sessionStore = sessionStore,
            authenticatedRoute = AppRoute.AuthenticatedPlaceholder.route,
        )

        assertEquals(AppRoute.Login, route)
        assertEquals(0, sessionStore.clearCalls)
    }

    @Test
    fun validPersistedSessionRestoresAuthenticatedPlaceholder() {
        val sessionStore = FakeDemoSessionStore(
            session = PersistedDemoSession(normalizedPhoneNumber = "+14155550199"),
        )

        val route = DemoSessionManager.determineInitialRoute(
            sessionStore = sessionStore,
            authenticatedRoute = AppRoute.AuthenticatedPlaceholder.route,
        )

        assertEquals(AppRoute.AuthenticatedPlaceholder, route)
        assertEquals(0, sessionStore.clearCalls)
    }

    @Test
    fun invalidPersistedSessionClearsAndFallsBackToLogin() {
        val sessionStore = FakeDemoSessionStore(
            session = PersistedDemoSession(normalizedPhoneNumber = "1415"),
        )

        val route = DemoSessionManager.determineInitialRoute(
            sessionStore = sessionStore,
            authenticatedRoute = AppRoute.AuthenticatedPlaceholder.route,
        )

        assertEquals(AppRoute.Login, route)
        assertEquals(1, sessionStore.clearCalls)
        assertNull(sessionStore.readSession())
    }

    @Test
    fun unsupportedAuthenticatedRouteFallsBackToLogin() {
        val sessionStore = FakeDemoSessionStore(
            session = PersistedDemoSession(normalizedPhoneNumber = "+14155550199"),
        )

        val route = DemoSessionManager.determineInitialRoute(
            sessionStore = sessionStore,
            authenticatedRoute = "real-home",
        )

        assertEquals(AppRoute.Login, route)
        assertEquals(1, sessionStore.clearCalls)
    }

    @Test
    fun persistAuthenticatedSessionStoresValidPhoneNumber() {
        val sessionStore = FakeDemoSessionStore()

        DemoSessionManager.persistAuthenticatedSession(
            sessionStore = sessionStore,
            normalizedPhoneNumber = "+14155550199",
        )

        assertEquals(
            PersistedDemoSession(normalizedPhoneNumber = "+14155550199"),
            sessionStore.readSession(),
        )
    }

    @Test
    fun invalidPhoneNumberIsNotPersisted() {
        val sessionStore = FakeDemoSessionStore()

        DemoSessionManager.persistAuthenticatedSession(
            sessionStore = sessionStore,
            normalizedPhoneNumber = "1415",
        )

        assertNull(sessionStore.readSession())
    }
}

private class FakeDemoSessionStore(
    session: PersistedDemoSession? = null,
) : DemoSessionStore {
    private var storedSession = session

    var clearCalls: Int = 0
        private set

    override fun readSession(): PersistedDemoSession? = storedSession

    override fun saveSession(session: PersistedDemoSession) {
        storedSession = session
    }

    override fun clearSession() {
        clearCalls += 1
        storedSession = null
    }
}
