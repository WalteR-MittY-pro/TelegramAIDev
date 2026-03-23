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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun ChatDetailRoute(
    assets: StartupAssets,
    conversationId: String?,
    onBack: () -> Unit,
) {
    val conversation = resolveChatDetailConversation(
        chatList = assets.sharedMockData.chatList,
        chatDetail = assets.sharedMockData.chatDetail,
        requestedConversationId = conversationId,
    )
    val chatDetail = assets.sharedMockData.chatDetail
    val chatDetailCopy = assets.sharedCopy.chatDetail

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
            ChatDetailComposerShell(
                assets = assets,
                placeholder = chatDetail.composer?.placeholder ?: chatDetailCopy.composerPlaceholder,
                sendLabel = chatDetailCopy.sendLabel,
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
                items = chatDetail.messages,
                key = { it.id },
            ) { message ->
                SeedMessageBubble(
                    message = message,
                    assets = assets,
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
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ChatDetailComposerShell(
    assets: StartupAssets,
    placeholder: String,
    sendLabel: String,
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
                value = "",
                onValueChange = {},
                modifier = Modifier.weight(1f),
                enabled = false,
                readOnly = true,
                placeholder = { Text(placeholder) },
                singleLine = true,
            )
            Button(
                onClick = {},
                enabled = false,
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

internal fun SeedMessage.displayDeliveryLabel(): String? = deliveryLabel?.replace("-", " ")
