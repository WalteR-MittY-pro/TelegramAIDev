package com.hypheng.telegram.kmp

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ChatDetailLocalSendTest {
    @Test
    fun queueLocalSendAppendsPendingOutgoingMessage() {
        val initialState = createChatDetailUiState(sampleChatDetailWithMessages()).copy(
            draftMessage = "Local only send",
        )

        val queuedState = queueLocalSend(
            state = initialState,
            localSend = sampleLocalSendMockData(),
            shouldFail = false,
        )

        assertEquals(3, queuedState.messages.size)
        assertEquals("local-1", queuedState.pendingMessageId)
        assertTrue(queuedState.hasPendingSend)
        assertEquals("pending", queuedState.messages.last().deliveryState)
        assertEquals("Local only send", queuedState.messages.last().text)
    }

    @Test
    fun settledSuccessClearsComposerWhenConfigured() {
        val queuedState = queueLocalSend(
            state = createChatDetailUiState(sampleChatDetailWithMessages()).copy(
                draftMessage = "Ship it",
            ),
            localSend = sampleLocalSendMockData(),
            shouldFail = false,
        )

        val settledState = settlePendingLocalSend(
            state = queuedState,
            localSend = sampleLocalSendMockData(),
            failureNotice = "Should not be used",
        )

        assertNull(settledState.pendingMessageId)
        assertEquals("", settledState.draftMessage)
        assertEquals("sent", settledState.messages.last().deliveryState)
        assertNull(settledState.failureNotice)
    }

    @Test
    fun failedSendRemainsRecoverable() {
        val queuedState = queueLocalSend(
            state = createChatDetailUiState(sampleChatDetailWithMessages()).copy(
                draftMessage = "Retry me",
            ),
            localSend = sampleLocalSendMockData(),
            shouldFail = true,
        )

        val failedState = settlePendingLocalSend(
            state = queuedState,
            localSend = sampleLocalSendMockData(),
            failureNotice = "The local demo message could not be sent. Try again.",
        )

        assertNull(failedState.pendingMessageId)
        assertEquals("local-1", failedState.retryMessageId)
        assertEquals("Retry me", failedState.draftMessage)
        assertEquals("failed", failedState.messages.last().deliveryState)
        assertEquals("The local demo message could not be sent. Try again.", failedState.failureNotice)
    }

    @Test
    fun retrySendReusesFailedMessageInsteadOfAppendingDuplicate() {
        val failedState = settlePendingLocalSend(
            state = queueLocalSend(
                state = createChatDetailUiState(sampleChatDetailWithMessages()).copy(
                    draftMessage = "Retry me",
                ),
                localSend = sampleLocalSendMockData(),
                shouldFail = true,
            ),
            localSend = sampleLocalSendMockData(),
            failureNotice = "The local demo message could not be sent. Try again.",
        )

        val retriedState = queueLocalSend(
            state = failedState,
            localSend = sampleLocalSendMockData(),
            shouldFail = false,
        )

        assertEquals(3, retriedState.messages.size)
        assertEquals("local-1", retriedState.pendingMessageId)
        assertEquals("pending", retriedState.messages.last().deliveryState)
    }

    @Test
    fun editingDraftAfterFailureClearsRetryState() {
        val failedState = settlePendingLocalSend(
            state = queueLocalSend(
                state = createChatDetailUiState(sampleChatDetailWithMessages()).copy(
                    draftMessage = "Retry me",
                ),
                localSend = sampleLocalSendMockData(),
                shouldFail = true,
            ),
            localSend = sampleLocalSendMockData(),
            failureNotice = "The local demo message could not be sent. Try again.",
        )

        val editedState = updateChatComposerDraft(failedState, "Try a fresh draft")

        assertNull(editedState.retryMessageId)
        assertNull(editedState.failureNotice)
        assertEquals("Try a fresh draft", editedState.draftMessage)
    }
}

private fun sampleChatDetailWithMessages() = ChatDetailMockData(
    placeholderConversationId = "chat-alex",
    subtitle = "last seen recently",
    typingSubtitle = "typing...",
    dateLabel = "Today",
    messages = listOf(
        SeedMessage(
            id = "msg-1",
            direction = "incoming",
            text = "Hello",
            deliveryState = null,
            timeLabel = "09:21",
            deliveryLabel = null,
        ),
        SeedMessage(
            id = "msg-2",
            direction = "outgoing",
            text = "Hi",
            deliveryState = null,
            timeLabel = "09:24",
            deliveryLabel = "sent-read",
        ),
    ),
    composer = ComposerMockData(placeholder = "Type a message..."),
    localSend = sampleLocalSendMockData(),
)

private fun sampleLocalSendMockData() = LocalSendMockData(
    initialDeliveryState = "pending",
    settledDeliveryState = "sent",
    failureDeliveryState = "failed",
    clearComposerOnSuccess = true,
)
