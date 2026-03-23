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
    fun validPersistedSessionRestoresHomeWhenHomeRouteRequested() {
        val sessionStore = FakeDemoSessionStore(
            session = PersistedDemoSession(normalizedPhoneNumber = "+14155550199"),
        )

        val route = DemoSessionManager.determineInitialRoute(
            sessionStore = sessionStore,
            authenticatedRoute = AppRoute.Home.route,
        )

        assertEquals(AppRoute.Home, route)
        assertEquals(0, sessionStore.clearCalls)
    }

    @Test
    fun invalidPersistedSessionClearsAndFallsBackToLogin() {
        val sessionStore = FakeDemoSessionStore(
            session = PersistedDemoSession(normalizedPhoneNumber = "1415"),
        )

        val route = DemoSessionManager.determineInitialRoute(
            sessionStore = sessionStore,
            authenticatedRoute = AppRoute.Home.route,
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

    @Test
    fun authenticatedRouteForAssetsPrefersHomeWhenSliceFourTabsAreAvailable() {
        val route = authenticatedRouteForAssets(
            StartupAssets(
                tokens = sampleDesignTokens(),
                sharedCopy = sampleSharedCopy(),
                sharedMockData = sampleSharedMockData(),
                resourceManifest = ResourceManifest(
                    sourceRoot = "shared/design/telegram-commercial-mvp",
                    resources = emptyList(),
                    copyRule = CopyRule(
                        copyIntoFrameworkApp = true,
                        preserveFilenames = true,
                        allowDirectRuntimeReadFromSharedSource = false,
                    ),
                ),
                appMarkSvg = byteArrayOf(0x1),
            ),
        )

        assertEquals(AppRoute.Home, route)
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

private fun sampleDesignTokens() = DesignTokens(
    meta = MetaTokens(name = "telegram-commercial-mvp", version = "1"),
    color = ColorTokens(
        surface = SurfaceColors("#FFFFFF", "#FFFFFF", "#F2F4F7", "#FFFFFF"),
        text = TextColors("#101828", "#475467", "#667085", "#FFFFFF"),
        accent = AccentColors("#4C8DFF", "#2563EB", "#DCE8FF"),
        status = StatusColors("#12B76A", "#F79009", "#F04438"),
        border = BorderColors("#D0D5DD", "#98A2B3"),
        badge = BadgeColors("#4C8DFF", "#FFFFFF"),
        avatar = AvatarColors("#4C8DFF", "#12B76A", "#F79009", "#8E6CEF"),
    ),
    typography = TypographyTokens(
        family = TypographyFamilies(primary = "Sans"),
        size = TypographySizes(caption = 12, body = 14, bodyStrong = 16, title = 18, headline = 28),
        lineHeight = TypographyLineHeights(caption = 16, body = 20, bodyStrong = 22, title = 24, headline = 34),
        weight = TypographyWeights(regular = 400, medium = 500, semibold = 600, bold = 700),
    ),
    spacing = SpacingTokens(xs = 4, sm = 8, md = 12, lg = 16, xl = 20, xxl = 24),
    radius = RadiusTokens(card = 18, field = 16, pill = 999, bubble = 18),
    borderWidth = BorderWidthTokens(hairline = 1, strong = 2),
    elevation = ElevationTokens(none = 0, card = 2, overlay = 6),
    iconSize = IconSizeTokens(sm = 16, md = 20, lg = 24, xl = 28),
    avatarSize = AvatarSizeTokens(list = 52, detail = 72),
)

private fun sampleSharedCopy() = SharedCopy(
    bootstrap = BootstrapCopy("Telegram Demo", "Loading", "Failed"),
    login = LoginCopy(
        brandTitle = "Telegram Demo",
        headline = "Start with your phone number",
        body = "Body",
        phoneLabel = "Phone number",
        phoneHint = "+14155550199",
        continueLabel = "Continue",
        footer = "Footer",
        invalidInputNotice = "Invalid",
    ),
    homeShell = HomeShellCopy(
        tabs = HomeShellTabsCopy(
            chats = "Chats",
            contacts = "Contacts",
            settings = "Settings",
        ),
        placeholderNotice = "Placeholder",
    ),
    chatList = ChatListCopy(
        title = "Telegram",
        loading = "Loading conversations...",
        emptyTitle = "No chats yet",
        emptyBody = "Empty",
        errorTitle = "Couldn't load chats",
        errorBody = "Error",
    ),
    chatDetail = ChatDetailCopy(
        titleFallback = "Alex Mason",
        composerPlaceholder = "Message",
        sendLabel = "Send",
        sendFailureNotice = "Failed",
    ),
)

private fun sampleSharedMockData() = SharedMockData(
    startup = StartupMockData(defaultAuthenticatedDestination = AppRoute.AuthenticatedPlaceholder.route),
    homeShell = HomeShellMockData(
        defaultTab = "chats",
        tabs = listOf(
            HomeShellTabMock(id = "chats", labelKey = "homeShell.tabs.chats", iconId = "chat-bubble", implementedInSlice = 4),
            HomeShellTabMock(id = "contacts", labelKey = "homeShell.tabs.contacts", iconId = "contacts", implementedInSlice = 4, placeholderDestination = true),
            HomeShellTabMock(id = "settings", labelKey = "homeShell.tabs.settings", iconId = "settings", implementedInSlice = 4, placeholderDestination = true),
        ),
    ),
    chatList = ChatListMockData(
        conversations = listOf(
            ConversationMockData(
                id = "chat-alex",
                title = "Alex Mason",
                snippet = "Snippet",
                timestamp = "09:41",
                unreadCount = 2,
                pinned = true,
                muted = false,
                avatarResource = "avatar-placeholder.svg",
                avatarTint = "blue",
            ),
        ),
    ),
    chatDetail = ChatDetailMockData(
        placeholderConversationId = "chat-alex",
        messages = emptyList(),
        localSend = LocalSendMockData(
            initialDeliveryState = "pending",
            settledDeliveryState = "sent",
            failureDeliveryState = "failed",
            clearComposerOnSuccess = true,
        ),
    ),
)
