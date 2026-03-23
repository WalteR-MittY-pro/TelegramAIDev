package com.hypheng.telegram.kmp

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay

internal enum class LocalSendRuntimeHook {
    None,
    FailNextSend,
}

internal enum class LocalSendOutcome {
    Success,
    Failure,
}

internal data class ChatDetailUiState(
    val messages: List<SeedMessage>,
    val draftMessage: String = "",
    val pendingMessageId: String? = null,
    private val pendingOutcome: LocalSendOutcome? = null,
    val retryMessageId: String? = null,
    val failureNotice: String? = null,
    val nextLocalMessageOrdinal: Int = 1,
) {
    val hasPendingSend: Boolean = pendingMessageId != null

    internal fun shouldSettleAsFailure(): Boolean = pendingOutcome == LocalSendOutcome.Failure
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun ChatDetailRoute(
    assets: StartupAssets,
    conversationId: String?,
    localSendRuntimeHook: LocalSendRuntimeHook = LocalSendRuntimeHook.None,
    onBack: () -> Unit,
) {
    val conversation = resolveChatDetailConversation(
        chatList = assets.sharedMockData.chatList,
        chatDetail = assets.sharedMockData.chatDetail,
        requestedConversationId = conversationId,
    )
    val chatDetail = assets.sharedMockData.chatDetail
    val chatDetailCopy = assets.sharedCopy.chatDetail
    var uiState by remember(conversation?.id) { mutableStateOf(createChatDetailUiState(chatDetail)) }
    var shouldFailNextSend by remember(conversation?.id, localSendRuntimeHook) {
        mutableStateOf(localSendRuntimeHook == LocalSendRuntimeHook.FailNextSend)
    }

    LaunchedEffect(uiState.pendingMessageId, uiState.shouldSettleAsFailure()) {
        if (uiState.pendingMessageId == null) {
            return@LaunchedEffect
        }
        delay(700)
        uiState = settlePendingLocalSend(
            state = uiState,
            localSend = chatDetail.localSend,
            failureNotice = chatDetailCopy.sendFailureNotice,
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = conversation?.title ?: chatDetailCopy.titleFallback,
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                        )
                        chatDetail.subtitle?.let { subtitle ->
                            Text(
                                text = subtitle,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                },
                navigationIcon = {
                    TextButton(onClick = onBack) {
                        Text(text = "Back")
                    }
                },
            )
        },
        bottomBar = {
            ChatDetailComposer(
                assets = assets,
                placeholder = chatDetail.composer?.placeholder ?: chatDetailCopy.composerPlaceholder,
                sendLabel = chatDetailCopy.sendLabel,
                draftMessage = uiState.draftMessage,
                failureNotice = uiState.failureNotice,
                isSending = uiState.hasPendingSend,
                onDraftChanged = { updatedDraft ->
                    uiState = updateChatComposerDraft(uiState, updatedDraft)
                },
                onSend = {
                    if (canSubmitLocalMessage(uiState)) {
                        val failThisSend = shouldFailNextSend
                        uiState = queueLocalSend(
                            state = uiState,
                            localSend = chatDetail.localSend,
                            shouldFail = failThisSend,
                        )
                        if (failThisSend) {
                            shouldFailNextSend = false
                        }
                    }
                },
            )
        },
        containerColor = MaterialTheme.colorScheme.surface,
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(
                horizontal = assets.tokens.spacing.lg.dp,
                vertical = assets.tokens.spacing.lg.dp,
            ),
            verticalArrangement = Arrangement.spacedBy(assets.tokens.spacing.md.dp),
        ) {
            chatDetail.dateLabel?.let { dateLabel ->
                item {
                    ChatDateSeparator(
                        label = dateLabel,
                        assets = assets,
                    )
                }
            }
            items(
                items = uiState.messages,
                key = { it.id },
            ) { message ->
                SeedMessageBubble(
                    message = message,
                    assets = assets,
                    failureDeliveryState = chatDetail.localSend.failureDeliveryState,
                )
            }
        }
    }
}

@Composable
private fun ChatDateSeparator(
    label: String,
    assets: StartupAssets,
) {
    Box(
        modifier = Modifier.fillMaxWidth(),
        contentAlignment = Alignment.Center,
    ) {
        Surface(
            color = MaterialTheme.colorScheme.surfaceVariant,
            shape = RoundedCornerShape(assets.tokens.radius.pill.dp),
        ) {
            Text(
                text = label,
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
                style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Medium),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun SeedMessageBubble(
    message: SeedMessage,
    assets: StartupAssets,
    failureDeliveryState: String,
) {
    val isOutgoing = message.isOutgoing()
    val bubbleColor = if (isOutgoing) {
        assets.tokens.color.accent.brandSoft.asColor()
    } else {
        MaterialTheme.colorScheme.surfaceVariant
    }
    val bubbleShape = if (isOutgoing) {
        RoundedCornerShape(
            topStart = assets.tokens.radius.bubble.dp,
            topEnd = assets.tokens.radius.field.dp,
            bottomStart = assets.tokens.radius.bubble.dp,
            bottomEnd = assets.tokens.radius.bubble.dp,
        )
    } else {
        RoundedCornerShape(
            topStart = assets.tokens.radius.field.dp,
            topEnd = assets.tokens.radius.bubble.dp,
            bottomStart = assets.tokens.radius.bubble.dp,
            bottomEnd = assets.tokens.radius.bubble.dp,
        )
    }

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isOutgoing) Arrangement.End else Arrangement.Start,
    ) {
        Surface(
            modifier = Modifier.fillMaxWidth(0.82f),
            color = bubbleColor,
            shape = bubbleShape,
        ) {
            Column(
                modifier = Modifier.padding(
                    horizontal = assets.tokens.spacing.lg.dp,
                    vertical = assets.tokens.spacing.md.dp,
                ),
                horizontalAlignment = if (isOutgoing) Alignment.End else Alignment.Start,
            ) {
                Text(
                    text = message.text,
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface,
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    message.timeLabel?.let { timeLabel ->
                        Text(
                            text = timeLabel,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    message.displayDeliveryLabel()?.let { deliveryLabel ->
                        Text(
                            text = deliveryLabel,
                            style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Medium),
                            color = if (message.deliveryState == failureDeliveryState) {
                                MaterialTheme.colorScheme.error
                            } else {
                                MaterialTheme.colorScheme.onSurfaceVariant
                            },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ChatDetailComposer(
    assets: StartupAssets,
    placeholder: String,
    sendLabel: String,
    draftMessage: String,
    failureNotice: String?,
    isSending: Boolean,
    onDraftChanged: (String) -> Unit,
    onSend: () -> Unit,
) {
    Surface(
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 2.dp,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = assets.tokens.spacing.lg.dp, vertical = assets.tokens.spacing.md.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(assets.tokens.spacing.md.dp),
        ) {
            OutlinedTextField(
                value = draftMessage,
                onValueChange = onDraftChanged,
                modifier = Modifier.weight(1f),
                enabled = !isSending,
                placeholder = { Text(placeholder) },
                supportingText = failureNotice?.let { notice ->
                    { Text(text = notice, color = MaterialTheme.colorScheme.error) }
                },
                singleLine = true,
            )
            Button(
                onClick = onSend,
                enabled = draftMessage.trim().isNotEmpty() && !isSending,
            ) {
                Text(sendLabel)
            }
        }
    }
}

internal fun resolveChatDetailConversation(
    chatList: ChatListMockData,
    chatDetail: ChatDetailMockData,
    requestedConversationId: String?,
): ConversationMockData? {
    val requestedConversation = requestedConversationId?.let { conversationId ->
        chatList.conversations.firstOrNull { it.id == conversationId }
    }
    if (requestedConversation != null) {
        return requestedConversation
    }

    return chatList.conversations.firstOrNull { it.id == chatDetail.placeholderConversationId }
        ?: chatList.conversations.firstOrNull()
}

internal fun SeedMessage.isOutgoing(): Boolean = direction == "outgoing"

internal fun SeedMessage.displayDeliveryLabel(): String? = (
    deliveryLabel
        ?: deliveryState
    )?.replace("-", " ")

internal fun createChatDetailUiState(chatDetail: ChatDetailMockData): ChatDetailUiState = ChatDetailUiState(
    messages = chatDetail.messages,
)

internal fun updateChatComposerDraft(
    state: ChatDetailUiState,
    updatedDraft: String,
): ChatDetailUiState {
    if (state.hasPendingSend) {
        return state
    }
    if (updatedDraft == state.draftMessage) {
        return state
    }
    return state.copy(
        draftMessage = updatedDraft,
        retryMessageId = null,
        failureNotice = null,
    )
}

internal fun canSubmitLocalMessage(state: ChatDetailUiState): Boolean {
    return !state.hasPendingSend && state.draftMessage.trim().isNotEmpty()
}

internal fun queueLocalSend(
    state: ChatDetailUiState,
    localSend: LocalSendMockData,
    shouldFail: Boolean,
): ChatDetailUiState {
    if (!canSubmitLocalMessage(state)) {
        return state
    }

    val messageId = state.retryMessageId ?: "local-${state.nextLocalMessageOrdinal}"
    val message = SeedMessage(
        id = messageId,
        direction = "outgoing",
        text = state.draftMessage.trim(),
        deliveryState = localSend.initialDeliveryState,
        timeLabel = null,
        deliveryLabel = null,
    )
    val updatedMessages = if (state.retryMessageId == null) {
        state.messages + message
    } else {
        state.messages.map { existingMessage ->
            if (existingMessage.id == state.retryMessageId) message else existingMessage
        }
    }

    return state.copy(
        messages = updatedMessages,
        pendingMessageId = messageId,
        pendingOutcome = if (shouldFail) LocalSendOutcome.Failure else LocalSendOutcome.Success,
        retryMessageId = null,
        failureNotice = null,
        nextLocalMessageOrdinal = if (state.retryMessageId == null) {
            state.nextLocalMessageOrdinal + 1
        } else {
            state.nextLocalMessageOrdinal
        },
    )
}

internal fun settlePendingLocalSend(
    state: ChatDetailUiState,
    localSend: LocalSendMockData,
    failureNotice: String,
): ChatDetailUiState {
    val messageId = state.pendingMessageId ?: return state
    val shouldFail = state.shouldSettleAsFailure()
    val resolvedDeliveryState = if (shouldFail) {
        localSend.failureDeliveryState
    } else {
        localSend.settledDeliveryState
    }

    return state.copy(
        messages = state.messages.map { message ->
            if (message.id == messageId) {
                message.copy(deliveryState = resolvedDeliveryState)
            } else {
                message
            }
        },
        draftMessage = if (!shouldFail && localSend.clearComposerOnSuccess) "" else state.draftMessage,
        pendingMessageId = null,
        pendingOutcome = null,
        retryMessageId = if (shouldFail) messageId else null,
        failureNotice = if (shouldFail) failureNotice else null,
    )
}
