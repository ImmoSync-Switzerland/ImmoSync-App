import '../../../../core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../domain/models/contact_user.dart';
import '../providers/contact_providers.dart';
import '../providers/chat_provider.dart';
import '../../../../core/widgets/app_top_bar.dart';

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
        CurvedAnimation(parent: _animationController!, curve: Curves.easeOut));

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeOut));

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
    final currentUser = ref.watch(currentUserProvider);
    final contactsAsync = ref.watch(userContactsProvider);
    final isLandlord = currentUser?.role == 'landlord';
    final colors = ref.watch(dynamicColorsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        title: isLandlord ? 'Tenants' : 'Landlords',
        showNotification: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/conversations');
            }
          },
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
        child: SafeArea(
          child: AnimatedBuilder(
            animation:
                _animationController ?? const AlwaysStoppedAnimation(1.0),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation?.value ?? 0.0),
                child: Opacity(
                  opacity: _fadeAnimation?.value ?? 1.0,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      Expanded(
                        child: contactsAsync.when(
                          data: (contacts) {
                            final filteredContacts = _filterContacts(contacts);
                            if (filteredContacts.isEmpty) {
                              return _buildEmptyState(isLandlord, colors);
                            }
                            return RefreshIndicator(
                              onRefresh: () async {
                                HapticFeedback.lightImpact();
                                ref.invalidate(userContactsProvider);
                                await Future.delayed(
                                    const Duration(seconds: 1));
                              },
                              color: colors.primaryAccent,
                              backgroundColor: Colors.white,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: filteredContacts.length,
                                itemBuilder: (context, index) {
                                  final contact = filteredContacts[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildContactTile(
                                        contact, isLandlord, colors),
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    colors.primaryAccent),
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                          error: (error, _) => Center(
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
                                  child: Icon(Icons.error_outline,
                                      size: 56, color: colors.error),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  AppLocalizations.of(context)!
                                      .errorLoadingContacts,
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
                                  AppLocalizations.of(context)!
                                      .pleaseTryAgainLater,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    inherit: true,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        colors.primaryAccent,
                                        colors.primaryAccent
                                            .withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.primaryAccent
                                            .withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        ref.invalidate(userContactsProvider),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.retry,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final colors = ref.watch(dynamicColorsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          width: 1,
        ),
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
          letterSpacing: -0.1,
          inherit: true,
        ),
        decoration: InputDecoration(
          hintText: 'Kontakte suchen...',
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
                    setState(() {
                      _searchQuery = '';
                    });
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

  List<ContactUser> _filterContacts(List<ContactUser> contacts) {
    if (_searchQuery.isEmpty) {
      return contacts;
    }

    return contacts.where((contact) {
      final searchLower = _searchQuery.toLowerCase();
      return contact.fullName.toLowerCase().contains(searchLower) ||
          contact.email.toLowerCase().contains(searchLower) ||
          contact.properties
              .any((property) => property.toLowerCase().contains(searchLower));
    }).toList();
  }

  Widget _buildEmptyState(bool isLandlord, DynamicAppColors colors) {
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
              Icons.contacts_outlined,
              size: 48,
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No contacts found'
                : isLandlord
                    ? 'No tenants yet'
                    : 'No landlords found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              inherit: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : isLandlord
                    ? 'Add properties to connect with tenants'
                    : 'Your landlord contacts will appear here',
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

  Widget _buildContactTile(
      ContactUser contact, bool isLandlord, DynamicAppColors colors) {
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
          width: 1,
        ),
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
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: UserAvatar(
          imageRef: contact.profileImage,
          name: contact.fullName,
          size: 50,
          fallbackToCurrentUser: false,
        ),
        title: Text(
          contact.fullName,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            inherit: true,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 14,
                  color: colors.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    contact.email,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      inherit: true,
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
                    color: colors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    contact.phone,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      inherit: true,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (contact.properties.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLandlord
                      ? contact.properties.first
                      : '${contact.properties.length} ${contact.properties.length == 1 ? 'Property' : 'Properties'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.primaryAccent,
                    fontWeight: FontWeight.w500,
                    inherit: true,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.chat_bubble_outline,
                color: colors.primaryAccent,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                // Navigate to chat with this contact
                _startConversationWith(contact);
              },
            ),
            if (contact.phone.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.phone_outlined,
                  color: colors.success,
                  size: 20,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _callContact(contact);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _startConversationWith(ContactUser contact) async {
    final colors = ref.read(dynamicColorsProvider);

    try {
      HapticFeedback.lightImpact();

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
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
                      inherit: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Get current user
      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.id == null) {
        throw Exception('User not authenticated');
      }

      // Find or create conversation to preserve chat history
      final chatService = ref.read(chatServiceProvider);
      final conversationId = await chatService.findOrCreateConversation(
        currentUserId: currentUser!.id,
        otherUserId: contact.id,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Navigate to the existing or newly created conversation
        final avatar = contact.profileImage ?? '';
        context.push(
            '/chat/$conversationId?otherUserId=${contact.id}&otherUser=${Uri.encodeComponent(contact.fullName)}&otherAvatar=${Uri.encodeComponent(avatar)}');
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unterhaltung konnte nicht gestartet werden: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  void _callContact(ContactUser contact) {
    final colors = ref.read(dynamicColorsProvider);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.surfaceCards,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '${AppLocalizations.of(context)!.call} ${contact.fullName}',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              inherit: true,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppLocalizations.of(context)!.callPrompt}\n${contact.phone}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  inherit: true,
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
                    width: 1,
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
                        inherit: true,
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
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                  inherit: true,
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
                          '${AppLocalizations.of(context)!.errorInitiatingCall}: ${e.toString()}'),
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
              child: Text(AppLocalizations.of(context)!.call),
            ),
          ],
        );
      },
    );
  }
}
