import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:immosync/features/property/domain/models/property.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import 'package:immosync/features/chat/domain/models/conversation.dart';
import 'package:immosync/features/chat/presentation/providers/conversations_provider.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';

class TenantSearchPage extends ConsumerStatefulWidget {
  const TenantSearchPage({super.key});

  @override
  ConsumerState<TenantSearchPage> createState() => _TenantSearchPageState();
}

class _TenantSearchPageState extends ConsumerState<TenantSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, properties, landlords, messages

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
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
    final currentUser = ref.watch(currentUserProvider);
    final isLandlord = currentUser?.role == 'landlord';

    // Choose appropriate providers based on user role
    final propertiesAsync = isLandlord
        ? ref.watch(landlordPropertiesProvider)
        : ref.watch(tenantPropertiesProvider);
    final conversationsAsync = ref.watch(conversationsProvider);

    return Consumer(
      builder: (context, ref, child) {
        final colors = ref.watch(dynamicColorsProvider);

        return Scaffold(
          backgroundColor: colors.primaryBackground,
          appBar: AppBar(
            title: Text(l10n.search),
            backgroundColor: colors.surfaceCards,
            foregroundColor: colors.textPrimary,
            elevation: 0,
          ),
          body: Column(
            children: [
              _buildSearchHeader(l10n, colors),
              _buildFilterTabs(l10n, isLandlord, colors),
              Expanded(
                child: _buildSearchResults(l10n, propertiesAsync,
                    conversationsAsync, isLandlord, colors),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchHeader(AppLocalizations l10n, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colors.primaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderLight),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Immobilien, Vermieter, Nachrichten suchen...',
                hintStyle: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search_outlined,
                  color: colors.primaryAccent,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colors.textTertiary,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(
      AppLocalizations l10n, bool isLandlord, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                      'all', l10n.all, Icons.search_outlined, colors),
                  const SizedBox(width: 8),
                  _buildFilterChip('properties', l10n.properties,
                      Icons.home_work_outlined, colors),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'landlords',
                      isLandlord ? l10n.tenants : 'Landlords',
                      Icons.people_outline,
                      colors),
                  const SizedBox(width: 8),
                  _buildFilterChip('messages', l10n.messages,
                      Icons.chat_bubble_outline, colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String filter, String label, IconData icon, DynamicAppColors colors) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryAccent : colors.surfaceCards,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.primaryAccent : colors.borderLight,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textSecondary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
      AppLocalizations l10n,
      AsyncValue<List<Property>> propertiesAsync,
      AsyncValue<List<Conversation>> conversationsAsync,
      bool isLandlord,
      DynamicAppColors colors) {
    if (_searchQuery.isEmpty) {
      return _buildEmptyState(l10n, colors);
    }

    return propertiesAsync.when(
      data: (properties) {
        return conversationsAsync.when(
          data: (conversations) {
            final filteredResults =
                _filterResults(properties, conversations, isLandlord);

            if (filteredResults.isEmpty) {
              return _buildNoResultsState(l10n, colors);
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: filteredResults.length,
              itemBuilder: (context, index) {
                final result = filteredResults[index];
                return _buildResultItem(result, l10n, colors);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading conversations: $error'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading properties: $error'),
      ),
    );
  }

  List<SearchResult> _filterResults(List<Property> properties,
      List<Conversation> conversations, bool isLandlord) {
    final searchLower = _searchQuery.toLowerCase();
    final List<SearchResult> results = [];

    // Filter properties
    if (_selectedFilter == 'all' || _selectedFilter == 'properties') {
      for (final property in properties) {
        final addressString =
            '${property.address.street}, ${property.address.city}';
        if (addressString.toLowerCase().contains(searchLower) ||
            property.address.city.toLowerCase().contains(searchLower) ||
            property.address.street.toLowerCase().contains(searchLower) ||
            property.status.toLowerCase().contains(searchLower)) {
          results.add(SearchResult(
            type: 'property',
            title: addressString,
            subtitle:
                '${property.details.rooms} rooms • ${_getStatusTranslation(property.status)}',
            data: property,
          ));
        }
      }
    }

    // Filter conversations/messages
    if (_selectedFilter == 'all' || _selectedFilter == 'messages') {
      for (final conversation in conversations) {
        // Search in conversation participants
        bool matchesParticipant = false;
        String participantName = '';

        if (conversation.otherParticipantName != null &&
            conversation.otherParticipantName!
                .toLowerCase()
                .contains(searchLower)) {
          matchesParticipant = true;
          participantName = conversation.otherParticipantName!;
        }

        if (conversation.otherParticipantEmail != null &&
            conversation.otherParticipantEmail!
                .toLowerCase()
                .contains(searchLower)) {
          matchesParticipant = true;
          participantName = conversation.otherParticipantName ?? 'User';
        }

        // Search in recent messages
        final bool matchesMessage =
            conversation.lastMessage.toLowerCase().contains(searchLower);

        if (matchesParticipant || matchesMessage) {
          results.add(SearchResult(
            type: 'conversation',
            title: participantName.isNotEmpty ? participantName : 'Chat',
            subtitle: conversation.lastMessage.isNotEmpty
                ? conversation.lastMessage
                : 'No messages yet',
            data: conversation,
          ));
        }
      }
    }

    // Filter landlords/tenants (based on conversation participants)
    if (_selectedFilter == 'all' || _selectedFilter == 'landlords') {
      for (final conversation in conversations) {
        // For tenants: show landlords, For landlords: show tenants
        final targetRole = isLandlord ? 'tenant' : 'landlord';

        if (conversation.otherParticipantRole == targetRole &&
            conversation.otherParticipantName != null &&
            (conversation.otherParticipantName!
                    .toLowerCase()
                    .contains(searchLower) ||
                (conversation.otherParticipantEmail != null &&
                    conversation.otherParticipantEmail!
                        .toLowerCase()
                        .contains(searchLower)))) {
          results.add(SearchResult(
            type: isLandlord ? 'tenant' : 'landlord',
            title: conversation.otherParticipantName!,
            subtitle: conversation.otherParticipantEmail ?? 'No email',
            data: conversation,
          ));
        }
      }
    }

    return results;
  }

  String _getStatusTranslation(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'available':
        return l10n.available;
      case 'occupied':
      case 'rented':
        return l10n.occupied;
      case 'maintenance':
        return l10n.maintenance;
      default:
        return status;
    }
  }

  Widget _buildResultItem(
      SearchResult result, AppLocalizations l10n, DynamicAppColors colors) {
    IconData icon;
    Color iconColor;
    VoidCallback? onTap;

    switch (result.type) {
      case 'property':
        icon = Icons.home_work_outlined;
        iconColor = colors.primaryAccent;
        onTap = () {
          final property = result.data as Property;
          context.push('/property/${property.id}');
        };
        break;
      case 'conversation':
        icon = Icons.chat_bubble_outline;
        iconColor = colors.warning;
        onTap = () {
          final conversation = result.data as Conversation;
          final name = conversation.otherParticipantName ?? 'User';
          final otherId = conversation.otherParticipantId ?? '';
          final avatar = conversation.otherParticipantAvatar ?? '';
          context.push(
              '/chat/${conversation.id}?otherUserId=$otherId&otherUser=${Uri.encodeComponent(name)}&otherAvatar=${Uri.encodeComponent(avatar)}');
        };
        break;
      case 'tenant':
      case 'landlord':
        icon = Icons.person_outline;
        iconColor = colors.info;
        onTap = () {
          final conversation = result.data as Conversation;
          final name = conversation.otherParticipantName ?? 'User';
          final otherId = conversation.otherParticipantId ?? '';
          final avatar = conversation.otherParticipantAvatar ?? '';
          context.push(
              '/chat/${conversation.id}?otherUserId=$otherId&otherUser=${Uri.encodeComponent(name)}&otherAvatar=${Uri.encodeComponent(avatar)}');
        };
        break;
      default:
        icon = Icons.search_outlined;
        iconColor = colors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.15),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          result.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          result.subtitle,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: colors.textSecondary,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, DynamicAppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_outlined,
            size: 64,
            color: colors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Start typing to search',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for properties, landlords, or messages',
            style: TextStyle(
              fontSize: 14,
              color: colors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(AppLocalizations l10n, DynamicAppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: colors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or check your spelling',
            style: TextStyle(
              fontSize: 14,
              color: colors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SearchResult {
  final String type; // 'property', 'tenant', 'landlord', 'conversation'
  final String title;
  final String subtitle;
  final dynamic data;

  SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    this.data,
  });
}
