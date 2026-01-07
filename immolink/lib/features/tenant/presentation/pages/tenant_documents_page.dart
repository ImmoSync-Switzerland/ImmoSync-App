import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../home/presentation/models/dashboard_design.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../documents/presentation/providers/document_providers.dart';
import '../../../documents/presentation/widgets/document_card.dart';
import '../../../documents/domain/models/document_model.dart';
import '../../../documents/presentation/pages/document_viewer_page.dart';
import '../../../documents/presentation/pages/documents_screen.dart';

class TenantDocumentsPage extends StatelessWidget {
  const TenantDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DocumentsScreen();
  }
}

class LegacyTenantDocumentsPage extends ConsumerStatefulWidget {
  const LegacyTenantDocumentsPage({super.key});

  @override
  ConsumerState<LegacyTenantDocumentsPage> createState() =>
      _LegacyTenantDocumentsPageState();
}

class _LegacyTenantDocumentsPageState
    extends ConsumerState<LegacyTenantDocumentsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Map<String, int> _categoryCounts = {};
  String? _selectedCategory; // null = all categories

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadCategoryCounts();
  }

  void _loadCategoryCounts() async {
    final authState = ref.read(authProvider);
    if (authState.userId != null) {
      final documentService = ref.read(documentServiceProvider);
      final counts =
          await documentService.getDocumentCountsByCategory(authState.userId!);
      if (mounted) {
        setState(() {
          _categoryCounts = counts;
        });
      }
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

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
    final documentsAsync = ref.watch(tenantDocumentsProvider);
    final recentDocuments = ref.watch(recentDocumentsProvider);
    final documentStats = ref.watch(documentStatsProvider);
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );
    final bool glassMode = design == DashboardDesign.glass;
    final List<Widget> actions = [
      IconButton(
        icon: const Icon(Icons.more_horiz),
        tooltip: l10n.more,
        onPressed: _showComingSoonDialog,
        color: glassMode ? Colors.white : colors.textPrimary,
      ),
    ];

    final Widget content = FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.read(tenantDocumentsProvider.notifier).refresh();
        },
        color: glassMode ? Colors.white : colors.primaryAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: glassMode
              ? const EdgeInsets.fromLTRB(16, 18, 16, 120)
              : const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(
                currentUser?.fullName ?? '',
                l10n,
                colors,
                glassMode: glassMode,
              ),
              const SizedBox(height: 24),
              _buildDocumentStats(
                documentStats,
                colors,
                glassMode: glassMode,
              ),
              const SizedBox(height: 32),
              _buildDocumentCategories(
                l10n,
                colors,
                glassMode: glassMode,
              ),
              const SizedBox(height: 24),
              _buildQuickActions(
                l10n,
                colors,
                glassMode: glassMode,
              ),
              const SizedBox(height: 24),
              _buildRecentDocuments(
                recentDocuments,
                l10n,
                colors,
                glassMode: glassMode,
              ),
              const SizedBox(height: 24),
              _buildAllDocuments(
                documentsAsync,
                l10n,
                colors,
                glassMode: glassMode,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );

    if (glassMode) {
      return GlassPageScaffold(
        title: l10n.myDocuments,
        actions: actions,
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(l10n, colors, actions: actions),
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
          child: content,
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(
      AppLocalizations l10n, DynamicAppColors colors,
      {required List<Widget> actions}) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        l10n.myDocuments,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: actions,
    );
  }

  Widget _buildWelcomeSection(
      String userName, AppLocalizations l10n, DynamicAppColors colors,
      {bool glassMode = false}) {
    final Widget child = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.folder_special,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome,',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.85)
                      : colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName.isEmpty ? 'User' : userName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: glassMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tenantDocumentsIntro,
                style: TextStyle(
                  fontSize: 14,
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.85)
                      : colors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (glassMode) {
      return GlassContainer(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: child,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE3F2FD),
            Color(0xFFBBDEFB),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n, DynamicAppColors colors,
      {required bool glassMode}) {
    return Column(
      children: [
        _buildActionButton(
          l10n.upload,
          Icons.cloud_upload,
          const Color(0xFF2196F3),
          _uploadDocument,
          colors,
          glassMode: glassMode,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          l10n.contactSupport,
          Icons.support_agent,
          const Color(0xFFFF9800),
          () => context.push('/contact-support'),
          colors,
          glassMode: glassMode,
        ),
      ],
    );
  }

  String _docPluralSuffix(int count, String localeName) {
    if (count == 1) return '';
    switch (localeName) {
      case 'de':
        return 'e';
      case 'it':
        return 'i';
      default:
        return 's';
    }
  }

  Widget _buildDocumentCategories(
      AppLocalizations l10n, DynamicAppColors colors,
      {required bool glassMode}) {
    final categories = [
      {
        'title': l10n.leaseAgreement,
        'subtitle': l10n.leaseAgreementSubtitle,
        'icon': Icons.description,
        'color': Colors.blue,
        'count': l10n.documentsCount(
            (_categoryCounts['Mietvertrag'] ?? 0).toString(),
            _docPluralSuffix(
                _categoryCounts['Mietvertrag'] ?? 0, l10n.localeName)),
      },
      {
        'title': l10n.operatingCosts,
        'subtitle': l10n.operatingCostsSubtitle,
        'icon': Icons.receipt_long,
        'color': Colors.green,
        'count': l10n.documentsCount(
            (_categoryCounts['Nebenkosten'] ?? 0).toString(),
            _docPluralSuffix(
                _categoryCounts['Nebenkosten'] ?? 0, l10n.localeName)),
      },
      {
        'title': l10n.protocols,
        'subtitle': l10n.protocolsSubtitle,
        'icon': Icons.checklist,
        'color': Colors.orange,
        'count': l10n.documentsCount(
            (_categoryCounts['Protokolle'] ?? 0).toString(),
            _docPluralSuffix(
                _categoryCounts['Protokolle'] ?? 0, l10n.localeName)),
      },
      {
        'title': l10n.correspondence,
        'subtitle': l10n.correspondenceSubtitle,
        'icon': Icons.email,
        'color': Colors.purple,
        'count': l10n.documentsCount(
            (_categoryCounts['Korrespondenz'] ?? 0).toString(),
            _docPluralSuffix(
                _categoryCounts['Korrespondenz'] ?? 0, l10n.localeName)),
      },
    ];

    final titleColor = _primaryTextColor(colors, glassMode);
    final subtitleColor = _secondaryTextColor(colors, glassMode);
    final resetColor = glassMode ? Colors.white : colors.primaryAccent;

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.documentCategories,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              if (_selectedCategory != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                  icon: Icon(Icons.clear,
                      size: 18, color: resetColor.withValues(alpha: 0.85)),
                  label: Text(
                    l10n.viewAll,
                    style: TextStyle(color: resetColor),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: resetColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final crossAxisCount = screenWidth > 600 ? 3 : 2;
              const crossAxisSpacing = 14.0;
              const mainAxisSpacing = 14.0;
              final itemWidth =
                  (screenWidth - (crossAxisSpacing * (crossAxisCount - 1))) /
                      crossAxisCount;
              final childAspectRatio = itemWidth / 122;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final categoryKey = _getCategoryKey(index);
                  final bool isSelected = _selectedCategory == categoryKey;
                  final Color accent = category['color'] as Color;
                  final Color background = isSelected
                      ? accent.withValues(alpha: glassMode ? 0.26 : 0.15)
                      : glassMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : colors.surfaceSecondary;
                  final Color borderColor = isSelected
                      ? (glassMode
                          ? Colors.white.withValues(alpha: 0.45)
                          : accent)
                      : glassMode
                          ? Colors.white.withValues(alpha: 0.18)
                          : colors.borderLight;

                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(glassMode ? 22 : 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(glassMode ? 22 : 16),
                      onTap: () {
                        setState(() {
                          _selectedCategory = isSelected ? null : categoryKey;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius:
                              BorderRadius.circular(glassMode ? 22 : 16),
                          border: Border.all(
                            color: borderColor,
                            width: isSelected ? 1.8 : 1.2,
                          ),
                          boxShadow: glassMode
                              ? []
                              : [
                                  BoxShadow(
                                    color: colors.shadowColor,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(
                                      alpha: glassMode ? 0.24 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        glassMode ? 14 : 10),
                                  ),
                                  child: Icon(
                                    category['icon'] as IconData,
                                    color: glassMode ? Colors.white : accent,
                                    size: 20,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  category['count'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: glassMode ? Colors.white : accent,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              category['title'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              category['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: subtitleColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final borderRadius = BorderRadius.circular(glassMode ? 24 : 16);
    final Color titleColor = glassMode ? Colors.white : colors.textPrimary;
    final Color arrowColor =
        glassMode ? Colors.white.withValues(alpha: 0.8) : colors.textSecondary;
    final Color iconBackground = glassMode
        ? Colors.white.withValues(alpha: 0.16)
        : accentColor.withValues(alpha: 0.12);

    final Widget child = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(glassMode ? 16 : 12),
          ),
          child: Icon(
            icon,
            color: glassMode ? Colors.white : accentColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: arrowColor,
        ),
      ],
    );

    void handleTap() {
      HapticFeedback.lightImpact();
      onTap();
    }

    if (glassMode) {
      return Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: handleTap,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: child,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: handleTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceCards,
            borderRadius: borderRadius,
            border: Border.all(color: colors.borderLight),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDocumentStats(Map<String, int> stats, DynamicAppColors colors,
      {required bool glassMode}) {
    final l10n = AppLocalizations.of(context)!;
    final dividerColor = glassMode
        ? Colors.white.withValues(alpha: 0.25)
        : colors.dividerSeparator;

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              l10n.total,
              '${stats['total'] ?? 0}',
              Icons.folder,
              glassMode ? Colors.white : colors.primaryAccent,
              colors,
              glassMode: glassMode,
            ),
          ),
          Container(width: 1, height: 46, color: dividerColor),
          Expanded(
            child: _buildStatItem(
              l10n.expiring,
              '${stats['expiring'] ?? 0}',
              Icons.warning_rounded,
              glassMode ? Colors.amberAccent : Colors.orange,
              colors,
              glassMode: glassMode,
            ),
          ),
          Container(width: 1, height: 46, color: dividerColor),
          Expanded(
            child: _buildStatItem(
              l10n.expired,
              '${stats['expired'] ?? 0}',
              Icons.error_rounded,
              glassMode ? Colors.redAccent.shade100 : Colors.red,
              colors,
              glassMode: glassMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final textColor = _primaryTextColor(colors, glassMode);
    final hintColor = _secondaryTextColor(colors, glassMode);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDocuments(
    List<DocumentModel> documents,
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final filteredDocuments = _filterDocumentsByCategory(documents);
    final titleColor = _primaryTextColor(colors, glassMode);
    final actionColor = glassMode ? Colors.white : colors.primaryAccent;
    final emptyIconColor =
        glassMode ? Colors.white.withValues(alpha: 0.6) : colors.textSecondary;
    final emptyTextColor = _secondaryTextColor(colors, glassMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentDocuments,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            if (filteredDocuments.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Show all documents
                },
                child: Text(
                  l10n.viewAll,
                  style: TextStyle(color: actionColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (filteredDocuments.isEmpty)
          _sectionCard(
            colors: colors,
            glassMode: glassMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 56,
                  color: emptyIconColor,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noRecentDocuments,
                  style: TextStyle(
                    color: emptyTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.documentsSharedByLandlord,
                  style: TextStyle(
                    color: emptyTextColor,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...filteredDocuments.take(3).map(
                (document) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DocumentCard(
                    document: document,
                    onTap: () => _viewDocument(document),
                    onDownload: () => _downloadDocument(document),
                    onDelete: null,
                    showActions: true,
                    glassMode: glassMode,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildAllDocuments(
    AsyncValue<List<DocumentModel>> documentsAsync,
    AppLocalizations l10n,
    DynamicAppColors colors, {
    required bool glassMode,
  }) {
    final headerColor = _primaryTextColor(colors, glassMode);
    final secondary = _secondaryTextColor(colors, glassMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.allDocumentsHeader,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: headerColor,
          ),
        ),
        const SizedBox(height: 16),
        documentsAsync.when(
          data: (documents) {
            final filteredDocuments = _filterDocumentsByCategory(documents);

            if (filteredDocuments.isEmpty) {
              return _sectionCard(
                colors: colors,
                glassMode: glassMode,
                padding:
                    const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 68,
                      color: secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noDocumentsAvailable,
                      style: TextStyle(
                        color: headerColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.documentsSharedByLandlord,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: filteredDocuments
                  .map((document) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DocumentCard(
                          document: document,
                          onTap: () => _viewDocument(document),
                          onDownload: () => _downloadDocument(document),
                          onDelete: null,
                          showActions: true,
                          glassMode: glassMode,
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: glassMode
                  ? const GlassContainer(
                      padding: EdgeInsets.all(28),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: colors.primaryAccent),
                        const SizedBox(height: 16),
                        Text(
                          l10n.loadingDocuments,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
            ),
          ),
          error: (error, stack) {
            final Color background = glassMode
                ? Colors.redAccent.withValues(alpha: 0.18)
                : colors.errorLight;
            final Color errorColor = glassMode ? Colors.white : colors.error;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.3)
                      : colors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: errorColor),
                  const SizedBox(height: 16),
                  Text(
                    l10n.errorLoadingDocuments,
                    style: TextStyle(
                      color: errorColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      color: errorColor.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(tenantDocumentsProvider.notifier).refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: glassMode ? Colors.white : colors.error,
                      foregroundColor:
                          glassMode ? Colors.black87 : colors.textOnAccent,
                    ),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _sectionCard({
    required DynamicAppColors colors,
    required Widget child,
    required bool glassMode,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    if (glassMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GlassContainer(
          width: double.infinity,
          padding: padding,
          child: child,
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  Color _primaryTextColor(DynamicAppColors colors, bool glassMode) =>
      glassMode ? Colors.white : colors.textPrimary;

  Color _secondaryTextColor(DynamicAppColors colors, bool glassMode) =>
      glassMode ? Colors.white.withValues(alpha: 0.8) : colors.textSecondary;

  void _viewDocument(DocumentModel document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentViewerPage(document: document),
      ),
    );
  }

  void _downloadDocument(DocumentModel document) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.downloadingDocument(document.name)),
          backgroundColor: Colors.green,
        ),
      );

      final documentService = ref.read(documentServiceProvider);
      await documentService.downloadDocument(document);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.documentDownloadedSuccessfully(document.name)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToDownloadDocument(document.name)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Removed unused _buildRecentActivity method

  String _getCategoryKey(int index) {
    // Maps category index to backend category key (English names as stored in DB)
    switch (index) {
      case 0:
        return 'Lease Agreement'; // Mietvertrag
      case 1:
        return 'Operating Costs'; // Nebenkosten (could also be "utilities")
      case 2:
        return 'Inspection Reports'; // Protokolle (could also be "protocols")
      case 3:
        return 'Correspondence'; // Korrespondenz
      default:
        return '';
    }
  }

  List<DocumentModel> _filterDocumentsByCategory(
      List<DocumentModel> documents) {
    if (_selectedCategory == null) {
      return documents; // Show all if no filter selected
    }

    // Case-insensitive comparison and handle variations
    final selectedLower = _selectedCategory!.toLowerCase();
    final filtered = documents.where((doc) {
      final docCategoryLower = doc.category.toLowerCase();

      // Direct match
      if (docCategoryLower == selectedLower) return true;

      // Handle category variations
      if (selectedLower == 'lease agreement' &&
          (docCategoryLower == 'lease' ||
              docCategoryLower == 'lease agreement')) {
        return true;
      }
      if (selectedLower == 'operating costs' &&
          (docCategoryLower == 'utilities' ||
              docCategoryLower == 'operating costs' ||
              docCategoryLower == 'nebenkosten')) {
        return true;
      }
      if (selectedLower == 'inspection reports' &&
          (docCategoryLower == 'protocols' ||
              docCategoryLower == 'inspection reports' ||
              docCategoryLower == 'protokolle')) {
        return true;
      }
      if (selectedLower == 'correspondence' &&
          (docCategoryLower == 'correspondence' ||
              docCategoryLower == 'korrespondenz')) {
        return true;
      }

      return false;
    }).toList();

    return filtered;
  }

  Future<void> _uploadDocument() async {
    final colors = ref.read(dynamicColorsProvider);
    final authState = ref.read(authProvider);

    if (authState.userId == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseLoginToUploadDocuments),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _UploadDocumentDialog(
        onUpload: (name, description, category, file) async {
          try {
            final documentService = ref.read(documentServiceProvider);
            await documentService.uploadDocument(
              file: file,
              name: name,
              description: description,
              category: category,
              uploadedBy: authState.userId!,
            );

            // Refresh the documents and category counts
            _loadCategoryCounts();
            ref.invalidate(tenantDocumentsProvider);

            if (mounted) {
              final l10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.documentUploadedSuccessfully(name)),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              final l10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.failedToUploadDocument(e)),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        colors: colors,
      ),
    );
  }

  void _showComingSoonDialog() {
    final colors = ref.read(dynamicColorsProvider);
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: colors.surfaceCards,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            l10n.featureComingSoonTitle,
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Text(
            l10n.featureComingSoonMessage,
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.ok,
                style: TextStyle(color: colors.primaryAccent),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UploadDocumentDialog extends StatefulWidget {
  final Function(
          String name, String description, String category, PlatformFile file)
      onUpload;
  final DynamicAppColors colors;

  const _UploadDocumentDialog({
    required this.onUpload,
    required this.colors,
  });

  @override
  State<_UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<_UploadDocumentDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Lease Agreement';
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  final List<String> _categories = [
    'Lease Agreement',
    'Operating Costs',
    'Inspection Reports',
    'Correspondence',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _nameController.text = _selectedFile!.name;
        });
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorPickingFile(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectFile),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterName),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await widget.onUpload(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        _selectedCategory,
        _selectedFile!,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error is handled by parent
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: widget.colors.surfaceCards,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.uploadDocument,
        style: TextStyle(color: widget.colors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File picker
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: widget.colors.borderLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null
                        ? Icons.check_circle
                        : Icons.cloud_upload,
                    size: 48,
                    color: _selectedFile != null
                        ? Colors.green
                        : widget.colors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFile?.name ?? l10n.selectFile,
                    style: TextStyle(
                      color: widget.colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${l10n.sizeLabel}: ${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: TextStyle(
                          color: widget.colors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _pickFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.colors.primaryAccent,
                    ),
                    child: Text(l10n.choose),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Document name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.documentName,
                labelStyle: TextStyle(color: widget.colors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.colors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.colors.primaryAccent),
                ),
              ),
              style: TextStyle(color: widget.colors.textPrimary),
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: l10n.category,
                labelStyle: TextStyle(color: widget.colors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.colors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.colors.primaryAccent),
                ),
              ),
              dropdownColor: widget.colors.surfaceCards,
              style: TextStyle(color: widget.colors.textPrimary, fontSize: 16),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    _localizeCategory(l10n, category),
                    style: TextStyle(color: widget.colors.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.descriptionOptional,
                labelStyle: TextStyle(color: widget.colors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.colors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.colors.primaryAccent),
                ),
              ),
              style: TextStyle(color: widget.colors.textPrimary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: TextStyle(color: widget.colors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _upload,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.colors.primaryAccent,
          ),
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(l10n.upload),
        ),
      ],
    );
  }

  String _localizeCategory(AppLocalizations l10n, String category) {
    switch (category) {
      case 'Lease Agreement':
        return l10n.leaseAgreement;
      case 'Operating Costs':
        return l10n.operatingCosts;
      case 'Inspection Reports':
        return l10n.inspectionReports;
      case 'Correspondence':
        return l10n.correspondence;
      case 'Other':
        return l10n.otherCategory;
      default:
        return category;
    }
  }
}
