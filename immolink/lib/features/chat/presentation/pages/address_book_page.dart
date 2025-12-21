import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/models/dashboard_design.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../domain/models/contact_user.dart';
import '../providers/chat_provider.dart';
import '../providers/contact_providers.dart';

class AddressBookPage extends ConsumerStatefulWidget {
  const AddressBookPage({super.key});

  @override
  ConsumerState<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends ConsumerState<AddressBookPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController?.dispose();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );

    _animationController!.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    final contactsAsync = ref.watch(userContactsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final bool isLandlord = currentUser?.role == 'landlord';
    final design =
        dashboardDesignFromId(ref.watch(settingsProvider).dashboardDesign);
    final bool glassMode = design == DashboardDesign.glass;

    final Widget body = _buildAnimatedContent(
      glassMode: glassMode,
      contactsAsync: contactsAsync,
      isLandlord: isLandlord,
      colors: colors,
      l10n: l10n,
    );

    if (glassMode) {
      final String title =
          isLandlord ? l10n.tenants : l10n.landlords; // assume keys exist
      return GlassPageScaffold(
        title: title,
        showBottomNav: false,
        onBack: () => _handleBack(context),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        title: isLandlord ? l10n.tenants : l10n.landlords,
        showNotification: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () => _handleBack(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primaryBackground,
              colors.surfaceSecondary,
            ],
          ),
        ),
        child: SafeArea(child: body),
      ),
    );
  }

  Widget _buildAnimatedContent({
    required bool glassMode,
    required AsyncValue<List<ContactUser>> contactsAsync,
    required bool isLandlord,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
  }) {
    final EdgeInsets padding = glassMode
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(horizontal: 0, vertical: 12);

    final Widget content = Padding(
      padding: glassMode
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (!glassMode) const SizedBox(height: 8),
          _buildSearchBar(glassMode: glassMode, colors: colors, l10n: l10n),
          const SizedBox(height: 16),
          Expanded(
            child: _buildContactsList(
              glassMode: glassMode,
              contactsAsync: contactsAsync,
              isLandlord: isLandlord,
              colors: colors,
              l10n: l10n,
            ),
          ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _animationController ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnimation?.value ?? 0.0),
        child: Opacity(
          opacity: _fadeAnimation?.value ?? 1.0,
          child: child,
        ),
      ),
      child: Padding(padding: padding, child: content),
    );
  }

  Widget _buildSearchBar({
    required bool glassMode,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
  }) {
    final hintText = l10n.searchContacts;
    if (glassMode) {
      return GlassContainer(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: TextField(
            controller: _searchController,
            cursorColor: Colors.white,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                Icons.search_outlined,
                color: Colors.white.withValues(alpha: 0.92),
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
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
            colors.surfaceCards,
            colors.luxuryGradientStart.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.borderLight.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: colors.primaryAccent.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: colors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
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
                    color: colors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildContactsList({
    required bool glassMode,
    required AsyncValue<List<ContactUser>> contactsAsync,
    required bool isLandlord,
    required DynamicAppColors colors,
    required AppLocalizations l10n,
  }) {
    return contactsAsync.when(
      data: (contacts) {
        final filtered = _filterContacts(contacts);
        if (filtered.isEmpty) {
          return _buildEmptyState(
            glassMode: glassMode,
            isLandlord: isLandlord,
            colors: colors,
          );
        }

        final refreshColor = glassMode ? Colors.white : colors.primaryAccent;
        final refreshBackground =
            glassMode ? Colors.black.withValues(alpha: 0.28) : Colors.white;

        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.invalidate(userContactsProvider);
            await Future.delayed(const Duration(milliseconds: 600));
          },
          color: refreshColor,
          backgroundColor: refreshBackground,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              glassMode ? 0 : 0,
              8,
              glassMode ? 0 : 0,
              glassMode ? 160 : 100,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final contact = filtered[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: glassMode ? 0 : 0,
                  right: glassMode ? 0 : 0,
                  bottom: 16,
                ),
                child: _buildContactTile(
                  contact,
                  isLandlord,
                  colors,
                  l10n,
                  glassMode: glassMode,
                ),
              );
            },
          ),
        );
      },
      loading: () => Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              glassMode ? Colors.white : colors.primaryAccent,
            ),
          ),
        ),
      ),
      error: (error, _) => _buildErrorState(colors),
    );
  }

  Widget _buildEmptyState({
    required bool glassMode,
    required bool isLandlord,
    required DynamicAppColors colors,
  }) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.12)
                : colors.primaryAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.contacts_outlined,
            size: 48,
            color: glassMode ? Colors.white : colors.primaryAccent,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _searchQuery.isNotEmpty
              ? 'No contacts found'
              : isLandlord
                  ? 'No tenants yet'
                  : 'No landlords found',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: glassMode ? Colors.white : colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _searchQuery.isNotEmpty
              ? 'Try adjusting your search terms'
              : isLandlord
                  ? 'Add properties to connect with tenants'
                  : 'Your landlord contacts will appear here',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: glassMode
                ? Colors.white.withValues(alpha: 0.75)
                : colors.textSecondary,
          ),
        ),
      ],
    );

    if (glassMode) {
      return Center(
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: content,
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [content],
      ),
    );
  }

  Widget _buildErrorState(DynamicAppColors colors) {
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
                  colors.error.withValues(alpha: 0.15),
                  colors.error.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.error_outline, size: 56, color: colors.error),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.errorLoadingContacts,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.pleaseTryAgainLater,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.invalidate(userContactsProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.retry,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(
    ContactUser contact,
    bool isLandlord,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final Color primaryText = glassMode ? Colors.white : colors.textPrimary;
    final Color secondaryText =
        glassMode ? Colors.white.withValues(alpha: 0.78) : colors.textSecondary;
    final Color tertiaryText =
        glassMode ? Colors.white.withValues(alpha: 0.65) : colors.textTertiary;
    final Color accentColor =
        glassMode ? colors.luxuryGold : colors.primaryAccent;
    final Color badgeBackground = glassMode
        ? accentColor.withValues(alpha: 0.25)
        : accentColor.withValues(alpha: 0.1);
    final Color badgeBorder = glassMode
        ? Colors.white.withValues(alpha: 0.35)
        : accentColor.withValues(alpha: 0.2);

    final Widget tileContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(
          imageRef: contact.profileImage,
          name: contact.fullName,
          size: 52,
          fallbackToCurrentUser: false,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.fullName,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 14,
                    color: tertiaryText,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      contact.email,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (contact.phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: tertiaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      contact.phone,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
              if (contact.properties.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeBorder),
                  ),
                  child: Text(
                    isLandlord
                        ? contact.properties.first
                        : '${contact.properties.length} '
                            '${contact.properties.length == 1 ? 'Property' : 'Properties'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: glassMode ? Colors.white : accentColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.chat_bubble_outline,
                color: glassMode ? Colors.white : colors.primaryAccent,
                size: 22,
              ),
              tooltip: l10n.openChat,
              onPressed: () {
                HapticFeedback.lightImpact();
                _startConversationWith(contact);
              },
            ),
            if (contact.phone.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.phone_outlined,
                  color: glassMode ? Colors.white : colors.success,
                  size: 22,
                ),
                tooltip: l10n.call,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _callContact(contact);
                },
              ),
          ],
        ),
      ],
    );

    if (glassMode) {
      return GlassContainer(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          padding: const EdgeInsets.all(20),
          child: tileContent,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceCards,
            colors.luxuryGradientStart.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.borderLight.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: colors.primaryAccent.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: tileContent,
    );
  }

  List<ContactUser> _filterContacts(List<ContactUser> contacts) {
    if (_searchQuery.isEmpty) {
      return contacts;
    }

    final searchLower = _searchQuery.toLowerCase();

    return contacts.where((contact) {
      return contact.fullName.toLowerCase().contains(searchLower) ||
          contact.email.toLowerCase().contains(searchLower) ||
          contact.properties
              .any((property) => property.toLowerCase().contains(searchLower));
    }).toList();
  }

  void _startConversationWith(ContactUser contact) async {
    final colors = ref.read(dynamicColorsProvider);

    try {
      HapticFeedback.lightImpact();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceCards,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colors.primaryAccent),
                ),
                const SizedBox(height: 16),
                Text(
                  'Finding conversation...',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.id == null) {
        throw Exception('User not authenticated');
      }

      final chatService = ref.read(chatServiceProvider);
      final conversationId = await chatService.findOrCreateConversation(
        currentUserId: currentUser!.id,
        otherUserId: contact.id,
      );

      if (mounted) {
        Navigator.of(context).pop();
        final avatar = contact.profileImage ?? '';
        context.push(
          '/chat/$conversationId?otherUserId=${contact.id}&otherUser=${Uri.encodeComponent(contact.fullName)}&otherAvatar=${Uri.encodeComponent(avatar)}',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unterhaltung konnte nicht gestartet werden: $e',
            ),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  void _callContact(ContactUser contact) {
    final colors = ref.read(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.surfaceCards,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '${l10n.call} ${contact.fullName}',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${l10n.callPrompt}\n${contact.phone}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.success.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone,
                      color: colors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      contact.phone,
                      style: TextStyle(
                        color: colors.success,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final phoneUrl = Uri.parse('tel:${contact.phone}');
                  if (await canLaunchUrl(phoneUrl)) {
                    await launchUrl(phoneUrl);
                  } else {
                    throw Exception('Could not launch phone dialer');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${l10n.errorInitiatingCall}: $e',
                      ),
                      backgroundColor: colors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.call),
            ),
          ],
        );
      },
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/conversations');
    }
  }
}
