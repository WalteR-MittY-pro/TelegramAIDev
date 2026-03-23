package com.hypheng.telegram.kmp

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ChatDetailRouteTest {
    @Test
    fun resolvesRequestedConversationWhenPresent() {
        val conversation = resolveChatDetailConversation(
            chatList = sampleChatListMockData(),
            chatDetail = sampleChatDetailMockData(),
            requestedConversationId = "chat-design",
        )

        assertEquals("chat-design", conversation?.id)
        assertEquals("Design Sync", conversation?.title)
    }

    @Test
    fun fallsBackToPlaceholderConversationWhenRequestMissing() {
        val conversation = resolveChatDetailConversation(
            chatList = sampleChatListMockData(),
            chatDetail = sampleChatDetailMockData(),
            requestedConversationId = "unknown-chat",
        )

        assertEquals("chat-alex", conversation?.id)
    }

    @Test
    fun outgoingMessagesReportDisplayDeliveryLabel() {
        val message = SeedMessage(
            id = "msg-2",
            direction = "outgoing",
            text = "Looks good",
            deliveryLabel = "sent-read",
            timeLabel = "09:24",
        )

        assertTrue(message.isOutgoing())
        assertEquals("sent read", message.displayDeliveryLabel())
    }

    @Test
    fun incomingMessagesRemainIncomingWithoutDeliveryLabel() {
        val message = SeedMessage(
            id = "msg-1",
            direction = "incoming",
            text = "Hello",
            deliveryLabel = null,
            timeLabel = "09:21",
        )

        assertFalse(message.isOutgoing())
        assertEquals(null, message.displayDeliveryLabel())
    }
}

private fun sampleChatListMockData() = ChatListMockData(
    conversations = listOf(
        ConversationMockData(
            id = "chat-alex",
            title = "Alex Mason",
            snippet = "Startup scope",
            timestamp = "09:41",
            unreadCount = 2,
            pinned = true,
            muted = false,
            avatarResource = "avatar-placeholder.svg",
            avatarTint = "blue",
        ),
        ConversationMockData(
            id = "chat-design",
            title = "Design Sync",
            snippet = "Shared assets",
            timestamp = "Yesterday",
            unreadCount = 0,
            pinned = false,
            muted = true,
            avatarResource = "avatar-placeholder.svg",
            avatarTint = "purple",
        ),
    ),
)

private fun sampleChatDetailMockData() = ChatDetailMockData(
    placeholderConversationId = "chat-alex",
    subtitle = "last seen recently",
    typingSubtitle = "typing...",
    dateLabel = "Today",
    messages = emptyList(),
    composer = ComposerMockData(placeholder = "Type a message..."),
    localSend = LocalSendMockData(
        initialDeliveryState = "pending",
        settledDeliveryState = "sent",
        failureDeliveryState = "failed",
        clearComposerOnSuccess = true,
    ),
)
