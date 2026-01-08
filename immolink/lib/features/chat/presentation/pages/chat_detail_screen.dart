import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/widgets/user_avatar.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/presentation/providers/messages_provider.dart';
import 'package:immosync/features/chat/presentation/providers/chat_provider.dart';
import 'package:immosync/core/presence/presence_ws_service.dart';
import 'package:immosync/l10n/app_localizations.dart';

enum _ChatMenuAction {
  reportUser,
  blockUser,
  deleteConversation,
}

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({
    super.key,
    this.conversationId = 'new',
    this.otherUserId,
    this.title = 'John Doe',
    this.status = 'Online',
    this.avatarUrl,
  });

  final String conversationId;
  final String? otherUserId;
  final String title;
  final String status;
  final String? avatarUrl;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  static const _bgTop = Color(0xFF0A1128);
  static const _bgBottom = Colors.black;
  static const _theirBubble = Color(0xFF2C2C2E);
  static const _inputDock = Color(0xFF1C1C1E);
  static const _inputFill = Color(0xFF2C2C2E);

  final _controller = TextEditingController();

  bool _decryptRequested = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(DateTime timestamp) {
    final t = TimeOfDay.fromDateTime(timestamp);
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _messageStatusLabel(AppLocalizations l10n, ChatMessage message) {
    if (message.readAt != null || message.isRead) return l10n.messageStatusRead;
    if (message.deliveredAt != null) {
      return l10n.messageStatusDelivered;
    }
    if (message.id.startsWith('temp_')) return l10n.messageStatusSending;
    return l10n.messageStatusSent;
  }

  String _resolveCurrentUserId() {
    final currentUserId = ref.read(currentUserProvider)?.id;
    if (currentUserId != null &&
        currentUserId.isNotEmpty &&
        currentUserId != 'null') {
      return currentUserId;
    }
    final authUserId = ref.read(authProvider).userId;
    if (authUserId != null && authUserId.isNotEmpty && authUserId != 'null') {
      return authUserId;
    }
    return 'unknown-user';
  }

  Future<bool> _confirmAction({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _inputDock,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                confirmLabel,
                style: TextStyle(
                  color: destructive ? Colors.redAccent : Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showSnack(String text) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _handleMenuAction(_ChatMenuAction action) async {
    final l10n = AppLocalizations.of(context)!;
    final me = _resolveCurrentUserId();
    final other = widget.otherUserId;
    final convId = widget.conversationId;

    final chatService = ref.read(chatServiceProvider);

    try {
      switch (action) {
        case _ChatMenuAction.reportUser:
          if (me == 'unknown-user') {
            _showSnack(l10n.mustBeLoggedInToReport);
            return;
          }
          if (convId == 'new') {
            _showSnack(l10n.missingRecipientForNewChat);
            return;
          }
          final ok = await _confirmAction(
            title: l10n.reportConversation,
            body: l10n.reportConfirmBody,
            confirmLabel: l10n.report,
          );
          if (!ok) return;

          await chatService.reportConversation(
            conversationId: convId,
            reporterId: me,
            reportedUserId: (other != null && other.isNotEmpty) ? other : null,
            reason: 'user_report',
          );
          if (!mounted) return;
          _showSnack(l10n.reported);
          return;

        case _ChatMenuAction.blockUser:
          if (other == null || other.isEmpty) {
            _showSnack(l10n.missingRecipientForNewChat);
            return;
          }
          final ok = await _confirmAction(
            title: l10n.blockUser,
            body: l10n.blockConfirmBody,
            confirmLabel: l10n.blockUser,
            destructive: true,
          );
          if (!ok) return;

          await chatService.blockUser(userId: me, targetUserId: other);
          if (!mounted) return;
          _showSnack(l10n.userBlockedSuccessfully);
          return;

        case _ChatMenuAction.deleteConversation:
          if (convId == 'new') {
            if (!mounted) return;
            context.pop();
            return;
          }
          final ok = await _confirmAction(
            title: l10n.deleteConversation,
            body: l10n.deleteConversationConfirmBody,
            confirmLabel: l10n.deleteConversation,
            destructive: true,
          );
          if (!ok) return;

          final token = ref.read(authProvider).sessionToken;
          await chatService.deleteConversationWithToken(convId, token);
          if (!mounted) return;
          _showSnack(l10n.conversationDeletedSuccessfully);
          context.pop();
          return;
      }
    } catch (e) {
      if (!mounted) return;
      switch (action) {
        case _ChatMenuAction.reportUser:
          _showSnack(l10n.failedToReportConversation(e.toString()));
          return;
        case _ChatMenuAction.blockUser:
          _showSnack(l10n.failedToBlockUser(e.toString()));
          return;
        case _ChatMenuAction.deleteConversation:
          _showSnack(l10n.failedToDeleteConversation(e.toString()));
          return;
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;

    final senderId = _resolveCurrentUserId();
    final receiverId = widget.otherUserId ?? '';
    _controller.clear();

    final convId = widget.conversationId;
    if (convId == 'new') {
      if (receiverId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.missingRecipientForNewChat)),
        );
        return;
      }
      ref.read(presenceWsServiceProvider).createConversation(
            otherUserId: receiverId,
            initialMessage: text,
          );
      return;
    }

    await ref.read(messageSenderProvider.notifier).sendMessage(
          conversationId: convId,
          senderId: senderId,
          receiverId: receiverId,
          content: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<AsyncValue<void>>(messageSenderProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.failedToSendMessage}: $error'),
            ),
          );
        },
      );
    });

    final currentUserId = _resolveCurrentUserId();
    final sendState = ref.watch(messageSenderProvider);
    final isSending = sendState.isLoading;

    final messagesAsync = widget.conversationId == 'new'
        ? const AsyncValue.data(<ChatMessage>[])
        : ref.watch(conversationMessagesProvider(widget.conversationId));

    if (!_decryptRequested &&
        widget.conversationId != 'new' &&
        widget.otherUserId != null &&
        widget.otherUserId!.isNotEmpty) {
      _decryptRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(conversationMessagesProvider(widget.conversationId).notifier)
            .decryptHistory(ref: ref, otherUserId: widget.otherUserId!);
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: Column(
          children: [
            _GlassHeader(
              title: widget.title,
              status: widget.status,
              avatarUrl: widget.avatarUrl,
              onMenuAction: _handleMenuAction,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${l10n.failedToLoadMessages}: $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                data: (messages) {
                  final lastOutgoingId = messages
                      .lastWhere(
                        (m) => m.senderId == currentUserId,
                        orElse: () => ChatMessage(
                          id: '',
                          senderId: '',
                          receiverId: '',
                          content: '',
                          timestamp: DateTime.fromMillisecondsSinceEpoch(0),
                        ),
                      )
                      .id;

                  final uiMessages = messages.reversed.toList(growable: false);

                  if (uiMessages.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noMessagesYet,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    itemCount: uiMessages.length,
                    itemBuilder: (context, index) {
                      final m = uiMessages[index];
                      final isMe = m.senderId == currentUserId;
                      final text = (m.content.isEmpty && m.isEncrypted)
                          ? l10n.encryptedMessagePlaceholder
                          : m.content;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MessageRow(
                          message: _ChatMessageItem(
                            id: m.id,
                            text: text,
                            isMe: isMe,
                            time: _formatTime(m.timestamp),
                            status: (isMe &&
                                    lastOutgoingId.isNotEmpty &&
                                    m.id == lastOutgoingId)
                                ? _messageStatusLabel(l10n, m)
                                : null,
                          ),
                          theirBubbleColor: _theirBubble,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: _InputDock(
                controller: _controller,
                inputFill: _inputFill,
                dockColor: _inputDock,
                onSend: isSending ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassHeader extends ConsumerWidget {
  const _GlassHeader({
    required this.title,
    required this.status,
    required this.onBack,
    required this.onMenuAction,
    this.avatarUrl,
  });

  final String title;
  final String status;
  final VoidCallback onBack;
  final ValueChanged<_ChatMenuAction> onMenuAction;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isOnline = status.toLowerCase() == 'online';

    return SafeArea(
      bottom: false,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.60),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: l10n.back,
                ),
                UserAvatar(
                  imageRef: avatarUrl,
                  name: title,
                  size: 34,
                  fallbackToCurrentUser: false,
                  bgColor: Colors.white.withValues(alpha: 0.10),
                  textColor: Colors.white70,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isOnline
                              ? const Color(0xFF22C55E)
                              : Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_rounded, color: Colors.white70),
                  tooltip: l10n.call,
                ),
                PopupMenuButton<_ChatMenuAction>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white70,
                  ),
                  tooltip: l10n.more,
                  onSelected: onMenuAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _ChatMenuAction.reportUser,
                      child: Text(l10n.reportConversation),
                    ),
                    PopupMenuItem(
                      value: _ChatMenuAction.blockUser,
                      child: Text(l10n.blockUser),
                    ),
                    PopupMenuItem(
                      value: _ChatMenuAction.deleteConversation,
                      child: Text(l10n.deleteConversation),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.theirBubbleColor});

  final _ChatMessageItem message;
  final Color theirBubbleColor;

  @override
  Widget build(BuildContext context) {
    final align =
        message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final rowAlign =
        message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start;

    return Row(
      mainAxisAlignment: rowAlign,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: align,
            children: [
              _Bubble(
                message: message,
                theirBubbleColor: theirBubbleColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.theirBubbleColor});

  final _ChatMessageItem message;
  final Color theirBubbleColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(message.isMe ? 18 : 0),
      bottomRight: Radius.circular(message.isMe ? 0 : 18),
    );

    final decoration = message.isMe
        ? BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B82F6),
                Color(0xFF22D3EE),
              ],
            ),
            borderRadius: radius,
          )
        : BoxDecoration(
            color: theirBubbleColor,
            borderRadius: radius,
          );

    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
      decoration: decoration,
      child: Column(
        crossAxisAlignment:
            message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.25,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  height: 1,
                ),
              ),
              if (message.isMe && message.status != null) ...[
                const SizedBox(width: 8),
                Text(
                  message.status!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InputDock extends StatelessWidget {
  const _InputDock({
    required this.controller,
    required this.inputFill,
    required this.dockColor,
    required this.onSend,
  });

  final TextEditingController controller;
  final Color inputFill;
  final Color dockColor;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: dockColor,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, color: Colors.white54),
            tooltip: l10n.attach,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: inputFill,
                hintText: l10n.typeAMessage,
                hintStyle: const TextStyle(color: Colors.white54),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend?.call(),
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(onTap: onSend),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF22D3EE),
            ],
          ),
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ChatMessageItem {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final String? status;

  const _ChatMessageItem({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.status,
  });
}
