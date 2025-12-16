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
import '../../../home/presentation/models/dashboard_design.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart';
import '../../../settings/providers/settings_provider.dart';

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
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _slideAnimation;
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

    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController?.dispose();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeOut));

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeOut));

    _animationController!.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final bool isLandlord = (currentUser?.role ?? '') == 'landlord';
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );
    final bool glassMode = design == DashboardDesign.glass;

    final Color refreshColor = glassMode ? Colors.white : colors.textPrimary;
    final Color addressBookColor =
        glassMode ? Colors.white : colors.primaryAccent;

    final Widget refreshAction = IconButton(
      icon: Icon(Icons.refresh_rounded, color: refreshColor),
      tooltip: l10n.refresh,
      onPressed: _handleRefresh,
    );

    final Widget addressBookAction = IconButton(
      icon: Icon(Icons.contacts_outlined, color: addressBookColor),
      tooltip: l10n.searchContacts,
      onPressed: () {
        HapticFeedback.lightImpact();
        context.push('/address-book');
      },
    );

    final Widget? floatingActionButton = isLandlord && _tabController.index == 1
        ? _buildInviteFab(glassMode: glassMode, l10n: l10n)
        : null;

    final body = _buildBody(glassMode: glassMode, l10n: l10n);

    if (glassMode) {
      return GlassPageScaffold(
        title: l10n.messages,
        actions: [
          refreshAction,
          addressBookAction,
        ],
        floatingActionButton: floatingActionButton,
        body: body,
      );
    }

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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          refreshAction,
          IconButton(
            icon: Icon(
              Icons.contacts_outlined,
              color: colors.primaryAccent,
            ),
            tooltip: l10n.searchContacts,
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/address-book');
            },
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNav(),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: body),
    );
  }

  Widget _buildBody({
    required bool glassMode,
    required AppLocalizations l10n,
  }) {
    final EdgeInsetsGeometry padding =
        glassMode ? EdgeInsets.zero : const EdgeInsets.fromLTRB(20, 16, 20, 8);

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(glassMode: glassMode, l10n: l10n),
        const SizedBox(height: 16),
        _buildTabSwitcher(glassMode: glassMode, l10n: l10n),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildMessagesTab(glassMode: glassMode, l10n: l10n),
              _buildInvitationsTab(glassMode: glassMode, l10n: l10n),
            ],
          ),
        ),
      ],
    );

    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        final double opacity = _fadeAnimation?.value ?? 1.0;
        final double translateY = _slideAnimation?.value ?? 0.0;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: padding,
        child: content,
      ),
    );
  }

  Widget _buildTabSwitcher({
    required bool glassMode,
    required AppLocalizations l10n,
  }) {
    final colors = ref.watch(dynamicColorsProvider);
    final tabs = [
      Tab(text: l10n.messages),
      Tab(text: l10n.invitations),
    ];
    const labelStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 14,
    );
    const unselectedLabelStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );

    if (glassMode) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.white.withValues(alpha: 0.25),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: tabs,
              indicatorSize: TabBarIndicatorSize.tab,
              splashBorderRadius: BorderRadius.circular(14),
              dividerColor: Colors.transparent,
              labelStyle: labelStyle,
              unselectedLabelStyle: unselectedLabelStyle,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceWithElevation(1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: colors.primaryAccent.withValues(alpha: 0.1),
        ),
        child: TabBar(
          controller: _tabController,
          tabs: tabs,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: labelStyle,
          unselectedLabelStyle: unselectedLabelStyle,
          labelColor: colors.primaryAccent,
          unselectedLabelColor: colors.textSecondary,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colors.primaryAccent.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar({
    required bool glassMode,
    required AppLocalizations l10n,
  }) {
    final colors = ref.watch(dynamicColorsProvider);
    final InputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    final Widget textField = TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: l10n.searchConversationsHint,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: glassMode ? Colors.white : colors.primaryAccent,
          size: 20,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.8)
                      : colors.textSecondary,
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
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: TextStyle(
        color: glassMode ? Colors.white : colors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        inherit: true,
      ),
    );

    if (glassMode) {
      return GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: textField,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceWithElevation(1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: textField,
    );
  }

  Widget _buildMessagesTab({
    required bool glassMode,
    required AppLocalizations l10n,
  }) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final colors = ref.watch(dynamicColorsProvider);

    return conversationsAsync.when(
      data: (conversations) {
        final filteredConversations = _filterConversations(conversations);
        if (filteredConversations.isEmpty) {
          return _buildEmptyState(
            title: l10n.noConversationsYet,
            subtitle: l10n.startConversation,
            glassMode: glassMode,
          );
        }
        return ListView.builder(
          padding: EdgeInsets.only(
            top: 4,
            bottom: glassMode ? 160 : 120,
          ),
          itemCount: filteredConversations.length,
          itemBuilder: (context, index) {
            final conversation = filteredConversations[index];
            final currentUser = ref.watch(currentUserProvider);
            final otherUserId =
                conversation.getOtherParticipantId(currentUser?.id ?? '');

            return Padding(
              padding: EdgeInsets.only(
                bottom: 12,
                left: glassMode ? 0 : 4,
                right: glassMode ? 0 : 4,
              ),
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
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (error, stack) => _buildErrorState(glassMode: glassMode),
    );
  }

  Widget _buildInvitationsTab({
    required bool glassMode,
    required AppLocalizations l10n,
  }) {
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
          final bool landlord = currentUser?.role == 'landlord';
          return _buildEmptyState(
            title: l10n.noResultsFound,
            subtitle:
                landlord ? l10n.inviteTenant : l10n.contactLandlordForAccess,
            glassMode: glassMode,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(
            top: 4,
            bottom: glassMode ? 160 : 120,
          ),
          itemCount: filteredInvitations.length,
          itemBuilder: (context, index) {
            final invitation = filteredInvitations[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: 12,
                left: glassMode ? 0 : 4,
                right: glassMode ? 0 : 4,
              ),
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
      error: (error, stack) => _buildErrorState(glassMode: glassMode),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    String otherUserId,
    String currentUserId, {
    required bool glassMode,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    final me = ref.watch(currentUserProvider);
    if (me != null && otherUserId.isNotEmpty) {
      ref.read(chatPreviewProvider.notifier).ensureWatching(
            conversationId: conversation.id,
            currentUserId: me.id,
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
        (me?.blockedUsers ?? const <String>[]).contains(otherUserId);
    final isReported =
        (me?.reportedUsers ?? const <String>[]).contains(otherUserId);
    final borderColor = isReported
        ? colors.error
        : isBlocked
            ? colors.warning
            : glassMode
                ? colors.borderLight.withValues(alpha: 0.5)
                : colors.borderLight;
    final List<Widget> statusBadges = [];
    if (isBlocked) {
      statusBadges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.warning, width: 0.5),
          ),
          child: Text(
            l10n.blockedLabel,
            style: TextStyle(
              color: colors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              inherit: true,
            ),
          ),
        ),
      );
    }
    if (isReported) {
      statusBadges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.error, width: 0.5),
          ),
          child: Text(
            l10n.reported,
            style: TextStyle(
              color: colors.error,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              inherit: true,
            ),
          ),
        ),
      );
    }

    final Color titleColor = glassMode ? Colors.white : colors.textPrimary;
    final Color subtitleColor =
        glassMode ? Colors.white.withValues(alpha: 0.85) : colors.textSecondary;
    final Color timeColor =
        glassMode ? Colors.white.withValues(alpha: 0.75) : colors.textSecondary;
    final BoxDecoration decoration = glassMode
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surfaceCards,
                colors.luxuryGradientStart.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: colors.primaryAccent.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
            ],
            border: Border.all(color: borderColor, width: 1),
          )
        : BoxDecoration(
            color: colors.surfaceWithElevation(1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          );

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
        decoration: decoration,
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
                            color: titleColor,
                            letterSpacing: -0.2,
                            inherit: true,
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
                      Text(
                        _getTimeAgo(conversation.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: timeColor,
                          fontWeight: FontWeight.w500,
                          inherit: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    previewText,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
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

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required bool glassMode,
  }) {
    final colors = ref.watch(dynamicColorsProvider);
    final Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.chat_bubble_outline,
          size: 56,
          color: glassMode ? Colors.white : colors.primaryAccent,
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: glassMode ? Colors.white : colors.textPrimary,
            letterSpacing: -0.3,
            inherit: true,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: glassMode
                ? Colors.white.withValues(alpha: 0.8)
                : colors.textSecondary,
            fontWeight: FontWeight.w500,
            inherit: true,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: child,
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          color: colors.surfaceWithElevation(1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderLight),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildErrorState({required bool glassMode}) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;

    final Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: glassMode ? Colors.white : colors.error,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.somethingWentWrong,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: glassMode ? Colors.white : colors.textPrimary,
            inherit: true,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.pleaseTryAgainLater,
          style: TextStyle(
            fontSize: 14,
            color: glassMode
                ? Colors.white.withValues(alpha: 0.8)
                : colors.textSecondary,
            inherit: true,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: child,
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        decoration: BoxDecoration(
          color: colors.surfaceWithElevation(1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderLight),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
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

  Widget _buildInviteFab({
    required bool glassMode,
    required AppLocalizations l10n,
  }) {
    final colors = ref.watch(dynamicColorsProvider);
    final Color background =
        glassMode ? Colors.white.withValues(alpha: 0.92) : colors.primaryAccent;
    final Color foreground = glassMode ? Colors.black87 : colors.textOnAccent;

    return FloatingActionButton.extended(
      onPressed: _showInviteTenantDialog,
      icon: const Icon(Icons.person_add_alt_1_rounded),
      label: Text(
        l10n.inviteTenant,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: glassMode ? 6 : 3,
    );
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    ref.invalidate(conversationsProvider);
    ref.invalidate(userInvitationsProvider);
    await Future.delayed(const Duration(milliseconds: 250));
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
