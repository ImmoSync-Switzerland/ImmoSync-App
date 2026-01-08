import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/dynamic_colors_provider.dart';
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
  static const Color _bgTop = Color(0xFF0A1128);
  static const Color _bgBottom = Colors.black;
  static const Color _bentoCardColor = Color(0xFF1C1C1E);

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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _DeepNavyBackground(),
          SafeArea(child: body),
        ],
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
          if (!glassMode) ...[
            const SizedBox(height: 8),
            _BentoHeader(
              title: isLandlord ? l10n.tenants : l10n.landlords,
              onBack: () => _handleBack(context),
            ),
            const SizedBox(height: 14),
          ],
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
    final hintText = l10n.searchContactsHint;
    return TextField(
      controller: _searchController,
      keyboardType: TextInputType.text,
      onChanged: (value) => setState(() => _searchQuery = value),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
        prefixIcon: Icon(
          Icons.search,
          color: Colors.white.withValues(alpha: 0.55),
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.white.withValues(alpha: 0.65),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
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
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              glassMode ? 0 : 0,
              8,
              glassMode ? 0 : 0,
              glassMode ? 160 : 100,
            ),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildContactTile(
              filtered[index],
              isLandlord,
              colors,
              l10n,
              glassMode: glassMode,
            ),
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
    final l10n = AppLocalizations.of(context)!;
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
              ? l10n.tryAdjustingSearch
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

    final Widget tileContent = Row(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: ClipOval(
            child: UserAvatar(
              imageRef: contact.profileImage,
              name: contact.fullName,
              size: 60,
              fallbackToCurrentUser: false,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 14, color: tertiaryText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      contact.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: glassMode ? secondaryText : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (contact.phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: tertiaryText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        contact.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              if (contact.properties.isNotEmpty)
                _PropertiesChip(
                  label:
                      '${contact.properties.length} ${contact.properties.length == 1 ? 'Property' : 'Properties'}',
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CircleActionButton(
              tooltip: l10n.openChat,
              background: const Color(0xFF3B82F6).withValues(alpha: 0.25),
              icon: Icons.chat_bubble_outline,
              onTap: () {
                HapticFeedback.lightImpact();
                _startConversationWith(contact);
              },
            ),
            if (contact.phone.isNotEmpty) ...[
              const SizedBox(height: 10),
              _CircleActionButton(
                tooltip: l10n.call,
                background: const Color(0xFF22C55E).withValues(alpha: 0.25),
                icon: Icons.phone_outlined,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _callContact(contact);
                },
              ),
            ],
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
        color: _bentoCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      padding: const EdgeInsets.all(16),
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

class _DeepNavyBackground extends StatelessWidget {
  const _DeepNavyBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _AddressBookPageState._bgTop,
            _AddressBookPageState._bgBottom
          ],
        ),
      ),
    );
  }
}

class _BentoHeader extends StatelessWidget {
  const _BentoHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.chevron_left,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PropertiesChip extends StatelessWidget {
  const _PropertiesChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFFC107);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: amber, width: 1),
        color: amber.withValues(alpha: 0.06),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: amber,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.tooltip,
    required this.background,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final Color background;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
