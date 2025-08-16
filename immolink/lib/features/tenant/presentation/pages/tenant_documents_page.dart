import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class TenantDocumentsPage extends ConsumerStatefulWidget {
  const TenantDocumentsPage({super.key});

  @override
  ConsumerState<TenantDocumentsPage> createState() => _TenantDocumentsPageState();
}

class _TenantDocumentsPageState extends ConsumerState<TenantDocumentsPage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: _buildAppBar(l10n, colors),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(currentUser?.fullName ?? 'Mieter', colors),
                const SizedBox(height: 32),
                _buildDocumentCategories(l10n, colors),
                const SizedBox(height: 24),
                _buildQuickActions(l10n, colors),
                const SizedBox(height: 24),
                _buildRecentActivity(l10n, colors),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n, DynamicAppColors colors) {
    return AppBar(
      backgroundColor: colors.primaryBackground,
      elevation: 0,
      title: Text(
        'Meine Dokumente',
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Add search functionality for documents
          },
          icon: Icon(Icons.search, color: colors.textSecondary),
        ),
        IconButton(
          onPressed: () {
            // Add notification bell for document updates
          },
          icon: Icon(Icons.notifications_outlined, color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(String userName, DynamicAppColors colors) {
    return Container(
      width: double.infinity,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_special,
                color: colors.primaryAccent,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Willkommen, $userName',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Verwalten Sie hier alle Ihre Mietdokumente, Verträge und wichtigen Unterlagen.',
            style: TextStyle(
              fontSize: 16,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCategories(AppLocalizations l10n, DynamicAppColors colors) {
    final categories = [
      {
        'title': 'Mietvertrag',
        'subtitle': 'Ihr aktueller Mietvertrag',
        'icon': Icons.description,
        'color': Colors.blue,
        'count': '1 Dokument',
      },
      {
        'title': 'Nebenkosten',
        'subtitle': 'Abrechnungen und Belege',
        'icon': Icons.receipt_long,
        'color': Colors.green,
        'count': '3 Dokumente',
      },
      {
        'title': 'Protokolle',
        'subtitle': 'Übergabe- und Abnahmeprotokolle',
        'icon': Icons.checklist,
        'color': Colors.orange,
        'count': '2 Dokumente',
      },
      {
        'title': 'Korrespondenz',
        'subtitle': 'E-Mails und Briefe',
        'icon': Icons.email,
        'color': Colors.purple,
        'count': '5 Dokumente',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dokumentenkategorien',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(category, colors);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, DynamicAppColors colors) {
    return GestureDetector(
      onTap: () {
        // Navigate to specific document category
        _showComingSoonDialog();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderLight),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (category['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category['icon'] as IconData,
                color: category['color'] as Color,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              category['title'] as String,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category['subtitle'] as String,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.3,
              ),
            ),
            const Spacer(),
            Text(
              category['count'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: category['color'] as Color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n, DynamicAppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schnellaktionen',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Dokument hochladen',
                Icons.cloud_upload,
                colors.primaryAccent,
                () => _showComingSoonDialog(),
                colors,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Support kontaktieren',
                Icons.support_agent,
                Colors.orange,
                () => context.push('/conversations'),
                colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
    DynamicAppColors colors,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceCards,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderLight),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(AppLocalizations l10n, DynamicAppColors colors) {
    final activities = [
      {
        'title': 'Nebenkostenabrechnung 2024',
        'subtitle': 'Vor 2 Tagen hinzugefügt',
        'icon': Icons.receipt,
        'status': 'Neu',
      },
      {
        'title': 'Mietvertrag aktualisiert',
        'subtitle': 'Vor 1 Woche aktualisiert',
        'icon': Icons.description,
        'status': 'Aktualisiert',
      },
      {
        'title': 'Übergabeprotokoll',
        'subtitle': 'Vor 2 Wochen hinzugefügt',
        'icon': Icons.checklist,
        'status': 'Archiviert',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Letzte Aktivitäten',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityItem(activity, colors);
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: colors.primaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(activity['status'] as String).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              activity['status'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(activity['status'] as String),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Neu':
        return Colors.green;
      case 'Aktualisiert':
        return Colors.blue;
      case 'Archiviert':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showComingSoonDialog() {
    final colors = ref.read(dynamicColorsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceCards,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Bald verfügbar',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Text(
          'Diese Funktion wird in einem zukünftigen Update verfügbar sein.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: colors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }
}
