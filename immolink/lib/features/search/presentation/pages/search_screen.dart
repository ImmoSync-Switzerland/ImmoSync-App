import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../chat/presentation/providers/contact_providers.dart';
import '../../../chat/presentation/providers/conversations_provider.dart';
import '../../../maintenance/presentation/providers/maintenance_providers.dart';
import '../../../property/presentation/providers/property_providers.dart';

const _bgTop = Color(0xFF0A1128);
const _bgBottom = Colors.black;
const _bentoCard = Color(0xFF1C1C1E);
const _chipUnselected = Color(0xFF2C2C2E);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  int _selectedCategory = 0;

  static const List<String> _categories = [
    'All',
    'Properties',
    'Tenants',
    'Maintenance',
    'Messages',
  ];

  @override
  void initState() {
    super.initState();

    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      _controller.text = initial;
      _controller.selection = TextSelection.collapsed(offset: initial.length);
      _query = initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userRoleProvider);
    final query = _query.trim();
    final bool hasResults = query.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgTop, _bgBottom],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    controller: _controller,
                    onBack: () => context.pop(),
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  _FilterChips(
                    categories: _categories,
                    selectedIndex: _selectedCategory,
                    onSelected: (index) {
                      setState(() {
                        _selectedCategory = index;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: hasResults
                        ? _SearchResults(
                            categoryIndex: _selectedCategory,
                            query: query.toLowerCase(),
                            userRole: userRole,
                            bottomPadding: 120,
                          )
                        : const _EmptyState(
                            bottomPadding: 120,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.onBack,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Search',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _bentoCard,
            hintText: 'Search properties, tenants, reports...',
            hintStyle: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(categories.length, (index) {
          final bool selected = index == selectedIndex;
          return Padding(
            padding:
                EdgeInsets.only(right: index == categories.length - 1 ? 0 : 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelected(index),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: selected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3B82F6),
                            Color(0xFF60A5FA),
                          ],
                        )
                      : null,
                  color: selected ? null : _chipUnselected,
                ),
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 80,
              color: Colors.white10,
            ),
            SizedBox(height: 14),
            Text(
              "Type to find what you're looking for",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.categoryIndex,
    required this.query,
    required this.userRole,
    required this.bottomPadding,
  });

  final int categoryIndex;
  final String query;
  final String userRole;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (categoryIndex) {
      case 1:
        if (userRole != 'landlord') {
          return _UnavailableState(bottomPadding: bottomPadding);
        }
        return _PropertiesResults(query: query, bottomPadding: bottomPadding);
      case 2:
        if (userRole != 'landlord') {
          return _UnavailableState(bottomPadding: bottomPadding);
        }
        return _TenantsResults(query: query, bottomPadding: bottomPadding);
      case 3:
        return _MaintenanceResults(
          query: query,
          bottomPadding: bottomPadding,
        );
      case 4:
        return _MessagesResults(query: query, bottomPadding: bottomPadding);
      case 0:
      default:
        return _AllResults(
          query: query,
          userRole: userRole,
          bottomPadding: bottomPadding,
        );
    }
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState({required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: const Text(
          'Not available for your account.',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AllResults extends StatelessWidget {
  const _AllResults({
    required this.query,
    required this.userRole,
    required this.bottomPadding,
  });

  final String query;
  final String userRole;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        if (userRole == 'landlord') ...[
          _PropertiesResults(query: query, bottomPadding: 0),
          const SizedBox(height: 12),
          _TenantsResults(query: query, bottomPadding: 0),
          const SizedBox(height: 12),
        ],
        _MaintenanceResults(query: query, bottomPadding: 0),
        const SizedBox(height: 12),
        _MessagesResults(query: query, bottomPadding: 0),
      ],
    );
  }
}

class _PropertiesResults extends ConsumerWidget {
  const _PropertiesResults({required this.query, required this.bottomPadding});

  final String query;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(landlordPropertiesProvider);

    return propertiesAsync.when(
      data: (properties) {
        final matches = properties.where((property) {
          final street = property.address.street.toLowerCase();
          final city = property.address.city.toLowerCase();
          final status = property.status.toLowerCase();
          return street.contains(query) ||
              city.contains(query) ||
              status.contains(query);
        }).toList();

        if (matches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            for (final property in matches) ...[
              _BentoResultCard(
                title: '${property.address.street}, ${property.address.city}',
                subtitle: 'Property',
                icon: Icons.home_work_rounded,
                onTap: () => context.push('/property/${property.id}'),
              ),
              const SizedBox(height: 12),
            ],
            if (bottomPadding > 0) SizedBox(height: bottomPadding),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'Error loading properties: $error',
          style: const TextStyle(color: Colors.white60),
        ),
      ),
    );
  }
}

class _TenantsResults extends ConsumerWidget {
  const _TenantsResults({required this.query, required this.bottomPadding});

  final String query;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(allTenantsProvider);
    final propertiesAsync = ref.watch(landlordPropertiesProvider);

    return tenantsAsync.when(
      data: (tenants) {
        return propertiesAsync.when(
          data: (properties) {
            final assigned = tenants.where((tenant) {
              return properties.any((p) => p.tenantIds.contains(tenant.id));
            }).toList();

            final matches = assigned.where((tenant) {
              return tenant.fullName.toLowerCase().contains(query) ||
                  tenant.email.toLowerCase().contains(query);
            }).toList();

            if (matches.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                for (final tenant in matches) ...[
                  _BentoResultCard(
                    title: tenant.fullName,
                    subtitle: tenant.email.isNotEmpty ? tenant.email : 'Tenant',
                    icon: Icons.person_rounded,
                    onTap: () => context.push(
                      '/chat/new?otherUserId=${tenant.id}&otherUserName=${Uri.encodeComponent(tenant.fullName)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (bottomPadding > 0) SizedBox(height: bottomPadding),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Error loading properties: $error',
              style: const TextStyle(color: Colors.white60),
            ),
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'Error loading tenants: $error',
          style: const TextStyle(color: Colors.white60),
        ),
      ),
    );
  }
}

class _MaintenanceResults extends ConsumerWidget {
  const _MaintenanceResults({required this.query, required this.bottomPadding});

  final String query;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);
    final maintenanceAsync = userRole == 'landlord'
        ? ref.watch(landlordMaintenanceRequestsProvider)
        : ref.watch(tenantMaintenanceRequestsProvider);

    return maintenanceAsync.when(
      data: (requests) {
        final matches = requests.where((r) {
          return r.title.toLowerCase().contains(query) ||
              r.description.toLowerCase().contains(query) ||
              r.status.toLowerCase().contains(query);
        }).toList();

        if (matches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            for (final request in matches) ...[
              _BentoResultCard(
                title: request.title,
                subtitle: 'Maintenance',
                icon: Icons.handyman_rounded,
                onTap: () => context.push('/maintenance/${request.id}'),
              ),
              const SizedBox(height: 12),
            ],
            if (bottomPadding > 0) SizedBox(height: bottomPadding),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'Error loading maintenance: $error',
          style: const TextStyle(color: Colors.white60),
        ),
      ),
    );
  }
}

class _MessagesResults extends ConsumerWidget {
  const _MessagesResults({required this.query, required this.bottomPadding});

  final String query;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return conversationsAsync.when(
      data: (conversations) {
        final matches = conversations.where((c) {
          final name = (c.otherParticipantName ?? '').toLowerCase();
          final last = c.lastMessage.toLowerCase();
          return name.contains(query) || last.contains(query);
        }).toList();

        if (matches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            for (final conversation in matches) ...[
              _BentoResultCard(
                title: conversation.otherParticipantName ?? 'Unknown',
                subtitle: conversation.lastMessage.isNotEmpty
                    ? conversation.lastMessage
                    : 'Messages',
                icon: Icons.chat_bubble_rounded,
                onTap: () {
                  final name = conversation.otherParticipantName ?? 'User';
                  final otherId = conversation.otherParticipantId ?? '';
                  final avatar = conversation.otherParticipantAvatar ?? '';
                  context.push(
                    '/chat/${conversation.id}?otherUserId=$otherId&otherUser=${Uri.encodeComponent(name)}&otherAvatar=${Uri.encodeComponent(avatar)}',
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            if (bottomPadding > 0) SizedBox(height: bottomPadding),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'Error loading messages: $error',
          style: const TextStyle(color: Colors.white60),
        ),
      ),
    );
  }
}

class _BentoResultCard extends StatelessWidget {
  const _BentoResultCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bentoCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
