import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/l10n/app_localizations.dart';
import '../providers/chat_preview_provider.dart';
import '../providers/conversations_provider.dart';
import '../../domain/models/conversation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/config/db_config.dart';
import '../../../home/presentation/models/dashboard_design.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../../core/theme/app_typography.dart';

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
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );
    final conversationsAsync = ref.watch(conversationsProvider);

    if (design == DashboardDesign.glass) {
      return _buildGlassScaffold(
        context: context,
        l10n: l10n,
        conversationsAsync: conversationsAsync,
      );
    }

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        title: Text(
          l10n.messages,
          style: AppTypography.pageTitle.copyWith(color: colors.textPrimary),
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
          _buildSearchBar(l10n: l10n),
          Expanded(
            child: _buildConversationList(conversationsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassScaffold({
    required BuildContext context,
    required AppLocalizations l10n,
    required AsyncValue<List<Conversation>> conversationsAsync,
  }) {
    return GlassPageScaffold(
      title: l10n.messages,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/address-book');
          },
          icon: const Icon(Icons.contacts_outlined, color: Colors.white),
        ),
      ],
      body: Column(
        children: [
          _buildSearchBar(l10n: l10n, glassMode: true),
          Expanded(
            child: _buildConversationList(
              conversationsAsync,
              glassMode: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar({
    required AppLocalizations l10n,
    bool glassMode = false,
  }) {
    final colors = ref.watch(dynamicColorsProvider);

    if (glassMode) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: TextFormField(
          initialValue: _searchQuery,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            icon: const Icon(Icons.search, color: Colors.black54),
            hintText: l10n.searchConversationsHint,
            border: InputBorder.none,
          ),
        ),
      );
    }

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
          hintText: l10n.searchConversationsHint,
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

  Widget _buildConversationList(
    AsyncValue<List<Conversation>> conversationsAsync, {
    bool glassMode = false,
  }) {
    final colors = ref.watch(dynamicColorsProvider);
    return conversationsAsync.when(
      data: (conversations) {
        final filteredConversations = _filterConversations(conversations);
        if (filteredConversations.isEmpty) {
          return _buildEmptyState(glassMode: glassMode);
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: glassMode ? 12 : 20),
          itemCount: filteredConversations.length,
          itemBuilder: (context, index) {
            final conversation = filteredConversations[index];
            final currentUser = ref.watch(currentUserProvider);
            final otherUserId =
                conversation.getOtherParticipantId(currentUser?.id ?? '');

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildConversationTile(
                context,
                conversation,
                otherUserId ?? '',
                currentUser?.id ?? '',
                glassMode: glassMode,
              ),
            );
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            glassMode ? Colors.white : colors.primaryAccent,
          ),
        ),
      ),
      error: (error, _) {
        final colors = ref.watch(dynamicColorsProvider);
        if (glassMode) {
          return Center(
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    '${AppLocalizations.of(context)!.errorLoadingConversations}: $error',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(conversationsProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.retry,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
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

  Widget _buildEmptyState({bool glassMode = false}) {
    final colors = ref.watch(dynamicColorsProvider);

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline,
                    size: 48, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No conversations found'
                    : 'No conversations yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _searchQuery.isNotEmpty
                    ? AppLocalizations.of(context)!.searchConversationsHint
                    : 'Start a conversation with your properties',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
    String currentUserId, {
    bool glassMode = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);
    final isLandlord = currentUser?.role == 'landlord';

    final otherUserName = conversation.getOtherParticipantDisplayName(
      currentUserId,
      isLandlord: isLandlord,
    );

    if (currentUser != null && otherUserId.isNotEmpty) {
      ref.read(chatPreviewProvider.notifier).ensureWatching(
            conversationId: conversation.id,
            currentUserId: currentUser.id,
            otherUserId: otherUserId,
            fallbackPreview: conversation.lastMessage,
          );
    }

    final previews = ref.watch(chatPreviewProvider);
    final override = previews[conversation.id]?.trim();
    final fallback = conversation.lastMessage.trim();
    final previewText = override != null && override.isNotEmpty
        ? override
        : (fallback.isNotEmpty ? fallback : l10n.noRecentMessages);

    final isBlocked =
        (currentUser?.blockedUsers ?? const <String>[]).contains(otherUserId);
    final isReported =
        (currentUser?.reportedUsers ?? const <String>[]).contains(otherUserId);
    final List<Widget> statusBadges = [];
    const Color reportedColor = Color(0xFFFF6B6B);
    if (isBlocked) {
      statusBadges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.blockedLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }
    if (isReported) {
      statusBadges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: reportedColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: reportedColor.withValues(alpha: 0.55),
              width: 0.6,
            ),
          ),
          child: Text(
            l10n.reported,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }
    if (glassMode) {
      final textPrimary = Colors.black.withValues(alpha: 0.85);
      final textSecondary = Colors.black.withValues(alpha: 0.65);
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            final avatar = conversation.getOtherParticipantAvatarRef() ??
                (otherUserId.isNotEmpty
                    ? '${DbConfig.apiUrl}/users/$otherUserId/profile-image'
                    : '');
            context.push(
                '/chat/${conversation.id}?otherUserId=$otherUserId&otherUser=${Uri.encodeComponent(otherUserName)}&otherAvatar=${Uri.encodeComponent(avatar)}');
          },
          child: Row(
            children: [
              UserAvatar(
                imageRef: conversation.getOtherParticipantAvatarRef() ??
                    (otherUserId.isNotEmpty
                        ? '${DbConfig.apiUrl}/users/$otherUserId/profile-image'
                        : null),
                name: otherUserName,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherUserName,
                            style: GoogleFonts.poppins(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          conversation.lastMessageTime.toString(),
                          style: GoogleFonts.poppins(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (statusBadges.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: statusBadges,
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (conversation.propertyAddress != 'Unknown Property')
                      Text(
                        conversation.propertyAddress,
                        style: GoogleFonts.poppins(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Text(
                      previewText,
                      style: GoogleFonts.poppins(
                        color: Colors.black.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.black54),
            ],
          ),
        ),
      );
    }

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
            if (statusBadges.isNotEmpty) ...[
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: statusBadges,
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
              previewText,
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
