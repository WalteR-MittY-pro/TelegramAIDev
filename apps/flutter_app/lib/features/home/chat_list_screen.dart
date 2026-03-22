import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shared/assets/shared_models.dart';

enum ChatListViewState { loading, populated, empty, error }

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({
    super.key,
    required this.copy,
    required this.conversations,
    required this.avatarPlaceholderAssetPath,
    required this.state,
    this.onOpenConversation,
    this.onRetry,
  });

  final ChatListCopy copy;
  final List<ChatConversation> conversations;
  final String? avatarPlaceholderAssetPath;
  final ChatListViewState state;
  final ValueChanged<String>? onOpenConversation;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ChatListViewState.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(copy.loading),
            ],
          ),
        );
      case ChatListViewState.empty:
        return _ChatListMessageState(
          title: copy.emptyTitle,
          body: copy.emptyBody,
        );
      case ChatListViewState.error:
        return _ChatListMessageState(
          title: copy.errorTitle,
          body: copy.errorBody,
          actionLabel: 'Retry',
          onAction: onRetry,
        );
      case ChatListViewState.populated:
        return ListView.separated(
          key: const PageStorageKey<String>('chat-list'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: conversations.length,
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: 8);
          },
          itemBuilder: (BuildContext context, int index) {
            final ChatConversation conversation = conversations[index];
            return _ConversationRow(
              conversation: conversation,
              avatarPlaceholderAssetPath: avatarPlaceholderAssetPath,
              onTap: onOpenConversation == null
                  ? null
                  : () => onOpenConversation!(conversation.id),
            );
          },
        );
    }
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.conversation,
    required this.avatarPlaceholderAssetPath,
    required this.onTap,
  });

  final ChatConversation conversation;
  final String? avatarPlaceholderAssetPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color unreadBackground = theme.colorScheme.primary;
    final Color unreadForeground = theme.colorScheme.onPrimary;

    return Card(
      child: InkWell(
        key: ValueKey<String>('conversation-row-${conversation.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ConversationAvatar(
                assetPath:
                    avatarPlaceholderAssetPath ?? conversation.avatarAssetPath,
                tintName: conversation.avatarTintName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            conversation.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          conversation.timestamp,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            conversation.snippet,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            if (conversation.pinned)
                              Icon(
                                Icons.push_pin_rounded,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            if (conversation.muted)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.volume_off_rounded,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (conversation.unreadCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: unreadBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${conversation.unreadCount}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: unreadForeground,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.assetPath, required this.tintName});

  final String assetPath;
  final String tintName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _backgroundColor(),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        assetPath,
        width: 26,
        height: 26,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  Color _backgroundColor() {
    switch (tintName) {
      case 'green':
        return const Color(0xFF4CAF50);
      case 'purple':
        return const Color(0xFF8E6CEF);
      case 'blue':
      default:
        return const Color(0xFF4C8DFF);
    }
  }
}

class _ChatListMessageState extends StatelessWidget {
  const _ChatListMessageState({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.forum_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
