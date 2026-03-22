package com.hypheng.telegram.kmp

import androidx.compose.ui.graphics.toArgb
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.serialization.json.Json

class StartupAssetsTest {
    @Test
    fun parsesSharedCopySubset() {
        val copy = Json { ignoreUnknownKeys = true }.decodeFromString<SharedCopy>(
            """
            {
              "bootstrap": {
                "title": "Loading Telegram Demo...",
                "body": "Preparing startup routing.",
                "failureNotice": "Startup failed."
              },
              "login": {
                "brandTitle": "Telegram Demo",
                "headline": "Start with your phone number",
                "body": "Demo login follows in the next slice.",
                "phoneLabel": "Phone number",
                "phoneHint": "+1 415 555 0199",
                "continueLabel": "Continue",
                "footer": "Local-only demo footer.",
                "invalidInputNotice": "Invalid"
              },
              "homeShell": {
                "tabs": {
                  "chats": "Chats",
                  "contacts": "Contacts",
                  "settings": "Settings"
                },
                "placeholderNotice": "Placeholder"
              },
              "chatList": {
                "title": "Telegram",
                "loading": "Loading",
                "emptyTitle": "Empty",
                "emptyBody": "Body",
                "errorTitle": "Error",
                "errorBody": "Body"
              },
              "chatDetail": {
                "titleFallback": "Conversation",
                "composerPlaceholder": "Message",
                "sendLabel": "Send",
                "sendFailureNotice": "Failed"
              }
            }
            """.trimIndent(),
        )

        assertEquals("Telegram Demo", copy.login.brandTitle)
        assertEquals("Continue", copy.login.continueLabel)
    }

    @Test
    fun convertsHexTokenToColor() {
        assertEquals(0xFF2AABEE.toInt(), "#2AABEE".asColor().toArgb())
        assertEquals(0x8017212B.toInt(), "#8017212B".asColor().toArgb())
    }

    @Test
    fun parsedColorsRemainUsableInMaterialCopies() {
        val copied = "#2AABEE".asColor().copy(alpha = 0.5f)

        assertEquals(0x802AABEE.toInt(), copied.toArgb())
    }
}
