import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../property/presentation/providers/property_providers.dart';
import '../../../chat/presentation/providers/contact_providers.dart';
import '../../../maintenance/presentation/providers/maintenance_providers.dart';
import '../../../chat/presentation/providers/conversations_provider.dart';
import '../../../../core/widgets/user_avatar.dart';

class UniversalSearchPage extends ConsumerStatefulWidget {
  const UniversalSearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<UniversalSearchPage> createState() =>
      _UniversalSearchPageState();
}

class _UniversalSearchPageState extends ConsumerState<UniversalSearchPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final userRole = ref.read(userRoleProvider);
    final tabCount =
        userRole == 'landlord' ? 5 : 4; // Landlords have 5 tabs, tenants have 4
    _tabController = TabController(length: tabCount, vsync: this);

    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      _searchController.text = initial;
      _searchController.selection = TextSelection.collapsed(
        offset: initial.length,
      );
      _searchQuery = initial.toLowerCase();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final userRole = ref.watch(userRoleProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        title: Text(
          'Suchen',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.chevron_left, color: colors.textPrimary, size: 32),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceCards,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadowColorMedium,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                    hintText: 'Suchen...',
                    hintStyle: TextStyle(color: colors.textSecondary),
                    prefixIcon: Icon(Icons.search, color: colors.primaryAccent),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: TextStyle(color: colors.textPrimary),
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: colors.primaryAccent,
                unselectedLabelColor: colors.textSecondary,
                indicatorColor: colors.primaryAccent,
                tabs: _buildTabs(userRole),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _buildTabViews(userRole),
      ),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  List<Widget> _buildTabs(String userRole) {
    if (userRole == 'landlord') {
      return [
        const Tab(text: 'Alle'),
        const Tab(text: 'Immobilien'),
        const Tab(text: 'Mieter'),
        const Tab(text: 'Wartung'),
        const Tab(text: 'Nachrichten'),
      ];
    } else {
      return [
        const Tab(text: 'Alle'),
        const Tab(text: 'Dokumente'),
        const Tab(text: 'Wartung'),
        const Tab(text: 'Nachrichten'),
      ];
    }
  }

  List<Widget> _buildTabViews(String userRole) {
    if (userRole == 'landlord') {
      return [
        _AllSearchTab(searchQuery: _searchQuery, userRole: userRole),
        _PropertiesSearchTab(searchQuery: _searchQuery),
        _TenantsSearchTab(searchQuery: _searchQuery),
        _MaintenanceSearchTab(searchQuery: _searchQuery),
        _MessagesSearchTab(searchQuery: _searchQuery),
      ];
    } else {
      return [
        _AllSearchTab(searchQuery: _searchQuery, userRole: userRole),
        _DocumentsSearchTab(searchQuery: _searchQuery),
        _MaintenanceSearchTab(searchQuery: _searchQuery),
        _MessagesSearchTab(searchQuery: _searchQuery),
      ];
    }
  }
}

class _PropertiesSearchTab extends ConsumerWidget {
  final String searchQuery;

  const _PropertiesSearchTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final propertiesAsync = ref.watch(landlordPropertiesProvider);

    return propertiesAsync.when(
      data: (properties) {
        final filteredProperties = properties.where((property) {
          return searchQuery.isEmpty ||
              property.address.street.toLowerCase().contains(searchQuery) ||
              property.address.city.toLowerCase().contains(searchQuery) ||
              property.status.toLowerCase().contains(searchQuery);
        }).toList();

        if (filteredProperties.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isEmpty
                  ? 'Geben Sie einen Suchbegriff ein'
                  : 'Keine Immobilien gefunden',
              style: TextStyle(color: colors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredProperties.length,
          itemBuilder: (context, index) {
            final property = filteredProperties[index];
            return Card(
              color: colors.surfaceCards,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(Icons.home, color: colors.primaryAccent),
                title: Text(
                  '${property.address.street}, ${property.address.city}',
                  style: TextStyle(
                      color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Status: ${property.status} • €${property.rentAmount}',
                  style: TextStyle(color: colors.textSecondary),
                ),
                onTap: () => context.push('/property/${property.id}'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Fehler: $error', style: TextStyle(color: colors.error)),
      ),
    );
  }
}

class _TenantsSearchTab extends ConsumerWidget {
  final String searchQuery;

  const _TenantsSearchTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final tenantsAsync = ref.watch(allTenantsProvider);
    final propertiesAsync = ref.watch(landlordPropertiesProvider);

    return tenantsAsync.when(
      data: (tenants) {
        return propertiesAsync.when(
          data: (properties) {
            // Filter to only show tenants assigned to landlord's properties
            final assignedTenants = tenants.where((tenant) {
              return properties
                  .any((property) => property.tenantIds.contains(tenant.id));
            }).toList();

            final filteredTenants = assignedTenants.where((tenant) {
              return searchQuery.isEmpty ||
                  tenant.fullName.toLowerCase().contains(searchQuery) ||
                  tenant.email.toLowerCase().contains(searchQuery);
            }).toList();

            if (filteredTenants.isEmpty) {
              return Center(
                child: Text(
                  searchQuery.isEmpty
                      ? 'Geben Sie einen Suchbegriff ein'
                      : 'Keine zugewiesenen Mieter gefunden',
                  style: TextStyle(color: colors.textSecondary),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTenants.length,
              itemBuilder: (context, index) {
                final tenant = filteredTenants[index];
                return Card(
                  color: colors.surfaceCards,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: UserAvatar(
                        imageRef: tenant.profileImage,
                        name: tenant.fullName,
                        size: 40),
                    title: Text(
                      tenant.fullName,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      tenant.email,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    onTap: () => context.push(
                        '/chat/new?otherUserId=${tenant.id}&otherUserName=${tenant.fullName}'),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Fehler beim Laden der Eigenschaften: $error',
                style: TextStyle(color: colors.error)),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Fehler beim Laden der Mieter: $error',
            style: TextStyle(color: colors.error)),
      ),
    );
  }
}

class _DocumentsSearchTab extends ConsumerWidget {
  final String searchQuery;

  const _DocumentsSearchTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);

    // Mock documents for now - replace with actual document provider
    final documents = [
      {'name': 'Mietvertrag.pdf', 'category': 'Verträge', 'date': '15.08.2025'},
      {'name': 'Hausordnung.pdf', 'category': 'Regeln', 'date': '01.08.2025'},
      {
        'name': 'Nebenkostenabrechnung.pdf',
        'category': 'Abrechnungen',
        'date': '10.08.2025'
      },
    ];

    final filteredDocuments = documents.where((doc) {
      return searchQuery.isEmpty ||
          doc['name']!.toLowerCase().contains(searchQuery) ||
          doc['category']!.toLowerCase().contains(searchQuery);
    }).toList();

    if (filteredDocuments.isEmpty) {
      return Center(
        child: Text(
          searchQuery.isEmpty
              ? 'Geben Sie einen Suchbegriff ein'
              : 'Keine Dokumente gefunden',
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDocuments.length,
      itemBuilder: (context, index) {
        final document = filteredDocuments[index];
        return Card(
          color: colors.surfaceCards,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(Icons.description, color: colors.primaryAccent),
            title: Text(
              document['name']!,
              style: TextStyle(
                  color: colors.textPrimary, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${document['category']} • ${document['date']}',
              style: TextStyle(color: colors.textSecondary),
            ),
            onTap: () {
              // Open document
            },
          ),
        );
      },
    );
  }
}

class _MaintenanceSearchTab extends ConsumerWidget {
  final String searchQuery;

  const _MaintenanceSearchTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final userRole = ref.watch(userRoleProvider);

    // Use role-specific maintenance provider
    final maintenanceAsync = userRole == 'landlord'
        ? ref.watch(landlordMaintenanceRequestsProvider)
        : ref.watch(tenantMaintenanceRequestsProvider);

    return maintenanceAsync.when(
      data: (requests) {
        final filteredRequests = requests.where((request) {
          return searchQuery.isEmpty ||
              request.title.toLowerCase().contains(searchQuery) ||
              request.description.toLowerCase().contains(searchQuery) ||
              request.status.toLowerCase().contains(searchQuery);
        }).toList();

        if (filteredRequests.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isEmpty
                  ? 'Geben Sie einen Suchbegriff ein'
                  : 'Keine Wartungsanfragen gefunden',
              style: TextStyle(color: colors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            final request = filteredRequests[index];
            return Card(
              color: colors.surfaceCards,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(Icons.build, color: colors.primaryAccent),
                title: Text(
                  request.title,
                  style: TextStyle(
                      color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Status: ${request.status} • ${request.description}',
                  style: TextStyle(color: colors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.push('/maintenance/${request.id}'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Fehler: $error', style: TextStyle(color: colors.error)),
      ),
    );
  }
}

class _MessagesSearchTab extends ConsumerWidget {
  final String searchQuery;

  const _MessagesSearchTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final conversationsAsync = ref.watch(conversationsProvider);

    return conversationsAsync.when(
      data: (conversations) {
        final filteredConversations = conversations.where((conversation) {
          return searchQuery.isEmpty ||
              (conversation.otherParticipantName
                      ?.toLowerCase()
                      .contains(searchQuery) ??
                  false) ||
              conversation.lastMessage.toLowerCase().contains(searchQuery);
        }).toList();

        if (filteredConversations.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isEmpty
                  ? 'Geben Sie einen Suchbegriff ein'
                  : 'Keine Nachrichten gefunden',
              style: TextStyle(color: colors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredConversations.length,
          itemBuilder: (context, index) {
            final conversation = filteredConversations[index];
            return Card(
              color: colors.surfaceCards,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: UserAvatar(
                  imageRef: conversation.getOtherParticipantAvatarUrl() ??
                      conversation.otherParticipantAvatar,
                  name: conversation.otherParticipantName,
                  size: 40,
                  fallbackToCurrentUser: false,
                ),
                title: Text(
                  conversation.otherParticipantName ?? 'Unbekannt',
                  style: TextStyle(
                      color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  conversation.lastMessage.isNotEmpty
                      ? conversation.lastMessage
                      : 'Keine Nachrichten',
                  style: TextStyle(color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  final name = conversation.otherParticipantName ?? 'User';
                  final otherId = conversation.otherParticipantId ?? '';
                  final avatar = conversation.otherParticipantAvatar ?? '';
                  context.push(
                      '/chat/${conversation.id}?otherUserId=$otherId&otherUser=${Uri.encodeComponent(name)}&otherAvatar=${Uri.encodeComponent(avatar)}');
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Fehler: $error', style: TextStyle(color: colors.error)),
      ),
    );
  }
}

class _AllSearchTab extends ConsumerWidget {
  final String searchQuery;
  final String userRole;

  const _AllSearchTab({required this.searchQuery, required this.userRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);

    if (searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Geben Sie einen Suchbegriff ein',
              style: TextStyle(color: colors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              userRole == 'landlord'
                  ? 'Durchsuchen Sie Immobilien, Mieter, Wartung und Nachrichten'
                  : 'Durchsuchen Sie Dokumente, Wartung und Nachrichten',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userRole == 'landlord') ...[
            _buildPropertiesSection(context, ref, colors),
            const SizedBox(height: 24),
            _buildTenantsSection(context, ref, colors),
            const SizedBox(height: 24),
          ] else ...[
            _buildDocumentsSection(context, ref, colors),
            const SizedBox(height: 24),
          ],
          _buildMaintenanceSection(context, ref, colors),
          const SizedBox(height: 24),
          _buildMessagesSection(context, ref, colors),
        ],
      ),
    );
  }

  Widget _buildPropertiesSection(
      BuildContext context, WidgetRef ref, dynamic colors) {
    final propertiesAsync = ref.watch(landlordPropertiesProvider);

    return propertiesAsync.when(
      data: (properties) {
        final filteredProperties = properties.where((property) {
          return property.address.street
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              property.address.city
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              property.status.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

        if (filteredProperties.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
                title: 'Immobilien (${filteredProperties.length})',
                colors: colors),
            ...filteredProperties.take(3).map((property) => Card(
                  color: colors.surfaceCards,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.home, color: colors.primaryAccent),
                    title: Text(
                      '${property.address.street}, ${property.address.city}',
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Status: ${property.status} • €${property.rentAmount}',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    onTap: () => context.push('/property/${property.id}'),
                  ),
                )),
            if (filteredProperties.length > 3)
              TextButton(
                onPressed: () => DefaultTabController.of(context).animateTo(1),
                child: Text(
                    'Alle ${filteredProperties.length} Immobilien anzeigen'),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildTenantsSection(
      BuildContext context, WidgetRef ref, dynamic colors) {
    final tenantsAsync = ref.watch(allTenantsProvider);
    final propertiesAsync = ref.watch(landlordPropertiesProvider);

    return tenantsAsync.when(
      data: (tenants) {
        return propertiesAsync.when(
          data: (properties) {
            // Filter to only show tenants assigned to landlord's properties
            final assignedTenants = tenants.where((tenant) {
              return properties
                  .any((property) => property.tenantIds.contains(tenant.id));
            }).toList();

            final filteredTenants = assignedTenants.where((tenant) {
              return tenant.fullName
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()) ||
                  tenant.email
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());
            }).toList();

            if (filteredTenants.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                    title: 'Mieter (${filteredTenants.length})',
                    colors: colors),
                ...filteredTenants.take(3).map((tenant) => Card(
                      color: colors.surfaceCards,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: UserAvatar(
                            imageRef: tenant.profileImage,
                            name: tenant.fullName,
                            size: 40),
                        title: Text(
                          tenant.fullName,
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          tenant.email,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        onTap: () => context.push(
                            '/chat/new?otherUserId=${tenant.id}&otherUserName=${tenant.fullName}'),
                      ),
                    )),
                if (filteredTenants.length > 3)
                  TextButton(
                    onPressed: () =>
                        DefaultTabController.of(context).animateTo(2),
                    child:
                        Text('Alle ${filteredTenants.length} Mieter anzeigen'),
                  ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildDocumentsSection(
      BuildContext context, WidgetRef ref, dynamic colors) {
    // For now, just show a placeholder since we don't have documents provider
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Dokumente', colors: colors),
        Card(
          color: colors.surfaceCards,
          child: ListTile(
            leading: Icon(Icons.description, color: colors.primaryAccent),
            title: Text(
              'Dokumentensuche',
              style: TextStyle(
                  color: colors.textPrimary, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Verwenden Sie die Dokumente-Registerkarte für eine detaillierte Suche',
              style: TextStyle(color: colors.textSecondary),
            ),
            onTap: () => DefaultTabController.of(context).animateTo(1),
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceSection(
      BuildContext context, WidgetRef ref, dynamic colors) {
    final maintenanceAsync = userRole == 'landlord'
        ? ref.watch(landlordMaintenanceRequestsProvider)
        : ref.watch(tenantMaintenanceRequestsProvider);

    return maintenanceAsync.when(
      data: (requests) {
        final filteredRequests = requests.where((request) {
          return request.title
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              request.description
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              request.status.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

        if (filteredRequests.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
                title: 'Wartungsanfragen (${filteredRequests.length})',
                colors: colors),
            ...filteredRequests.take(3).map((request) => Card(
                  color: colors.surfaceCards,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.build,
                      color: request.status == 'open'
                          ? colors.error
                          : colors.primaryAccent,
                    ),
                    title: Text(
                      request.title,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Status: ${request.status} • ${request.priority}',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    onTap: () => context.push('/maintenance/${request.id}'),
                  ),
                )),
            if (filteredRequests.length > 3)
              TextButton(
                onPressed: () => DefaultTabController.of(context)
                    .animateTo(userRole == 'landlord' ? 3 : 2),
                child: Text(
                    'Alle ${filteredRequests.length} Wartungsanfragen anzeigen'),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildMessagesSection(
      BuildContext context, WidgetRef ref, dynamic colors) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return conversationsAsync.when(
      data: (conversations) {
        final filteredConversations = conversations.where((conversation) {
          return (conversation.otherParticipantName
                      ?.toLowerCase()
                      .contains(searchQuery.toLowerCase()) ??
                  false) ||
              conversation.lastMessage
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());
        }).toList();

        if (filteredConversations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
                title: 'Nachrichten (${filteredConversations.length})',
                colors: colors),
            ...filteredConversations.take(3).map((conversation) => Card(
                  color: colors.surfaceCards,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: UserAvatar(
                      imageRef: conversation.getOtherParticipantAvatarUrl() ??
                          conversation.otherParticipantAvatar,
                      name: conversation.otherParticipantName,
                      size: 40,
                      fallbackToCurrentUser: false,
                    ),
                    title: Text(
                      conversation.otherParticipantName ?? 'Unbekannt',
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      conversation.lastMessage.isNotEmpty
                          ? conversation.lastMessage
                          : 'Keine Nachrichten',
                      style: TextStyle(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      final name = conversation.otherParticipantName ?? 'User';
                      final otherId = conversation.otherParticipantId ?? '';
                      final avatar = conversation.otherParticipantAvatar ?? '';
                      context.push(
                          '/chat/${conversation.id}?otherUserId=$otherId&otherUser=${Uri.encodeComponent(name)}&otherAvatar=${Uri.encodeComponent(avatar)}');
                    },
                  ),
                )),
            if (filteredConversations.length > 3)
              TextButton(
                onPressed: () => DefaultTabController.of(context)
                    .animateTo(userRole == 'landlord' ? 4 : 3),
                child: Text(
                    'Alle ${filteredConversations.length} Nachrichten anzeigen'),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final dynamic colors;

  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
