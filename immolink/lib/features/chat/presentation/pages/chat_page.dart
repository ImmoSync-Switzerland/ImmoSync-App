import 'package:flutter/material.dart';
import 'dart:io';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/core/widgets/user_avatar.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/presentation/providers/messages_provider.dart';
import 'package:immosync/features/chat/presentation/providers/chat_provider.dart'
    as chat_providers;
import 'package:immosync/features/chat/domain/services/chat_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/presence/presence_ws_service.dart';
import '../../../../core/presence/presence_cache.dart';
import '../../../../core/crypto/e2ee_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:immosync/features/chat/infrastructure/matrix_chat_service.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? otherUserId;

  const ChatPage({
    required this.conversationId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.otherUserId,
    super.key,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isTyping = false; // local user typing
  bool _otherTyping = false; // remote user typing
  // Removed polling timer
  Timer? _presenceTimer; // Fallback heartbeat only
  bool _otherOnline = false;
  DateTime? _otherLastSeen;
  ProviderSubscription<Map<String, PresenceInfo>>? _presenceCacheRemove;
  ProviderSubscription<dynamic>? _authConnSub;
  Timer? _wsConnectRetry;
  // Stream subscriptions for chat & conversation sockets (to cancel on dispose)
  StreamSubscription<Map<String, dynamic>>? _chatStreamSub;
  StreamSubscription<Map<String, dynamic>>? _conversationStreamSub;
  ProviderSubscription<AsyncValue<List<ChatMessage>>>? _messagesDecryptSub;

  // Pending attachment state
  XFile? _pendingImage;
  PlatformFile? _pendingFile;
  bool _sendingAttachment = false;
  bool _encryptionReady = false;
  double? _uploadProgress; // 0..1 while uploading
  Timer? _encryptionRetryTimer;
  int _encryptionRetryAttempts = 0;

  String? _currentConversationId;
  // Per-message visibility tracking
  final Map<String, GlobalKey> _messageKeys = {};
  final Set<String> _readSent = {};
  Timer? _visibilityDebounce;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Start fallback refresh and init layers
    _currentConversationId = widget.conversationId;
    // No polling refresh (pure WS)
    // Matrix-only mode: disable legacy WS presence/chat layers
    // _initPresenceLayer();
    // _initChatWsListener();
    // Attempt initial read marking shortly after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_emitReadReceipts());
    });
    // Attach scroll listener for fine-grained visibility based read detection
    _scrollController.addListener(_onScrollVisibilityCheck);
    // Pre-derive conversation key (best-effort) for faster first encrypted message
    if (widget.otherUserId != null) {
      Future.microtask(() async {
        try {
          final e2ee = ref.read(e2eeServiceProvider);
          await e2ee.ensureInitialized();
          e2ee
              .ensureConversationKey(
                  conversationId: widget.conversationId,
                  otherUserId: widget.otherUserId!)
              .then((ok) {
            if (mounted) {
              setState(() {
                _encryptionReady = ok;
              });
              if (!ok) _scheduleEncryptionRetry();
              if (ok) {
                try {
                  ref
                      .read(conversationMessagesProvider(widget.conversationId)
                          .notifier)
                      .decryptHistory(
                          ref: ref, otherUserId: widget.otherUserId!);
                } catch (_) {}
              }
            }
          });
          _messagesDecryptSub = ref.listenManual<AsyncValue<List<ChatMessage>>>(
            conversationMessagesProvider(widget.conversationId),
            (prev, next) {
              if (!_encryptionReady) return;
              next.whenData((msgs) {
                final needs = msgs.any((m) =>
                    m.isEncrypted &&
                    (m.content.isEmpty || m.content == '[encrypted]'));
                if (needs) {
                  try {
                    ref
                        .read(
                            conversationMessagesProvider(widget.conversationId)
                                .notifier)
                        .decryptHistory(
                            ref: ref, otherUserId: widget.otherUserId ?? '');
                  } catch (_) {}
                }
              });
            },
          );
        } catch (_) {
          if (mounted)
            setState(() {
              _encryptionReady = false;
            });
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    // no polling timer to cancel
    _presenceTimer?.cancel();
    _visibilityDebounce?.cancel();
    _presenceCacheRemove?.close();
    _authConnSub?.close();
    _wsConnectRetry?.cancel();
    _encryptionRetryTimer?.cancel();
    _chatStreamSub?.cancel();
    _conversationStreamSub?.cancel();
    _messagesDecryptSub?.close();
    super.dispose();
  }

  // polling removed and legacy WS removed

  // Heartbeat and HTTP presence fetch removed in Matrix-only mode

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(conversationMessagesProvider(widget.conversationId));
    final currentUser = ref.watch(currentUserProvider);
    final colors = ref.watch(dynamicColorsProvider);

    // Listen for message changes and auto-scroll to bottom
    ref.listen<AsyncValue<List<ChatMessage>>>(
      conversationMessagesProvider(widget.conversationId),
      (previous, next) {
        next.whenData((messages) {
          if (messages.isNotEmpty && _scrollController.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          }
        });
      },
    );

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Matrix initialization status banner
          ValueListenableBuilder<MatrixClientState>(
            valueListenable: ChatService.clientState,
            builder: (context, state, _) {
              if (state == MatrixClientState.ready) return const SizedBox.shrink();
              String text;
              bool busy = true;
              switch (state) {
                case MatrixClientState.starting:
                  text = 'Matrix wird initialisiert …';
                  break;
                case MatrixClientState.ensuringCrypto:
                  text = 'Ende-zu-Ende-Verschlüsselung wird vorbereitet …';
                  break;
                case MatrixClientState.ensuringRoom:
                  text = 'Chat-Verbindung wird erstellt …';
                  break;
                case MatrixClientState.error:
                  text = 'Matrix-Fehler – bitte später erneut versuchen.';
                  busy = false;
                  break;
                default:
                  text = 'Matrix wird initialisiert …';
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.amber.withOpacity(0.15),
                child: Row(
                  children: [
                    if (busy)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    if (busy) const SizedBox(width: 8),
                    Expanded(child: Text(text)),
                    if (state == MatrixClientState.error)
                      TextButton(
                        onPressed: () async {
                          final me = ref.read(currentUserProvider)?.id ?? '';
                          if (me.isNotEmpty) {
                            await ref.read(chat_providers.chatServiceProvider).ensureMatrixReady(userId: me);
                          }
                        },
                        child: const Text('Erneut verbinden'),
                      ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: messagesAsync.when(
              data: (messages) =>
                  _buildMessagesList(messages, currentUser?.id ?? ''),
              loading: () => Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colors.primaryAccent),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colors.error),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!
                          .failedToLoadImage, // TODO: replace with dedicated failedToLoadMessages key
                      style: AppTypography.subhead.copyWith(
                        color: colors.error,
                        inherit: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                          conversationMessagesProvider(widget.conversationId)),
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildMessageInput(currentUser?.id ?? ''),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colors = ref.watch(dynamicColorsProvider);
    
    return AppBar(
      backgroundColor: colors.primaryBackground,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
      ),
      title: Row(
        children: [
          UserAvatar(
            imageRef: widget.otherUserAvatar,
            name: widget.otherUserName,
            size: 40,
            fallbackToCurrentUser: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    inherit: true,
                  ),
                ),
                if (_otherTyping)
                  Text(
                    'typing...',
                    style: TextStyle(
                      color: colors.primaryAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      inherit: true,
                    ),
                  )
                else
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: _otherOnline
                              ? Colors.green
                              : colors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        _otherOnline ? 'Online' : _formatLastSeen(),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          inherit: true,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.call_outlined, color: colors.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            _initiateVoiceCall();
          },
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: colors.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showChatOptions();
          },
        ),
      ],
    );
  }

  String _formatLastSeen() {
    if (_otherLastSeen == null) return 'Offline';
    final diff = DateTime.now().difference(_otherLastSeen!);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std';
    return 'vor ${diff.inDays} Tg';
  }

  Widget _buildMessagesList(List<ChatMessage> messages, String currentUserId) {
    if (messages.isEmpty) {
      return _buildEmptyMessagesState();
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _slideAnimation.value,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.horizontalPadding),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe = message.senderId == currentUserId;
              final showDate = index == 0 ||
                  !_isSameDay(message.timestamp, messages[index - 1].timestamp);
              // Ensure a GlobalKey for visibility tracking
              _messageKeys.putIfAbsent(message.id, () => GlobalKey());

              return Column(
                children: [
                  if (showDate) _buildDateSeparator(message.timestamp),
                  _MessageVisibilityWrapper(
                    key: _messageKeys[message.id],
                    child: _buildMessageBubble(message, isMe),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyMessagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryAccent.withValues(alpha: 0.1),
                  AppColors.primaryAccent.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.primaryAccent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation with ${widget.otherUserName}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceCards,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(date),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final colors = ref.watch(dynamicColorsProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            UserAvatar(
              imageRef: widget.otherUserAvatar,
              name: widget.otherUserName,
              size: 32,
              fallbackToCurrentUser: false,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xF23B82F6), // Blue #3B82F6 @ 95%
                          Color(0xD98B5CF6), // Purple #8B5CF6 @ 85%
                        ],
                      )
                    : null,
                color: isMe ? null : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.isEncrypted) ...[
                        Icon(Icons.lock,
                            size: 14,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.75)
                                : colors.textSecondary),
                        const SizedBox(width: 4),
                      ] else if (_encryptionReady &&
                          message.messageType == 'text') ...[
                        Icon(Icons.warning_amber_outlined,
                            size: 14,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.75)
                                : Colors.orangeAccent),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                          child: _buildMessageContent(message, isMe, colors)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.75)
                          : colors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      inherit: true,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.readAt != null
                          ? Icons.done_all
                          : (message.deliveredAt != null
                              ? Icons.check
                              : Icons.access_time),
                      size: 14,
                      color: message.readAt != null
                          ? Colors.white.withValues(alpha: 0.95)
                          : (message.deliveredAt != null
                              ? Colors.white.withValues(alpha: 0.75)
                              : Colors.white.withValues(alpha: 0.5)),
                    )
                  ]
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            UserAvatar(size: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, bool isMe, dynamic colors) {
    // Basic handling for image/file types (no preview yet)
    if (message.messageType == 'image') {
      final name = message.metadata?['fileName'] ?? message.content;
      return GestureDetector(
        onTap: () async {
          if (message.metadata?['fileId'] != null) {
            final other = isMe ? (message.receiverId) : message.senderId;
            final bytes = await ref
                .read(chat_providers.chatServiceProvider)
                .downloadAndDecryptAttachment(
                  message: message,
                  currentUserId: ref.read(currentUserProvider)?.id ?? '',
                  otherUserId: other,
                  ref: ref,
                );
            if (bytes != null && mounted) {
              showDialog(
                  context: context,
                  builder: (_) => Dialog(
                        child: Image.memory(Uint8List.fromList(bytes),
                            fit: BoxFit.contain),
                      ));
            }
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.image,
                size: 18, color: isMe ? Colors.white70 : colors.primaryAccent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(name,
                  style: AppTypography.body.copyWith(
                      color: isMe ? Colors.white : colors.textPrimary,
                      inherit: true)),
            ),
          ],
        ),
      );
    }
    if (message.messageType == 'file') {
      final name = message.metadata?['fileName'] ?? message.content;
      return GestureDetector(
        onTap: () async {
          if (message.metadata?['fileId'] != null) {
            final other = isMe ? (message.receiverId) : message.senderId;
            final bytes = await ref
                .read(chat_providers.chatServiceProvider)
                .downloadAndDecryptAttachment(
                  message: message,
                  currentUserId: ref.read(currentUserProvider)?.id ?? '',
                  otherUserId: other,
                  ref: ref,
                );
            if (bytes != null && mounted) {
              try {
                final dir = await getTemporaryDirectory();
                final path = '${dir.path}/$name';
                final f = File(path);
                await f.writeAsBytes(bytes, flush: true);
                await OpenFilex.open(f.path);
              } catch (e) {
                final l10n = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.openFileFailed}: $e')));
              }
            }
          }
        },
        child: Row(children: [
          Icon(Icons.insert_drive_file,
              size: 18, color: isMe ? Colors.white70 : colors.primaryAccent),
          const SizedBox(width: 6),
          Expanded(
              child: Text(name,
                  style: AppTypography.body.copyWith(
                      color: isMe ? Colors.white : colors.textPrimary,
                      inherit: true))),
        ]),
      );
    }
    return Text(
      message.content,
      style: AppTypography.body.copyWith(
        color: isMe ? Colors.white : colors.textPrimary,
        inherit: true,
      ),
    );
  }

  Widget _buildMessageInput(String currentUserId) {
    final colors = ref.watch(dynamicColorsProvider);

    return ValueListenableBuilder<MatrixClientState>(
      valueListenable: ChatService.clientState,
      builder: (context, state, _) {
        final matrixReady = state == MatrixClientState.ready;
        return Container(
      padding: const EdgeInsets.all(AppSpacing.horizontalPadding),
      decoration: BoxDecoration(
        color: colors.primaryBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_pendingImage != null || _pendingFile != null) ...[
              _buildAttachmentPreview(),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                // Attachment button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: colors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () => _showAttachmentOptions(),
                  ),
                ),
                const SizedBox(width: 8),
                // Emoji button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: colors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () => _showEmojiPicker(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _messageController,
                      enabled: matrixReady,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        inherit: true,
                      ),
                      decoration: InputDecoration(
                        hintText: matrixReady
                            ? AppLocalizations.of(context)!.typeAMessage
                            : 'Warte auf Matrix …',
                        hintStyle: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          inherit: true,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (text) {
                        setState(() {
                          _isTyping = text.isNotEmpty;
                          final convId = _currentConversationId;
                          if (convId != null && convId != 'new') {
                            ref.read(presenceWsServiceProvider).sendTyping(
                                conversationId: convId, isTyping: true);
                            // Schedule stop typing after debounce
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted && _isTyping == false) {
                                ref.read(presenceWsServiceProvider).sendTyping(
                                    conversationId: convId, isTyping: false);
                              }
                            });
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () {
                    if (!matrixReady) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Matrix wird initialisiert …')),
                      );
                      return;
                    }
                    if (_sendingAttachment) return; // busy
                    if (!_encryptionReady &&
                        widget.otherUserId != null &&
                        (_currentConversationId ?? widget.conversationId) !=
                            'new') {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .encryptionKeyNotReady)));
                      return;
                    }
                    if (_pendingImage != null || _pendingFile != null) {
                      _sendPendingAttachment(currentUserId);
                    } else if (_messageController.text.trim().isNotEmpty) {
                      _sendMessage(currentUserId);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _sendingAttachment
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.textTertiary,
                                colors.textTertiary.withValues(alpha: 0.8),
                              ],
                            )
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xF23B82F6), // Blue #3B82F6 @ 95%
                                Color(0xD98B5CF6), // Purple #8B5CF6 @ 85%
                              ],
                            ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x4D3B82F6).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _sendingAttachment
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)),
                          )
                        : (!_encryptionReady &&
                                widget.otherUserId != null &&
                                (_currentConversationId ??
                                        widget.conversationId) !=
                                    'new')
                            ? const Icon(Icons.lock_clock,
                                color: Colors.white, size: 20)
                            : Icon(
                                _pendingImage != null || _pendingFile != null
                                    ? Icons.cloud_upload
                                    : Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                  ),
                ),
              ],
            ),
            if (_uploadProgress != null) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(value: _uploadProgress, minHeight: 4),
            ],
          ],
        ),
      ),
    );
      },
    );
  }

  void _sendMessage(String senderId) async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();
    setState(() {
      _isTyping = false;
    });
    try {
      // TODO: Migrate to WebSocket send for lower latency & real-time fanout
      // Example (after ensuring conversationId is established):
      // ref.read(presenceWsServiceProvider).sendChatMessage(
      //   conversationId: widget.conversationId,
      //   senderId: realSenderId,
      //   content: content,
      // );
      // For new conversation creation keep REST flow until WS creation event exists.
      // Get the real current user ID from auth provider
      final currentUser = ref.read(currentUserProvider);
      final realSenderId = currentUser?.id ?? 'unknown-user';

      print(
          'Sending message with senderId: $realSenderId, otherUserId: ${widget.otherUserId}');

      final convId = _currentConversationId ?? widget.conversationId;
      if (convId == 'new') {
        // Keep using WS conversation creation for now
        ref.read(presenceWsServiceProvider).createConversation(
              otherUserId: widget.otherUserId ?? '',
              initialMessage: content,
            );
      } else {
        // Use Matrix-only send via provider
        await ref.read(messageSenderProvider.notifier).sendMessage(
              conversationId: convId,
              senderId: realSenderId,
              receiverId: widget.otherUserId ?? '',
              content: content,
            );
      }

      _scrollToBottom();
    } catch (error) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.failedToSendMessage}: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    _emitReadReceipts();
  }

  void _scheduleEncryptionRetry() {
    if (widget.otherUserId == null) return;
    if (_encryptionRetryAttempts >= 8) return; // cap retries (~8 * 2s = 16s)
    _encryptionRetryAttempts++;
    _encryptionRetryTimer?.cancel();
    _encryptionRetryTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      try {
        final e2ee = ref.read(e2eeServiceProvider);
        final ok = await e2ee.ensureConversationKey(
            conversationId: _currentConversationId ?? widget.conversationId,
            otherUserId: widget.otherUserId!);
        if (mounted) {
          setState(() {
            _encryptionReady = ok;
          });
          if (!ok) _scheduleEncryptionRetry();
        }
      } catch (_) {
        if (mounted) _scheduleEncryptionRetry();
      }
    });
  }

  Future<void> _emitReadReceipts() async {
    if (!mounted) return;
    final convId = _currentConversationId ?? widget.conversationId;
    if (convId == 'new') return;
    final currentUserId = ref.read(currentUserProvider)?.id;
    if (currentUserId == null) return;
    final messagesAsync = ref.read(conversationMessagesProvider(convId));
    final messages = messagesAsync.maybeWhen(data: (m) => m, orElse: () => []);
    if (messages.isEmpty) return;
    // Determine visible: if scrolled near bottom treat all as viewed.
    if (_scrollController.hasClients) {
      final offsetFromBottom =
          _scrollController.position.maxScrollExtent - _scrollController.offset;
      // Mark as read only if within 150px of bottom
      if (offsetFromBottom > 150) {
        return; // still far from bottom
      }
    }
    final unreadIds = messages
        .where((m) => m.senderId != currentUserId && !m.isRead)
        .map((m) => m.id as String)
        .toList(growable: false);
    if (unreadIds.isNotEmpty) {
      // Send Matrix read receipts via FRB
      final me = ref.read(currentUserProvider);
      final other = widget.otherUserId ?? '';
      final roomId = await ref
              .read(chat_providers.chatServiceProvider)
              .getMatrixRoomIdForConversation(
                  conversationId: convId,
                  currentUserId: me?.id ?? '',
                  otherUserId: other) ??
          convId;
      for (final id in unreadIds) {
        try {
          await MatrixChatService.instance
              .markRead(roomId: roomId, eventId: id);
        } catch (_) {}
      }
      // Optimistically update local state so ticks appear immediately
      ref
          .read(conversationMessagesProvider(convId).notifier)
          .bulkMarkRead(unreadIds);
    }
  }

  void _onScrollVisibilityCheck() {
    if (_visibilityDebounce?.isActive ?? false) return;
    _visibilityDebounce = Timer(const Duration(milliseconds: 120), () {
      unawaited(_computeVisibleMessagesAndMarkRead());
    });
  }

  Future<void> _computeVisibleMessagesAndMarkRead() async {
    final convId = _currentConversationId ?? widget.conversationId;
    if (convId == 'new') return;
    final currentUserId = ref.read(currentUserProvider)?.id;
    if (currentUserId == null) return;
    final messages = ref
        .read(conversationMessagesProvider(convId))
        .maybeWhen(data: (m) => m, orElse: () => []);
    if (messages.isEmpty) return;
    final unreadToMark = <String>[];
    for (final msg in messages) {
      if (msg.senderId == currentUserId || msg.isRead) continue;
      final key = _messageKeys[msg.id];
      final ctx = key?.currentContext;
      if (ctx == null) continue;
      final renderObj = ctx.findRenderObject();
      if (renderObj is! RenderBox) continue;
      // Determine global position
      final offset = renderObj.localToGlobal(Offset.zero);
      final size = renderObj.size;
      final top = offset.dy;
      final bottom = top + size.height;
      final screenHeight = MediaQuery.of(ctx).size.height;
      final vpTop = 0.0;
      final vpBottom = screenHeight;
      final overlap = bottom > vpTop && top < vpBottom;
      if (!overlap) continue;
      final visibleTop = top.clamp(vpTop, vpBottom);
      final visibleBottom = bottom.clamp(vpTop, vpBottom);
      final visiblePortion = (visibleBottom - visibleTop) / size.height;
      if (visiblePortion >= 0.35 && !_readSent.contains(msg.id)) {
        unreadToMark.add(msg.id);
      }
    }
    if (unreadToMark.isNotEmpty) {
      final me = ref.read(currentUserProvider);
      final other = widget.otherUserId ?? '';
      final roomId = await ref
              .read(chat_providers.chatServiceProvider)
              .getMatrixRoomIdForConversation(
                  conversationId: convId,
                  currentUserId: me?.id ?? '',
                  otherUserId: other) ??
          convId;
      for (final id in unreadToMark) {
        try {
          await MatrixChatService.instance
              .markRead(roomId: roomId, eventId: id);
        } catch (_) {}
      }
      _readSent.addAll(unreadToMark);
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCards,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.chatOptions,
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    final me = ref.read(currentUserProvider);
                    final oid = widget.otherUserId;
                    final isBlocked = me != null &&
                        oid != null &&
                        me.blockedUsers.contains(oid);
                    if (isBlocked) {
                      return ListTile(
                        leading: Icon(Icons.lock_open,
                            color: AppColors.primaryAccent),
                        title: Text(AppLocalizations.of(context)!.unblockUser),
                        onTap: () {
                          Navigator.pop(context);
                          _unblockUser();
                        },
                      );
                    }
                    return ListTile(
                      leading: Icon(Icons.block, color: AppColors.error),
                      title: Text(AppLocalizations.of(context)!.blockUser),
                      onTap: () {
                        Navigator.pop(context);
                        _blockUser();
                      },
                    );
                  }),
                  ListTile(
                    leading: Icon(Icons.report, color: AppColors.warning),
                    title:
                        Text(AppLocalizations.of(context)!.reportConversation),
                    onTap: () {
                      Navigator.pop(context);
                      _reportConversation();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete, color: AppColors.error),
                    title:
                        Text(AppLocalizations.of(context)!.deleteConversation),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteConversation();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCards,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.upload,
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAttachmentOption(
                        icon: Icons.photo_library,
                        label: AppLocalizations.of(context)!.gallery,
                        color: AppColors.primaryAccent,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImageFromGallery();
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.camera_alt,
                        label: AppLocalizations.of(context)!.camera,
                        color: AppColors.success,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImageFromCamera();
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.attach_file,
                        label: AppLocalizations.of(context)!.document,
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.pop(context);
                          _pickDocument();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: AppColors.surfaceCards,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.emojis,
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _commonEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = _commonEmojis[index];
                  return GestureDetector(
                    onTap: () {
                      _messageController.text += emoji;
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateVoiceCall() async {
    try {
      // For demonstration, we'll use tel: URL to initiate a call
      // In a real app, you'd get the contact's phone number
      const phoneNumber = 'tel:+1234567890'; // This would be dynamic

      if (await canLaunchUrl(Uri.parse(phoneNumber))) {
        await launchUrl(Uri.parse(phoneNumber));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot make phone calls on this device'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initiating call: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.blockUser),
        content: Text(AppLocalizations.of(context)!.blockConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final me = ref.read(currentUserProvider);
              final other = widget.otherUserId;
              Navigator.of(context).pop();
              if (me?.id == null || other == null) return;
              try {
                await ref
                    .read(chat_providers.chatServiceProvider)
                    .blockUser(userId: me!.id, targetUserId: other);
                // Optimistically update currentUser provider
                final updated = me.copyWith(
                    blockedUsers: {...me.blockedUsers, other}.toList());
                ref.read(currentUserProvider.notifier).setUserModel(updated);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User blocked successfully'),
                    backgroundColor: AppColors.primaryAccent,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to block user: $e'),
                      backgroundColor: AppColors.error),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.block),
          ),
        ],
      ),
    );
  }

  void _unblockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.unblockUser),
        content: Text(AppLocalizations.of(context)!.unblockConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final me = ref.read(currentUserProvider);
              final other = widget.otherUserId;
              Navigator.of(context).pop();
              if (me?.id == null || other == null) return;
              try {
                await ref
                    .read(chat_providers.chatServiceProvider)
                    .unblockUser(userId: me!.id, targetUserId: other);
                // Optimistically update currentUser provider
                final updatedList = List<String>.from(me.blockedUsers)
                  ..remove(other);
                final updated = me.copyWith(blockedUsers: updatedList);
                ref.read(currentUserProvider.notifier).setUserModel(updated);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User unblocked successfully'),
                    backgroundColor: AppColors.primaryAccent,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to unblock user: $e'),
                      backgroundColor: AppColors.error),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.unblock),
          ),
        ],
      ),
    );
  }

  void _reportConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.reportConversation),
        content: Text(AppLocalizations.of(context)!.reportConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final me = ref.read(currentUserProvider);
              Navigator.of(context).pop();
              try {
                await ref
                    .read(chat_providers.chatServiceProvider)
                    .reportConversation(
                      conversationId:
                          _currentConversationId ?? widget.conversationId,
                      reporterId: me?.id ?? '',
                      reason: 'user_report',
                    );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conversation reported successfully'),
                    backgroundColor: AppColors.primaryAccent,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to report: $e'),
                      backgroundColor: AppColors.error),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.report),
          ),
        ],
      ),
    );
  }

  void _deleteConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteConversation),
        content:
            Text(AppLocalizations.of(context)!.deleteConversationConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final convId = _currentConversationId ?? widget.conversationId;
              try {
                await ref
                    .read(chat_providers.chatServiceProvider)
                    .deleteConversation(convId);
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conversation deleted successfully'),
                    backgroundColor: AppColors.primaryAccent,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: AppColors.error),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  void _pickImageFromGallery() async {
    try {
      final XFile? image =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _pendingImage = image;
          _pendingFile = null; // clear file if any
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _pickImageFromCamera() async {
    try {
      final XFile? image =
          await ImagePicker().pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          _pendingImage = image;
          _pendingFile = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        setState(() {
          _pendingFile = file;
          _pendingImage = null; // clear image if any
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending document: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // === Attachment helpers (preview & sending) ===
  Widget _buildAttachmentPreview() {
    final colors = ref.watch(dynamicColorsProvider);
    final isImage = _pendingImage != null;
    final fileName = isImage
        ? (_pendingImage!.name.isNotEmpty
            ? _pendingImage!.name
            : _pendingImage!.path.split(Platform.pathSeparator).last)
        : (_pendingFile?.name ?? '');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_pendingImage!.path),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: colors.borderLight,
                  child: const Icon(Icons.broken_image, size: 24),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.insert_drive_file, color: colors.primaryAccent),
            ),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      inherit: true),
                ),
                const SizedBox(height: 4),
                Text(
                  isImage
                      ? AppLocalizations.of(context)!.imageReadyToSend
                      : AppLocalizations.of(context)!.fileReadyToSend,
                  style: AppTypography.caption
                      .copyWith(color: colors.textSecondary, inherit: true),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: colors.textSecondary),
            onPressed: _sendingAttachment ? null : _clearPendingAttachment,
          ),
          IconButton(
            icon: Icon(Icons.cloud_upload, color: colors.primaryAccent),
            onPressed: _sendingAttachment
                ? null
                : () {
                    final currentUser = ref.read(currentUserProvider);
                    if (currentUser != null)
                      _sendPendingAttachment(currentUser.id);
                  },
          ),
        ],
      ),
    );
  }

  void _clearPendingAttachment() {
    setState(() {
      _pendingImage = null;
      _pendingFile = null;
    });
  }

  Future<void> _sendPendingAttachment(String currentUserId) async {
    if (_pendingImage == null && _pendingFile == null) return;
    final convId = _currentConversationId ?? widget.conversationId;
    if (convId == 'new') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseSendTextFirst)),
      );
      return;
    }
    setState(() {
      _sendingAttachment = true;
    });
    try {
      final chatService = ref.read(chat_providers.chatServiceProvider);
      ChatMessage? stored;
      if (_pendingImage != null) {
        _uploadProgress = 0.0;
        stored = await chatService.sendImage(
          conversationId: convId,
          senderId: currentUserId,
          fileName: _pendingImage!.name.isNotEmpty
              ? _pendingImage!.name
              : _pendingImage!.path.split(Platform.pathSeparator).last,
          imagePath: _pendingImage!.path,
          otherUserId: widget.otherUserId,
          ref: ref,
          onProgress: (p) {
            if (mounted)
              setState(() {
                _uploadProgress = p;
              });
          },
        );
      } else if (_pendingFile != null) {
        final f = _pendingFile!;
        _uploadProgress = 0.0;
        stored = await chatService.sendDocument(
          conversationId: convId,
          senderId: currentUserId,
          fileName: f.name,
          filePath: f.path ?? '',
          fileSize: f.size.toString(),
          otherUserId: widget.otherUserId,
          ref: ref,
          onProgress: (p) {
            if (mounted)
              setState(() {
                _uploadProgress = p;
              });
          },
        );
      }
      if (stored != null) {
        ref
            .read(conversationMessagesProvider(convId).notifier)
            .addOrReplace(stored);
      } else {
        ref.invalidate(conversationMessagesProvider(convId));
      }
      setState(() {
        _pendingImage = null;
        _pendingFile = null;
        _uploadProgress = null;
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Attachment failed: $e'),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingAttachment = false;
        });
      }
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Common emojis for quick access
  static const List<String> _commonEmojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '🤣',
    '😂',
    '🙂',
    '🙃',
    '😉',
    '😊',
    '😇',
    '😍',
    '🤩',
    '😘',
    '😗',
    '😚',
    '😋',
    '😛',
    '😝',
    '😜',
    '🤪',
    '🤨',
    '🧐',
    '🤓',
    '😎',
    '🤩',
    '😏',
    '😒',
    '😞',
    '😔',
    '😟',
    '😕',
    '🙁',
    '😣',
    '😖',
    '😫',
    '😩',
    '🥺',
    '😢',
    '😭',
    '😤',
    '😠',
    '😡',
    '🤬',
    '🤯',
    '😳',
    '🥵',
    '🥶',
    '😱',
    '😨',
    '😰',
    '😥',
    '😓',
    '🤗',
    '🤔',
    '🤭',
    '🤫',
    '🤥',
    '😶',
    '😐',
    '😑',
    '😬',
    '🙄',
    '😯',
    '😦',
    '😧',
    '😮',
    '😲',
    '🥱',
    '😴',
    '🤤',
    '😪',
    '😵',
    '🤐',
    '🥴',
    '🤢',
    '🤮',
    '🤧',
    '😷',
    '🤒',
    '🤕',
    '🤑',
    '🤠',
    '😈',
    '👿',
    '👹',
    '💀',
    '☠️',
    '👻',
    '👽',
    '👾',
    '🤖',
    '🎃',
    '😺',
    '😸',
    '😹',
    '😻',
    '😼',
    '😽',
    '🙀',
    '😿',
    '😾',
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🤎',
    '🖤',
    '🤍',
    '💔',
    '❣️',
    '💕',
    '💞',
    '💓',
    '💗',
    '💖',
    '💘',
    '💝',
    '💟',
    '👍',
    '👎',
    '👌',
    '🤏',
    '✌️',
  ];
}

// Lightweight wrapper so each message has a RenderObject with a GlobalKey for visibility calc.
class _MessageVisibilityWrapper extends StatelessWidget {
  final Widget child;
  const _MessageVisibilityWrapper({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return child;
  }
}
