import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/conversations_provider.dart';
import '../providers/invitation_provider.dart';
import '../../domain/models/conversation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../widgets/invitation_card.dart';
import '../../../property/presentation/providers/property_providers.dart';
import '../../../property/domain/models/property.dart';
import '../../../auth/domain/models/user.dart';

class ConversationsTabbedPage extends ConsumerStatefulWidget {
  const ConversationsTabbedPage({super.key});

  @override
  ConsumerState<ConversationsTabbedPage> createState() => _ConversationsTabbedPageState();
}

class _ConversationsTabbedPageState extends ConsumerState<ConversationsTabbedPage> 
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
              icon: Icon(Icons.contacts_outlined, color: colors.primaryAccent, size: 22),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
          return _buildEmptyState('No conversations yet', 'Start chatting with your tenants or landlord');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredConversations.length,
          itemBuilder: (context, index) {
            final conversation = filteredConversations[index];
            final currentUser = ref.watch(currentUserProvider);
            final otherUserId = conversation.getOtherParticipantId(currentUser?.id ?? '');
            
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

  Widget _buildConversationTile(
    BuildContext context, 
    Conversation conversation, 
    String otherUserId, 
    String currentUserId
  ) {
    final colors = ref.watch(dynamicColorsProvider);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(
          '/chat/${conversation.id}?otherUser=${Uri.encodeComponent(conversation.otherParticipantName ?? 'Unknown User')}&otherUserId=$otherUserId',
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.primaryAccent.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.person_outline,
                color: colors.primaryAccent,
                size: 24,
              ),
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
                    conversation.lastMessage,
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
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              inherit: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
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
      final searchInName = conversation.otherParticipantName?.toLowerCase().contains(_searchQuery) ?? false;
      final searchInMessage = conversation.lastMessage.toLowerCase().contains(_searchQuery);
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
      builder: (context) => InviteTenantDialog(
        landlordId: currentUser.id,
      ),
    );
  }
}

class InviteTenantDialog extends ConsumerStatefulWidget {
  final String landlordId;

  const InviteTenantDialog({
    super.key,
    required this.landlordId,
  });

  @override
  ConsumerState<InviteTenantDialog> createState() => _InviteTenantDialogState();
}

class _InviteTenantDialogState extends ConsumerState<InviteTenantDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedPropertyId;
  String? _selectedTenantId;
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final propertiesAsync = ref.watch(landlordPropertiesProvider);
    final tenantsAsync = ref.watch(availableTenantsProvider(_selectedPropertyId));

    return Dialog(
      backgroundColor: colors.surfaceCards,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.addTenant,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Property Selection
            Text(
              l10n.property,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            propertiesAsync.when(
              data: (properties) => _buildPropertyDropdown(properties, colors),
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
            ),
            
            const SizedBox(height: 24),
            
            // Tenant Search
            Text(
              l10n.searchTenants,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildSearchBar(colors),
            
            const SizedBox(height: 16),
            
            // Tenant List
            Expanded(
              child: tenantsAsync.when(
                data: (tenants) => _buildTenantList(tenants, colors),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Message
            Text(
              l10n.message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.typeAMessage,
                hintStyle: TextStyle(color: colors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primaryAccent),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSendInvitation() ? _sendInvitation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.submit,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyDropdown(List<Property> properties, DynamicAppColors colors) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPropertyId,
          hint: Text(
            AppLocalizations.of(context)!.pleaseSelectProperty,
            style: TextStyle(color: colors.textSecondary),
          ),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          items: properties.map((property) {
            return DropdownMenuItem<String>(
              value: property.id,
              child: Text(
                '${property.address.street}, ${property.address.city}',
                style: TextStyle(color: colors.textPrimary),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPropertyId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(DynamicAppColors colors) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchTenants,
        hintStyle: TextStyle(color: colors.textSecondary),
        prefixIcon: Icon(Icons.search, color: colors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primaryAccent),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
    );
  }

  Widget _buildTenantList(List<User> tenants, DynamicAppColors colors) {
    final filteredTenants = tenants.where((tenant) {
      return tenant.fullName.toLowerCase().contains(_searchQuery) ||
             tenant.email.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredTenants.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noTenantsFound,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTenants.length,
      itemBuilder: (context, index) {
        final tenant = filteredTenants[index];
        final isSelected = _selectedTenantId == tenant.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryAccent.withValues(alpha: 0.1) : colors.primaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.primaryAccent : colors.textSecondary.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.primaryAccent.withValues(alpha: 0.2),
              child: Text(
                tenant.fullName.isNotEmpty ? tenant.fullName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: colors.primaryAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              tenant.fullName,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              tenant.email,
              style: TextStyle(color: colors.textSecondary),
            ),
            onTap: () {
              setState(() {
                _selectedTenantId = isSelected ? null : tenant.id;
              });
            },
          ),
        );
      },
    );
  }

  bool _canSendInvitation() {
    return _selectedPropertyId != null && _selectedTenantId != null;
  }

  void _sendInvitation() async {
    if (!_canSendInvitation()) return;

    final colors = ref.read(dynamicColorsProvider);
    
    try {
      await ref.read(invitationNotifierProvider.notifier).sendInvitation(
        propertyId: _selectedPropertyId!,
        landlordId: widget.landlordId,
        tenantId: _selectedTenantId!,
        message: _messageController.text.isNotEmpty 
          ? _messageController.text 
          : AppLocalizations.of(context)!.inviteTenant,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.success),
            backgroundColor: colors.success,
          ),
        );
        
        // Refresh invitations
        ref.invalidate(userInvitationsProvider);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $error'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
