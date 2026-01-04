import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/widgets/user_avatar.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/presentation/providers/messages_provider.dart';
import 'package:immosync/core/presence/presence_ws_service.dart';

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

  String _messageStatusLabel(ChatMessage message) {
    if (message.readAt != null || message.isRead) return 'Read';
    if (message.deliveredAt != null) return 'Delivered';
    if (message.id.startsWith('temp_')) return 'Sending…';
    return 'Sent';
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final senderId = _resolveCurrentUserId();
    final receiverId = widget.otherUserId ?? '';
    _controller.clear();

    final convId = widget.conversationId;
    if (convId == 'new') {
      if (receiverId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing recipient for new chat')),
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
    ref.listen<AsyncValue<void>>(messageSenderProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: $error'),
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
                      'Failed to load messages: $error',
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
                    return const Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.white54),
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
                          ? '[encrypted]'
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
                                ? _messageStatusLabel(m)
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
    this.avatarUrl,
  });

  final String title;
  final String status;
  final VoidCallback onBack;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Back',
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
                  tooltip: 'Call',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Colors.white70),
                  tooltip: 'More',
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
    return Container(
      color: dockColor,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, color: Colors.white54),
            tooltip: 'Attach',
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
                hintText: 'Type a message…',
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
