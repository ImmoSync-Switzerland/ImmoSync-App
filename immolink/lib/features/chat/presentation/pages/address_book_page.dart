import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/contact_user.dart';
import '../providers/contact_providers.dart';
import '../providers/chat_service_provider.dart';

class AddressBookPage extends ConsumerStatefulWidget {
  const AddressBookPage({super.key});

  @override
  ConsumerState<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends ConsumerState<AddressBookPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final contactsAsync = ref.watch(userContactsProvider);
    final isLandlord = currentUser?.role == 'landlord';

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          isLandlord ? 'Tenants' : 'Landlords',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/conversations');
            }
          },
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: contactsAsync.when(
              data: (contacts) {
                final filteredContacts = _filterContacts(contacts);
                if (filteredContacts.isEmpty) {
                  return _buildEmptyState(isLandlord);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildContactTile(contact, isLandlord),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                ),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading contacts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(userContactsProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.surfaceCards,
            AppColors.luxuryGradientStart,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
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
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search contacts...',
          hintStyle: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_outlined,
              color: AppColors.primaryAccent,
              size: 20,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.textTertiary,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
             contact.properties.any((property) => 
                 property.toLowerCase().contains(searchLower));
    }).toList();
  }

  Widget _buildEmptyState(bool isLandlord) {
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
              Icons.contacts_outlined,
              size: 48,
              color: AppColors.primaryAccent,
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
              color: AppColors.textPrimary,
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
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(ContactUser contact, bool isLandlord) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceCards,
            AppColors.luxuryGradientStart.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isLandlord ? AppColors.success : AppColors.luxuryGold,
                (isLandlord ? AppColors.success : AppColors.luxuryGold).withValues(alpha: 0.7),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isLandlord ? AppColors.success : AppColors.luxuryGold).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              contact.fullName.isNotEmpty ? contact.fullName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        title: Text(
          contact.fullName,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    contact.email,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),            if (contact.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    contact.phone,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
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
                  color: AppColors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLandlord 
                      ? contact.properties.first 
                      : '${contact.properties.length} ${contact.properties.length == 1 ? 'Property' : 'Properties'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w500,
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
                color: AppColors.primaryAccent,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                // Navigate to chat with this contact
                _startConversationWith(contact);
              },
            ),            if (contact.phone.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.phone_outlined,
                  color: AppColors.success,
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
                color: AppColors.surfaceCards,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Finding conversation...',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
        context.push('/chat/$conversationId?otherUserId=${contact.id}&otherUser=${Uri.encodeComponent(contact.fullName)}');
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start conversation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _callContact(ContactUser contact) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCards,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Call ${contact.fullName}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Do you want to call ${contact.phone}?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),                    Text(
                      contact.phone,
                      style: TextStyle(
                        color: AppColors.success,
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
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement actual phone call functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Phone call functionality will be implemented'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Call'),
            ),
          ],
        );
      },
    );
  }
}
