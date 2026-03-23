package com.hypheng.telegram.kmp

import androidx.compose.foundation.clickable
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp

internal enum class ChatListDebugState {
    Default,
    Loading,
    Empty,
    Error,
}

private enum class ChatListViewState {
    Loading,
    Populated,
    Empty,
    Error,
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun HomeShellRoute(
    assets: StartupAssets,
    chatListDebugState: ChatListDebugState,
    onOpenConversation: (String) -> Unit,
) {
    val tabs = assets.sharedMockData.homeShell.tabs
    val defaultTabId = tabs.firstOrNull { it.id == assets.sharedMockData.homeShell.defaultTab }?.id
        ?: tabs.firstOrNull()?.id
        ?: "chats"
    var currentTabId by rememberSaveable { mutableStateOf(defaultTabId) }
    var chatListViewState by remember(chatListDebugState, assets.sharedMockData.chatList.conversations.size) {
        mutableStateOf(chatListDebugState.toInitialViewState(assets.sharedMockData.chatList.conversations))
    }

    val title = if (currentTabId == "chats") {
        assets.sharedCopy.chatList.title
    } else {
        assets.sharedCopy.homeShell.tabs.labelForTabId(currentTabId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(title) },
            )
        },
        bottomBar = {
            NavigationBar {
                tabs.forEach { tab ->
                    NavigationBarItem(
                        selected = currentTabId == tab.id,
                        onClick = { currentTabId = tab.id },
                        icon = {
                            Box(
                                modifier = Modifier
                                    .size(12.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (currentTabId == tab.id) {
                                            MaterialTheme.colorScheme.primary
                                        } else {
                                            MaterialTheme.colorScheme.surfaceVariant
                                        },
                                    ),
                            )
                        },
                        label = { Text(assets.sharedCopy.homeShell.tabs.labelForTabId(tab.id)) },
                    )
                }
            }
        },
        containerColor = MaterialTheme.colorScheme.surface,
    ) { padding ->
        when (currentTabId) {
            "chats" -> ChatListScreen(
                assets = assets,
                state = chatListViewState,
                onOpenConversation = onOpenConversation,
                modifier = Modifier.padding(padding),
            )

            else -> HomeTabPlaceholderScreen(
                tabLabel = assets.sharedCopy.homeShell.tabs.labelForTabId(currentTabId),
                notice = assets.sharedCopy.homeShell.placeholderNotice,
                modifier = Modifier.padding(padding),
            )
        }
    }
}

@Composable
private fun ChatListScreen(
    assets: StartupAssets,
    state: ChatListViewState,
    onOpenConversation: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    when (state) {
        ChatListViewState.Loading -> CenteredContent(modifier = modifier) {
            CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = assets.sharedCopy.chatList.loading,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }

        ChatListViewState.Empty -> ChatListMessageState(
            title = assets.sharedCopy.chatList.emptyTitle,
            body = assets.sharedCopy.chatList.emptyBody,
            modifier = modifier,
        )

        ChatListViewState.Error -> ChatListMessageState(
            title = assets.sharedCopy.chatList.errorTitle,
            body = assets.sharedCopy.chatList.errorBody,
            modifier = modifier,
        )

        ChatListViewState.Populated -> LazyColumn(
            modifier = modifier.fillMaxSize(),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(
                horizontal = assets.tokens.spacing.lg.dp,
                vertical = assets.tokens.spacing.lg.dp,
            ),
            verticalArrangement = Arrangement.spacedBy(assets.tokens.spacing.md.dp),
        ) {
            items(
                items = assets.sharedMockData.chatList.conversations,
                key = { it.id },
            ) { conversation ->
                ConversationRow(
                    conversation = conversation,
                    assets = assets,
                    onOpenConversation = onOpenConversation,
                )
            }
        }
    }
}

@Composable
private fun ConversationRow(
    conversation: ConversationMockData,
    assets: StartupAssets,
    onOpenConversation: (String) -> Unit,
) {
    Card {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { onOpenConversation(conversation.id) }
                .padding(assets.tokens.spacing.lg.dp),
            verticalAlignment = Alignment.Top,
        ) {
            ConversationAvatar(
                title = conversation.title,
                tintName = conversation.avatarTint,
                assets = assets,
            )
            Spacer(modifier = Modifier.size(assets.tokens.spacing.md.dp))
            Column(
                modifier = Modifier.weight(1f),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = conversation.title,
                        style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f),
                    )
                    Spacer(modifier = Modifier.size(assets.tokens.spacing.sm.dp))
                    Text(
                        text = conversation.timestamp,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = conversation.snippet,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(modifier = Modifier.height(10.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    if (conversation.pinned) {
                        ConversationMetaMarker(
                            color = assets.tokens.color.accent.brand.asColor(),
                        )
                    }
                    if (conversation.muted) {
                        ConversationMetaMarker(
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    Spacer(modifier = Modifier.weight(1f))
                    if (conversation.unreadCount > 0) {
                        Surface(
                            color = assets.tokens.color.badge.unreadBackground.asColor(),
                            shape = CircleShape,
                        ) {
                            Text(
                                text = conversation.unreadCount.toString(),
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                                color = assets.tokens.color.badge.unreadText.asColor(),
                                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ConversationAvatar(
    title: String,
    tintName: String,
    assets: StartupAssets,
) {
    Box(
        modifier = Modifier
            .size(assets.tokens.avatarSize.list.dp)
            .clip(CircleShape)
            .background(assets.tokens.color.avatar.asTintColor(tintName)),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = title.firstOrNull()?.uppercase() ?: "?",
            color = MaterialTheme.colorScheme.onPrimary,
            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
        )
    }
}

@Composable
private fun ConversationMetaMarker(
    color: androidx.compose.ui.graphics.Color,
) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = CircleShape,
    ) {
        Box(
            modifier = Modifier
                .padding(horizontal = 8.dp, vertical = 7.dp)
                .size(8.dp)
                .clip(CircleShape)
                .background(color),
        )
    }
}

@Composable
private fun HomeTabPlaceholderScreen(
    tabLabel: String,
    notice: String,
    modifier: Modifier = Modifier,
) {
    CenteredContent(modifier = modifier) {
        Text(
            text = tabLabel,
            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold),
            color = MaterialTheme.colorScheme.onSurface,
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = notice,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun ChatListMessageState(
    title: String,
    body: String,
    modifier: Modifier = Modifier,
) {
    CenteredContent(modifier = modifier) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold),
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(10.dp))
        Text(
            text = body,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun CenteredContent(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            content = content,
        )
    }
}

private fun ChatListDebugState.toInitialViewState(
    conversations: List<ConversationMockData>,
): ChatListViewState = when (this) {
    ChatListDebugState.Loading -> ChatListViewState.Loading
    ChatListDebugState.Empty -> ChatListViewState.Empty
    ChatListDebugState.Error -> ChatListViewState.Error
    ChatListDebugState.Default -> if (conversations.isEmpty()) {
        ChatListViewState.Empty
    } else {
        ChatListViewState.Populated
    }
}

internal fun HomeShellTabsCopy.labelForTabId(tabId: String): String = when (tabId) {
    "contacts" -> contacts
    "settings" -> settings
    else -> chats
}

private fun AvatarColors.asTintColor(tintName: String) = when (tintName) {
    "green" -> green.asColor()
    "orange" -> orange.asColor()
    "purple" -> purple.asColor()
    else -> blue.asColor()
}
