import 'package:flutter/material.dart';

import '../../shared/assets/shared_models.dart';

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({
    super.key,
    required this.conversation,
    required this.chatDetailCopy,
    required this.chatDetailData,
    required this.onBack,
  });

  final ChatConversation conversation;
  final ChatDetailCopy chatDetailCopy;
  final ChatDetailData chatDetailData;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              conversation.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              chatDetailData.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                key: PageStorageKey<String>('chat-detail-${conversation.id}'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: chatDetailData.messages.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return _DateSeparator(label: chatDetailData.dateLabel);
                  }
                  final ChatDetailMessage message =
                      chatDetailData.messages[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MessageBubble(message: message),
                  );
                },
              ),
            ),
            _InactiveComposerShell(
              placeholder: chatDetailData.composerPlaceholder.isEmpty
                  ? chatDetailCopy.composerPlaceholder
                  : chatDetailData.composerPlaceholder,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatDetailMessage message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool outgoing = message.isOutgoing;
    final Color bubbleColor = outgoing
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerLow;
    final Color textColor = outgoing
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message.text,
                  style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      message.timeLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    if (message.deliveryLabel != null) ...<Widget>[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: _deliveryLabel(message.deliveryLabel!),
                        child: Icon(
                          _deliveryIcon(message.deliveryLabel!),
                          size: 16,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _deliveryIcon(String label) {
    switch (label) {
      case 'pending-local':
        return Icons.schedule_rounded;
      case 'failed':
        return Icons.error_outline_rounded;
      case 'sent-read':
        return Icons.done_all_rounded;
      case 'sent':
      default:
        return Icons.done_rounded;
    }
  }

  String _deliveryLabel(String label) {
    switch (label) {
      case 'pending-local':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'sent-read':
        return 'Read';
      case 'sent':
      default:
        return 'Sent';
    }
  }
}

class _InactiveComposerShell extends StatelessWidget {
  const _InactiveComposerShell({required this.placeholder});

  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  placeholder,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.block_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Inactive',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
