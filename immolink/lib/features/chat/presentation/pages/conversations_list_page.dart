import 'package:flutter/material.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_preview_provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/conversations_provider.dart';
import '../../domain/models/conversation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/config/db_config.dart';

class ConversationsListPage extends ConsumerStatefulWidget {
  const ConversationsListPage({super.key});

  @override
  ConsumerState<ConversationsListPage> createState() =>
      _ConversationsListPageState();
}

class _ConversationsListPageState extends ConsumerState<ConversationsListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Set navigation index to Messages (2) when this page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeAwareNavigationProvider.notifier).setIndex(2);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        title: Text(
          l10n.messages,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.contacts_outlined, color: colors.primaryAccent),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/address-book');
            },
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNav(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                final filteredConversations =
                    _filterConversations(conversations);
                if (filteredConversations.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = filteredConversations[index];
                    final currentUser = ref.watch(currentUserProvider);
                    final otherUserId = conversation
                        .getOtherParticipantId(currentUser?.id ?? '');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildConversationTile(
                        context,
                        conversation,
                        otherUserId ?? '',
                        currentUser?.id ?? '',
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) {
                final colors = ref.watch(dynamicColorsProvider);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colors.error),
                      const SizedBox(height: 16),
                      Text(
                          '${AppLocalizations.of(context)!.errorLoadingConversations}: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(conversationsProvider),
                        child: Text(AppLocalizations.of(context)!.retry),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final colors = ref.watch(dynamicColorsProvider);
    
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(
            color: colors.textTertiary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_outlined,
              color: colors.primaryAccent,
              size: 20,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colors.textTertiary,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) {
      return conversations;
    }

    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id ?? '';
    final isLandlord = currentUser?.role == 'landlord';

    return conversations.where((conversation) {
      final searchLower = _searchQuery.toLowerCase();

      // Get the other participant's name for searching
      final otherUserName = conversation
          .getOtherParticipantDisplayName(
            currentUserId,
            isLandlord: isLandlord,
          )
          .toLowerCase();

      // Search in multiple fields
      return conversation.propertyAddress.toLowerCase().contains(searchLower) ||
          conversation.lastMessage.toLowerCase().contains(searchLower) ||
          otherUserName.contains(searchLower) ||
          (conversation.otherParticipantEmail
                  ?.toLowerCase()
                  .contains(searchLower) ??
              false);
    }).toList();
  }

  Widget _buildEmptyState() {
    final colors = ref.watch(dynamicColorsProvider);
    
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
                  colors.primaryAccent.withValues(alpha: 0.1),
                  colors.primaryAccent.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No conversations found'
                : 'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Start a conversation with your properties',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    String otherUserId,
    String currentUserId,
  ) {
    final currentUser = ref.watch(currentUserProvider);
    final isLandlord = currentUser?.role == 'landlord';

    final otherUserName = conversation.getOtherParticipantDisplayName(
      currentUserId,
      isLandlord: isLandlord,
    );

    final isBlocked =
        (currentUser?.blockedUsers ?? const <String>[]).contains(otherUserId);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.95),
            const Color(0xFF8B5CF6).withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        leading: UserAvatar(
          imageRef: conversation.getOtherParticipantAvatarRef() ??
              (otherUserId.isNotEmpty
                  ? '${DbConfig.apiUrl}/users/$otherUserId/profile-image'
                  : null),
          name: otherUserName,
          size: 52,
          fallbackToCurrentUser: false,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUserName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isBlocked) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocalizations.of(context)!.blockedLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (conversation.propertyAddress != 'Unknown Property') ...[
              Text(
                'Property: ${conversation.propertyAddress}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 4),
            Text(
              (() {
                // Ensure preview watcher for this conversation is active (Matrix timelines)
                final me = ref.read(currentUserProvider);
                if (me != null && otherUserId.isNotEmpty) {
                  // fire-and-forget
                  ref.read(chatPreviewProvider.notifier).ensureWatching(
                      conversationId: conversation.id,
                      currentUserId: me.id,
                      otherUserId: otherUserId);
                }
                final previews = ref.read(chatPreviewProvider);
                final override = previews[conversation.id];
                if (override != null && override.isNotEmpty) return override;
                // Treat empty content from aggregation as encrypted/no-preview
                final lm = (conversation.lastMessage).toString().trim();
                if (lm.isEmpty || lm == '[encrypted]')
                  return 'Encrypted message';
                return lm;
              })(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              conversation.lastMessageTime.toString(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 16,
          ),
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          final avatar = conversation.getOtherParticipantAvatarRef() ??
              (otherUserId.isNotEmpty
                  ? '${DbConfig.apiUrl}/users/$otherUserId/profile-image'
                  : '');
          context.push(
              '/chat/${conversation.id}?otherUserId=$otherUserId&otherUser=${Uri.encodeComponent(otherUserName)}&otherAvatar=${Uri.encodeComponent(avatar)}');
        },
      ),
    );
  }
}
