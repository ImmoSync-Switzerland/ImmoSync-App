import 'package:flutter/material.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/chat/domain/models/chat_message.dart';
import 'package:immosync/features/chat/presentation/providers/messages_provider.dart';
import 'package:immosync/features/chat/presentation/providers/chat_service_provider.dart' as chat_providers;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/presence/presence_ws_service.dart';
import '../../../../core/presence/presence_cache.dart';
import '../../../../core/config/db_config.dart';

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

class _ChatPageState extends ConsumerState<ChatPage> with TickerProviderStateMixin {
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
  int _wsConnectAttempts = 0;

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
  _initPresenceLayer();
  _initChatWsListener();
  // Attempt initial read marking shortly after build
  WidgetsBinding.instance.addPostFrameCallback((_) => _emitReadReceipts());
  // Attach scroll listener for fine-grained visibility based read detection
  _scrollController.addListener(_onScrollVisibilityCheck);
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
    super.dispose();
  }

  // polling removed

  void _initPresenceLayer() {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser?.id;
    print('[ChatPage][_initPresenceLayer] userId=$userId');
    if (userId != null && userId.isNotEmpty) {
      void tryConnect() {
        final token = ref.read(authProvider).sessionToken;
        print('[ChatPage][tryConnect] attempt=$_wsConnectAttempts token=${token != null}');
        if (token != null) {
          ref.read(presenceWsServiceProvider).connect(userId: userId, token: token);
          _authConnSub?.close();
          _authConnSub = null;
          _wsConnectRetry?.cancel();
          // After short delay, dump debug status
          Future.delayed(const Duration(seconds:1), () {
            if (mounted) {
              ref.read(presenceWsServiceProvider).debugStatus();
            }
          });
        }
      }
      // Attempt now (post frame) and if token not yet ready, listen for it
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tryConnect();
        if (_authConnSub == null && ref.read(authProvider).sessionToken == null) {
          _authConnSub = ref.listenManual(authProvider, (prev, next) {
            if (mounted) tryConnect();
          });
        }
      });
      // Also start a periodic retry (in case listenManual misses initial change)
      _wsConnectRetry = Timer.periodic(const Duration(seconds: 2), (t) {
        _wsConnectAttempts++;
        if (_wsConnectAttempts > 10) { t.cancel(); return; }
        // Just attempt; PresenceWsService internally ignores duplicate connects
        tryConnect();
      });
      // Fallback REST heartbeat every 45s (server also gets WS pings)
      _presenceTimer = Timer.periodic(const Duration(seconds: 45), (_) => _sendHeartbeat());
      _sendHeartbeat();
    }
    // Listen to presence cache for other user updates (manual listen allowed outside build)
    _presenceCacheRemove = ref.listenManual<Map<String, PresenceInfo>>(presenceCacheProvider, (prev, next) {
      final oid = widget.otherUserId;
      if (oid != null && next.containsKey(oid)) {
        final info = next[oid]!;
        if (mounted) {
          setState(() {
            _otherOnline = info.online;
            _otherLastSeen = info.lastSeen;
          });
        }
      }
    });
    // Initial fetch for other user (HTTP fallback)
    _fetchOtherStatus();
  }

  void _initChatWsListener() {
    final ws = ref.read(presenceWsServiceProvider);
    ws.chatStream.listen((data) {
      final type = data['type'];
      final convId = _currentConversationId ?? widget.conversationId;
      final notifier = ref.read(conversationMessagesProvider(convId).notifier);
      if (type == 'message') {
        notifier.applyWsMessage(data, isAck: false);
      } else if (type == 'ack') {
        notifier.applyWsMessage(data, isAck: true);
      } else if (type == 'delivered' || type == 'read') {
        notifier.applyDeliveryOrRead(data);
      } else if (type == 'typing') {
        if (data['conversationId'] == convId && data['userId'] != ref.read(currentUserProvider)?.id) {
          setState(() { _otherTyping = data['isTyping'] == true; });
        }
      } else if (type == 'error') {
        // Handle chat errors (e.g., database unavailable)
        final errorMessage = data['message'] ?? 'Chat error occurred';
        print('[ChatPage] Chat error: $type - $errorMessage');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat error: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (type == 'read') {
        // optional: future read receipt UI updates
      }
      // Auto-scroll on new messages
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
    ws.conversationStream.listen((data) {
      if (data['type'] == 'createAck') {
        final conv = data['conversation'];
        final newId = conv?['_id']?.toString();
        if (newId != null) {
          setState(() { _currentConversationId = newId; });
          // Replace route to bind to provider keyed by new ID
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  conversationId: newId,
                  otherUserName: widget.otherUserName,
                  otherUserAvatar: widget.otherUserAvatar,
                  otherUserId: widget.otherUserId,
                ),
              ),
            );
          });
        }
      }
    });
  }

  Future<void> _sendHeartbeat() async {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser?.id;
    if (userId == null || userId.isEmpty) return;
    try {
      // Assuming same base API used elsewhere
  final baseUrl = DbConfig.apiUrl;
  await http.post(Uri.parse('$baseUrl/users/$userId/heartbeat'));
    } catch (_) {}
  }

  Future<void> _fetchOtherStatus() async {
    if (widget.otherUserId == null || widget.otherUserId!.isEmpty) return;
    try {
  final baseUrl = DbConfig.apiUrl;
  final resp = await http.get(Uri.parse('$baseUrl/users/online-status?ids=${widget.otherUserId}'));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final map = data['statuses'] as Map<String, dynamic>;
        final entry = map[widget.otherUserId];
        if (entry != null) {
          setState(() {
            _otherOnline = entry['online'] == true;
            final ls = entry['lastSeen'];
            _otherLastSeen = ls != null ? DateTime.tryParse(ls) : null;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(conversationMessagesProvider(widget.conversationId));
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
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessagesList(messages, currentUser?.id ?? ''),
              loading: () => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colors.error),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.failedToLoadImage, // TODO: replace with dedicated failedToLoadMessages key
                      style: AppTypography.subhead.copyWith(
                        color: colors.error,
                        inherit: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(conversationMessagesProvider(widget.conversationId)),
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
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.primaryAccent.withValues(alpha: 0.1),
            backgroundImage: widget.otherUserAvatar != null 
                ? NetworkImage(widget.otherUserAvatar!) 
                : null,
            child: widget.otherUserAvatar == null
                ? Text(
                    widget.otherUserName.isNotEmpty 
                        ? widget.otherUserName[0].toUpperCase() 
                        : 'U',
                    style: AppTypography.subhead.copyWith(
                      color: colors.primaryAccent,
                      fontWeight: FontWeight.w600,
                      inherit: true,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: AppTypography.subhead.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    inherit: true,
                  ),
                ),
                if (_otherTyping)
                  Text(
                    'typing...',
                    style: AppTypography.caption.copyWith(
                      color: colors.primaryAccent,
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
                          color: _otherOnline ? Colors.green : colors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        _otherOnline ? 'Online' : _formatLastSeen(),
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
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
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primaryAccent.withValues(alpha: 0.1),
              child: Text(
                widget.otherUserName[0].toUpperCase(),
                style: TextStyle(
                  color: colors.primaryAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  inherit: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primaryAccent,
                          colors.primaryAccent.withValues(alpha: 0.8),
                        ],
                      )
                    : null,
                color: isMe ? null : colors.surfaceCards,
                borderRadius: BorderRadius.circular(18),
                border: isMe ? null : Border.all(
                  color: colors.borderLight,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((message.deliveredAt != null || message.readAt != null) && message.content == '[encrypted]')
                        const SizedBox.shrink(),
                      if (message.content == '[encrypted]') ...[
                        Icon(Icons.lock, size: 14, color: isMe ? Colors.white70 : colors.textSecondary),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          message.content,
                          style: AppTypography.body.copyWith(
                            color: isMe ? Colors.white : colors.textPrimary,
                            inherit: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: AppTypography.caption.copyWith(
                      color: isMe 
                          ? Colors.white.withValues(alpha: 0.7)
                          : colors.textTertiary,
                      inherit: true,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.readAt != null ? Icons.done_all : (message.deliveredAt != null ? Icons.check : Icons.access_time),
                      size: 14,
                      color: message.readAt != null
                          ? Colors.lightBlueAccent
                          : (message.deliveredAt != null ? Colors.white70 : Colors.white38),
                    )
                  ]
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primaryAccent.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                color: colors.primaryAccent,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildMessageInput(String currentUserId) {
    final colors = ref.watch(dynamicColorsProvider);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.horizontalPadding),
      decoration: BoxDecoration(
        color: colors.primaryBackground,
        border: Border(
          top: BorderSide(
            color: colors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                // Attachment button
                IconButton(
                  icon: Icon(
                    Icons.attach_file,
                    color: colors.textSecondary,
                    size: 24,
                  ),
                  onPressed: () => _showAttachmentOptions(),
                ),
                // Emoji button
                IconButton(
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: colors.textSecondary,
                    size: 24,
                  ),
                  onPressed: () => _showEmojiPicker(),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colors.surfaceCards,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colors.borderLight,
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                        inherit: true,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.typeAMessage,
                        hintStyle: AppTypography.body.copyWith(
                          color: colors.textTertiary,
                          inherit: true,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (text) {
                        setState(() {
                          _isTyping = text.isNotEmpty;
                          final convId = _currentConversationId;
                          if (convId != null && convId != 'new') {
                            ref.read(presenceWsServiceProvider).sendTyping(conversationId: convId, isTyping: true);
                            // Schedule stop typing after debounce
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted && _isTyping == false) {
                                ref.read(presenceWsServiceProvider).sendTyping(conversationId: convId, isTyping: false);
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
                    if (_messageController.text.trim().isNotEmpty) {
                      _sendMessage(currentUserId);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primaryAccent,
                          colors.primaryAccent.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primaryAccent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
      
      print('Sending message with senderId: $realSenderId, otherUserId: ${widget.otherUserId}');

      final convId = _currentConversationId ?? widget.conversationId;
      if (convId == 'new') {
        ref.read(presenceWsServiceProvider).createConversation(
          otherUserId: widget.otherUserId ?? '',
          initialMessage: content,
        );
      } else {
        final ws = ref.read(presenceWsServiceProvider);
        final optimistic = ChatMessage(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          senderId: realSenderId,
          receiverId: widget.otherUserId ?? '',
          content: content,
          timestamp: DateTime.now(),
        );
        ref.read(conversationMessagesProvider(convId).notifier).addOptimisticMessage(optimistic);
  ws.sendChatMessage(conversationId: convId, content: content, receiverId: widget.otherUserId, ref: ref);
      }
      
  _scrollToBottom();
    } catch (error) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nachricht konnte nicht gesendet werden: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    _emitReadReceipts();
  }

  void _emitReadReceipts() {
    final convId = _currentConversationId ?? widget.conversationId;
    if (convId == 'new') return;
    final currentUserId = ref.read(currentUserProvider)?.id;
    if (currentUserId == null) return;
    final messagesAsync = ref.read(conversationMessagesProvider(convId));
    final messages = messagesAsync.maybeWhen(data: (m) => m, orElse: () => []);
    if (messages.isEmpty) return;
    // Determine visible: if scrolled near bottom treat all as viewed.
    if (_scrollController.hasClients) {
      final offsetFromBottom = _scrollController.position.maxScrollExtent - _scrollController.offset;
      if (offsetFromBottom > 150) return; // not near bottom yet
    }
  final unreadIds = messages
    .where((m) => m.senderId != currentUserId && !m.isRead)
    .map((m) => m.id as String)
    .toList(growable: false);
  if (unreadIds.isNotEmpty) {
    ref.read(presenceWsServiceProvider).markAllRead(conversationId: convId, messageIds: List<String>.from(unreadIds));
    }
  }

  void _onScrollVisibilityCheck() {
    if (_visibilityDebounce?.isActive ?? false) return;
    _visibilityDebounce = Timer(const Duration(milliseconds: 120), _computeVisibleMessagesAndMarkRead);
  }

  void _computeVisibleMessagesAndMarkRead() {
    final convId = _currentConversationId ?? widget.conversationId;
    if (convId == 'new') return;
    final currentUserId = ref.read(currentUserProvider)?.id;
    if (currentUserId == null) return;
    final messages = ref.read(conversationMessagesProvider(convId)).maybeWhen(data: (m)=>m, orElse: ()=>[]);
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
      ref.read(presenceWsServiceProvider).markAllRead(conversationId: convId, messageIds: unreadToMark);
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
                children: [                  Text(
                    'Chat Options',
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.block, color: AppColors.error),
                    title: Text(AppLocalizations.of(context)!.blockUser),
                    onTap: () {
                      Navigator.pop(context);
                      _blockUser();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.report, color: AppColors.warning),
                    title: Text(AppLocalizations.of(context)!.reportConversation),
                    onTap: () {
                      Navigator.pop(context);
                      _reportConversation();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete, color: AppColors.error),
                    title: Text(AppLocalizations.of(context)!.deleteConversation),
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
                    'Send Attachment',
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
                        label: 'Gallery',
                        color: AppColors.primaryAccent,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImageFromGallery();
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        color: AppColors.success,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImageFromCamera();
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.attach_file,
                        label: 'Document',
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
                    'Emojis',
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
        title: const Text('Block User'),
        content: const Text('Are you sure you want to block this user? You will no longer receive messages from them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement block user functionality
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User blocked successfully'),
                  backgroundColor: AppColors.primaryAccent,
                ),
              );
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _reportConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Conversation'),
        content: const Text('Are you sure you want to report this conversation? Our support team will review it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement report functionality
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation reported successfully'),
                  backgroundColor: AppColors.primaryAccent,
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _deleteConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement delete conversation functionality
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation deleted successfully'),
                  backgroundColor: AppColors.primaryAccent,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _pickImageFromGallery() async {
    try {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected: ${image.name}'),
            backgroundColor: AppColors.primaryAccent,
          ),
        );
        // Here you would normally send the image
        // await _chatService.sendImage(image);
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
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
      
      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo taken: ${image.name}'),
            backgroundColor: AppColors.primaryAccent,
          ),
        );
        // Here you would normally send the image
        // await _chatService.sendImage(image);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sending document: ${file.name}'),
            backgroundColor: AppColors.primaryAccent,
          ),
        );
        
        // Send the document
        final chatService = ref.read(chat_providers.chatServiceProvider);
        final currentUser = ref.read(currentUserProvider);
        
        if (currentUser != null) {
          await chatService.sendDocument(
            conversationId: widget.conversationId,
            senderId: currentUser.id,
            fileName: file.name,
            filePath: file.path ?? '',
            fileSize: file.size.toString(),
            otherUserId: widget.otherUserId,
            ref: ref,
          );
          
          // Refresh messages
          ref.invalidate(conversationMessagesProvider(widget.conversationId));
        }
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
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '🙂', '🙃', '😉', '😊', '😇', '😍', '🤩', '😘',
    '😗', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨',
    '🧐', '🤓', '😎', '🤩', '😏', '😒', '😞', '😔',
    '😟', '😕', '🙁', '😣', '😖', '😫', '😩', '🥺',
    '😢', '😭', '😤', '😠', '😡', '🤬', '🤯', '😳',
    '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗',
    '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬',
    '🙄', '😯', '😦', '😧', '😮', '😲', '🥱', '😴',
    '🤤', '😪', '😵', '🤐', '🥴', '🤢', '🤮', '🤧',
    '😷', '🤒', '🤕', '🤑', '🤠', '😈', '👿', '👹',
    '💀', '☠️', '👻', '👽', '👾', '🤖', '🎃', '😺',
    '😸', '😹', '😻', '😼', '😽', '🙀', '😿', '😾',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🤎', '🖤',
    '🤍', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
    '💘', '💝', '💟', '👍', '👎', '👌', '🤏', '✌️',
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

