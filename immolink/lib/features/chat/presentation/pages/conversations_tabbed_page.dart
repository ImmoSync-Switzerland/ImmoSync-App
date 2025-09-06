import 'package:flutter/material.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/conversations_provider.dart';
import '../providers/invitation_provider.dart';
import '../providers/chat_preview_provider.dart';
import '../../domain/models/conversation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../widgets/invitation_card.dart';
import '../widgets/property_email_invite_dialog.dart';
import '../../../../core/widgets/user_avatar.dart';

class ConversationsTabbedPage extends ConsumerStatefulWidget {
  const ConversationsTabbedPage({super.key});

  @override
  ConsumerState<ConversationsTabbedPage> createState() =>
      _ConversationsTabbedPageState();
}

class _ConversationsTabbedPageState
    extends ConsumerState<ConversationsTabbedPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Add listener to rebuild when tab changes
    _tabController.addListener(() {
      setState(() {});
    });

    // Set navigation index to Messages (2) when this page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeAwareNavigationProvider.notifier).setIndex(2);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isLandlord = currentUser?.role == 'landlord';

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        title: Text(
          l10n.messages,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            inherit: true,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textSecondary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: colors.surfaceCards,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.contacts_outlined,
                  color: colors.primaryAccent, size: 22),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/address-book');
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primaryAccent,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primaryAccent,
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            inherit: true,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            inherit: true,
          ),
          tabs: [
            Tab(text: l10n.messages),
            Tab(text: l10n.invitations),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
      floatingActionButton: isLandlord && _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showInviteTenantDialog(),
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: Text(l10n.addTenant),
            )
          : null,
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMessagesTab(),
                _buildInvitationsTab(),
              ],
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
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colors.shadowColorMedium,
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchConversationsHint,
          hintStyle: TextStyle(
            color: colors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            inherit: true,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_outlined,
              color: colors.textSecondary,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
          inherit: true,
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    final conversationsAsync = ref.watch(conversationsProvider);
    final colors = ref.watch(dynamicColorsProvider);

    return conversationsAsync.when(
      data: (conversations) {
        final filteredConversations = _filterConversations(conversations);
        if (filteredConversations.isEmpty) {
          return _buildEmptyState('No conversations yet',
              'Start chatting with your tenants or landlord');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
              ),
            );
          },
        );
      },
      loading: () => Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildInvitationsTab() {
    final currentUser = ref.watch(currentUserProvider);
    final invitationsAsync = ref.watch(userInvitationsProvider);
    final colors = ref.watch(dynamicColorsProvider);

    return invitationsAsync.when(
      data: (invitations) {
        // Filter invitations based on user role
        final filteredInvitations = invitations.where((invitation) {
          if (currentUser?.role == 'landlord') {
            return invitation.landlordId == currentUser!.id;
          } else {
            return invitation.tenantId == currentUser!.id;
          }
        }).toList();

        if (filteredInvitations.isEmpty) {
          return _buildEmptyState(
            currentUser?.role == 'landlord'
                ? 'No invitations sent'
                : 'No invitations received',
            currentUser?.role == 'landlord'
                ? 'Send invitations to potential tenants'
                : 'Wait for landlord invitations',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredInvitations.length,
          itemBuilder: (context, index) {
            final invitation = filteredInvitations[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InvitationCard(
                invitation: invitation,
                isLandlord: currentUser?.role == 'landlord',
              ),
            );
          },
        );
      },
      loading: () => Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildConversationTile(BuildContext context, Conversation conversation,
      String otherUserId, String currentUserId) {
    final colors = ref.watch(dynamicColorsProvider);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final avatar = conversation.otherParticipantAvatar ?? '';
        context.push(
          '/chat/${conversation.id}?otherUser=${Uri.encodeComponent(conversation.otherParticipantName ?? 'Unknown User')}&otherUserId=$otherUserId&otherAvatar=${Uri.encodeComponent(avatar)}',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: colors.shadowColorMedium,
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            UserAvatar(
              imageRef: conversation.otherParticipantAvatar,
              name: conversation.otherParticipantName,
              size: 56,
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
                          conversation.otherParticipantName ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            letterSpacing: -0.2,
                            inherit: true,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _getTimeAgo(conversation.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                          inherit: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (() {
                      final previews = ref.read(chatPreviewProvider);
                      final override = previews[conversation.id];
                      if (override != null && override.isNotEmpty) return override;
                      if (conversation.lastMessage == '[encrypted]') return 'Encrypted message';
                      return conversation.lastMessage;
                    })(),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                      letterSpacing: -0.1,
                      inherit: true,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    final colors = ref.watch(dynamicColorsProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              letterSpacing: -0.4,
              inherit: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              inherit: true,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final colors = ref.watch(dynamicColorsProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.error),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.somethingWentWrong,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              inherit: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.pleaseTryAgainLater,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              inherit: true,
            ),
          ),
        ],
      ),
    );
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) return conversations;

    return conversations.where((conversation) {
      final searchInName = conversation.otherParticipantName
              ?.toLowerCase()
              .contains(_searchQuery) ??
          false;
      final searchInMessage =
          conversation.lastMessage.toLowerCase().contains(_searchQuery);
      return searchInName || searchInMessage;
    }).toList();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showInviteTenantDialog() {
    final currentUser = ref.read(currentUserProvider);
    final colors = ref.read(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.error),
          backgroundColor: colors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => PropertyEmailInviteDialog(
        landlordId: currentUser.id,
      ),
    );
  }
}
