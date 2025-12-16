import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../property/presentation/providers/property_providers.dart';
import '../../../documents/domain/models/document_model.dart';
import '../../../documents/presentation/providers/document_providers.dart';
import '../../../documents/presentation/widgets/document_card.dart';
import '../../../documents/presentation/pages/document_viewer_page.dart';
import '../../../home/presentation/models/dashboard_design.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart';
import '../../../settings/providers/settings_provider.dart';

class LandlordDocumentsPage extends ConsumerStatefulWidget {
  const LandlordDocumentsPage({super.key});

  @override
  ConsumerState<LandlordDocumentsPage> createState() =>
      _LandlordDocumentsPageState();
}

class _LandlordDocumentsPageState extends ConsumerState<LandlordDocumentsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedCategory = 'All'; // Will map to localized 'All'
  String? _selectedPropertyId;
  final Set<String> _selectedTenantIds = {};

  late List<String> _categories; // Populated in didChangeDependencies

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _categories = [
      l10n.all,
      l10n.leaseAgreement,
      l10n.operatingCosts,
      l10n.correspondence,
      l10n.insurance,
      l10n.inspectionReports,
      l10n.legalDocuments,
      l10n.otherCategory,
    ];
  }

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
    final documentsAsync = ref.watch(landlordDocumentsProvider);
    final propertiesAsync = ref.watch(landlordPropertiesProvider);
    final design = dashboardDesignFromId(
      ref.watch(settingsProvider).dashboardDesign,
    );
    final bool glassMode = design == DashboardDesign.glass;

    final actions = <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        color: glassMode ? Colors.white : colors.textPrimary,
        tooltip: l10n.search,
        onPressed: () {
          // TODO: implement search
        },
      ),
      _buildOverflowMenu(colors, l10n, glassMode: glassMode),
    ];

    final Widget content = FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.read(landlordDocumentsProvider.notifier).refresh();
          ref.invalidate(landlordPropertiesProvider);
        },
        color: glassMode ? Colors.white : colors.primaryAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: glassMode
              ? const EdgeInsets.fromLTRB(16, 18, 16, 140)
              : const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(
                currentUser?.fullName ?? 'Landlord',
                colors,
                l10n,
                glassMode: glassMode,
              ),
              const SizedBox(height: 24),
              _buildUploadSection(colors, l10n, glassMode: glassMode),
              const SizedBox(height: 24),
              _buildFilterSection(
                colors,
                propertiesAsync,
                l10n,
                glassMode: glassMode,
              ),
              const SizedBox(height: 24),
              _buildDocumentsList(
                documentsAsync,
                colors,
                l10n,
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
        title: l10n.documentManagement,
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
        child: SafeArea(child: content),
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
        l10n.documentManagement,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: actions,
    );
  }

  Widget _buildOverflowMenu(DynamicAppColors colors, AppLocalizations l10n,
      {required bool glassMode}) {
    final Color iconColor = glassMode ? Colors.white : colors.textPrimary;
    final TextStyle? itemStyle =
        glassMode ? const TextStyle(color: Colors.white) : null;

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: iconColor),
      color: glassMode ? Colors.black.withValues(alpha: 0.8) : null,
      onSelected: (value) {
        switch (value) {
          case 'bulk_upload':
            _bulkUploadDocuments();
            break;
          case 'export':
            _exportDocuments();
            break;
          case 'settings':
            _showDocumentSettings();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'bulk_upload',
          child: Text('Bulk Upload', style: itemStyle),
        ),
        PopupMenuItem(
          value: 'export',
          child: Text('Export List', style: itemStyle),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Text('Settings', style: itemStyle),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(
      String userName, DynamicAppColors colors, AppLocalizations l10n,
      {required bool glassMode}) {
    final primaryText = _primaryTextColor(colors, glassMode);
    final secondaryText = _secondaryTextColor(colors, glassMode);

    final Widget child = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.22)
                : const Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(glassMode ? 20 : 16),
          ),
          child: Icon(
            Icons.folder_shared,
            color: glassMode ? Colors.white : Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.documentsSharedByLandlord,
                style: TextStyle(
                  fontSize: 14,
                  color: secondaryText,
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

  Widget _buildUploadSection(DynamicAppColors colors, AppLocalizations l10n,
      {required bool glassMode}) {
    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickUpload,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _primaryTextColor(colors, glassMode),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickUploadButton(
            colors,
            glassMode: glassMode,
            label: l10n.leaseAgreement,
            icon: Icons.description,
            color: const Color(0xFF2196F3),
            onTap: () => _uploadDocumentWithCategory(l10n.leaseAgreement),
          ),
          const SizedBox(height: 12),
          _buildQuickUploadButton(
            colors,
            glassMode: glassMode,
            label: l10n.notice,
            icon: Icons.announcement,
            color: const Color(0xFFFF9800),
            onTap: () => _uploadDocumentWithCategory(l10n.correspondence),
          ),
          const SizedBox(height: 12),
          _buildQuickUploadButton(
            colors,
            glassMode: glassMode,
            label: l10n.receipt,
            icon: Icons.receipt,
            color: const Color(0xFF4CAF50),
            onTap: () => _uploadDocumentWithCategory(l10n.operatingCosts),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickUploadButton(
    DynamicAppColors colors, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool glassMode,
  }) {
    final borderRadius = BorderRadius.circular(glassMode ? 22 : 16);
    final Color titleColor = glassMode ? Colors.white : colors.textPrimary;
    final Color arrowColor =
        glassMode ? Colors.white.withValues(alpha: 0.8) : colors.textSecondary;
    final Color chipBackground =
        glassMode ? Colors.white.withValues(alpha: 0.16) : color;

    final child = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: chipBackground,
            borderRadius: BorderRadius.circular(glassMode ? 16 : 12),
          ),
          child: Icon(
            icon,
            color: glassMode ? Colors.white : Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: titleColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: arrowColor,
        ),
      ],
    );

    if (glassMode) {
      return Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
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
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: borderRadius,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
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

  Widget _buildFilterSection(
    DynamicAppColors colors,
    AsyncValue<List<dynamic>> propertiesAsync,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final titleColor = _primaryTextColor(colors, glassMode);
    final hintColor = _secondaryTextColor(colors, glassMode);

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.filterDocuments,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.category,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hintColor,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final bool isSelected = _selectedCategory == category;
                final Color background = glassMode
                    ? (isSelected
                        ? Colors.white.withValues(alpha: 0.28)
                        : Colors.white.withValues(alpha: 0.12))
                    : colors.surfaceSecondary;
                final Color borderColor = glassMode
                    ? Colors.white.withValues(alpha: isSelected ? 0.5 : 0.2)
                    : (isSelected
                        ? const Color(0xFF2E7D32)
                        : colors.borderLight);
                final Color textColor = glassMode
                    ? Colors.white
                    : (isSelected ? Colors.white : colors.textPrimary);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: borderColor,
                            width: isSelected ? 1.6 : 1,
                          ),
                          gradient: !glassMode && isSelected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF2E7D32),
                                    Color(0xFF66BB6A),
                                  ],
                                )
                              : null,
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.property,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hintColor,
            ),
          ),
          const SizedBox(height: 10),
          propertiesAsync.when(
            data: (properties) {
              if (_selectedPropertyId != null &&
                  !properties.any((p) => p.id == _selectedPropertyId)) {
                _selectedPropertyId = null;
              }

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: glassMode
                        ? Colors.white.withValues(alpha: 0.24)
                        : colors.borderLight,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPropertyId,
                    isExpanded: true,
                    hint: Text(
                      l10n.allProperties,
                      style: TextStyle(color: hintColor),
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: glassMode ? Colors.white : colors.textPrimary,
                    ),
                    dropdownColor:
                        glassMode ? Colors.black87 : colors.surfaceCards,
                    style: TextStyle(
                      color: glassMode ? Colors.white : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          l10n.allProperties,
                          style: TextStyle(
                            color:
                                glassMode ? Colors.white : colors.textPrimary,
                          ),
                        ),
                      ),
                      ...properties.map((property) => DropdownMenuItem<String>(
                            value: property.id,
                            child: Text(
                              '${property.address.street}, ${property.address.city}',
                              style: TextStyle(
                                color: glassMode
                                    ? Colors.white
                                    : colors.textPrimary,
                              ),
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPropertyId = value;
                        _selectedTenantIds.clear();
                      });
                    },
                  ),
                ),
              );
            },
            loading: () => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: glassMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : colors.surfaceSecondary,
                border: Border.all(
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.25)
                      : colors.borderLight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        glassMode ? Colors.white : colors.primaryAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.loadingProperties,
                    style: TextStyle(color: hintColor),
                  ),
                ],
              ),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: glassMode
                    ? Colors.redAccent.withValues(alpha: 0.16)
                    : colors.error.withValues(alpha: 0.1),
                border: Border.all(
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.4)
                      : colors.error,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: glassMode ? Colors.white : colors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.errorLoadingProperties,
                    style: TextStyle(
                      color: glassMode ? Colors.white : colors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(
    AsyncValue<List<DocumentModel>> documentsAsync,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final titleColor = _primaryTextColor(colors, glassMode);
    final secondary = _secondaryTextColor(colors, glassMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.documentLibrary,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 16),
        documentsAsync.when(
          data: (documents) {
            // Apply filters
            var filteredDocs = documents;

            if (_selectedCategory != 'All') {
              filteredDocs = filteredDocs
                  .where((doc) => doc.category == _selectedCategory)
                  .toList();
            }

            if (_selectedPropertyId != null) {
              filteredDocs = filteredDocs
                  .where((doc) =>
                      doc.metadata?['propertyId'] == _selectedPropertyId)
                  .toList();
            }

            if (filteredDocs.isEmpty) {
              return _buildEmptyState(colors, l10n, glassMode: glassMode);
            }

            return Column(
              children: filteredDocs
                  .map((document) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DocumentCard(
                          document: document,
                          onTap: () => _viewDocument(document),
                          onDownload: () => _downloadDocument(document),
                          onDelete: () => _deleteDocument(document),
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
                        CircularProgressIndicator(
                          color: colors.primaryAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.loadingDocuments,
                          style: TextStyle(color: secondary),
                        ),
                      ],
                    ),
            ),
          ),
          error: (error, stack) =>
              _buildErrorState(error, colors, l10n, glassMode: glassMode),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final titleColor = _primaryTextColor(colors, glassMode);
    final secondary = _secondaryTextColor(colors, glassMode);

    return _sectionCard(
      colors: colors,
      glassMode: glassMode,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
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
            l10n.noDocumentsFound,
            style: TextStyle(
              color: titleColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.uploadFirstDocument,
            style: TextStyle(
              color: secondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _uploadDocument,
            icon: const Icon(Icons.upload_file),
            label: Text(l10n.uploadDocument),
            style: ElevatedButton.styleFrom(
              backgroundColor: glassMode ? Colors.white : colors.primaryAccent,
              foregroundColor: glassMode ? Colors.black87 : colors.textOnAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    Object error,
    DynamicAppColors colors,
    AppLocalizations l10n, {
    required bool glassMode,
  }) {
    final Color background = glassMode
        ? Colors.redAccent.withValues(alpha: 0.18)
        : colors.errorLight;
    final Color textColor = glassMode ? Colors.white : colors.error;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: glassMode
              ? Colors.white.withValues(alpha: 0.35)
              : colors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: textColor,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.errorLoadingDocuments,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.85),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(landlordDocumentsProvider.notifier).refresh(),
            style: ElevatedButton.styleFrom(
              backgroundColor: glassMode ? Colors.white : colors.error,
              foregroundColor: glassMode ? Colors.black87 : colors.textOnAccent,
            ),
            child: Text(l10n.retry),
          ),
        ],
      ),
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

  void _uploadDocument() async {
    // Use localized "Other" category so the dropdown initialValue matches items in non-English locales
    final l10n = AppLocalizations.of(context)!;
    _uploadDocumentWithCategory(l10n.otherCategory);
  }

  void _uploadDocumentWithCategory(String category) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null) {
        await _showDocumentUploadDialog(result.files.first, category);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick file: $e');
    }
  }

  Future<void> _showDocumentUploadDialog(
      PlatformFile file, String category) async {
    final propertiesAsync = ref.read(landlordPropertiesProvider);

    String selectedCategory = category;
    String? selectedPropertyId;
    final Set<String> selectedTenantIds = {};
    String documentName = file.name;
    String description = '';

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.uploadDocument,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.fileLabel}: ${file.name}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${AppLocalizations.of(context)!.sizeLabel}: ${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.documentName,
                      border: const OutlineInputBorder(),
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    controller: TextEditingController(text: documentName),
                    onChanged: (value) => documentName = value,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.descriptionOptional,
                      border: const OutlineInputBorder(),
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    maxLines: 3,
                    onChanged: (value) => description = value,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.category,
                      border: const OutlineInputBorder(),
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    items: _categories
                        .skip(1)
                        .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              style:
                                  TextStyle(color: theme.colorScheme.onSurface),
                            )))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedCategory = value!),
                  ),
                  const SizedBox(height: 16),
                  propertiesAsync.when(
                    data: (properties) => DropdownButtonFormField<String>(
                      initialValue: selectedPropertyId,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!
                            .assignToPropertyOptional,
                        border: const OutlineInputBorder(),
                      ),
                      dropdownColor: theme.colorScheme.surface,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            AppLocalizations.of(context)!.noSpecificProperty,
                            style:
                                TextStyle(color: theme.colorScheme.onSurface),
                          ),
                        ),
                        ...properties
                            .map((property) => DropdownMenuItem<String>(
                                  value: property.id,
                                  child: Text(
                                    '${property.address.street}, ${property.address.city}',
                                    style: TextStyle(
                                        color: theme.colorScheme.onSurface),
                                  ),
                                )),
                      ],
                      onChanged: (value) => setState(() {
                        selectedPropertyId = value;
                        selectedTenantIds.clear();
                      }),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => Text(
                      AppLocalizations.of(context)!.errorLoadingProperties,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _processDocumentUpload(
                    file,
                    documentName,
                    description,
                    selectedCategory,
                    selectedPropertyId,
                    selectedTenantIds,
                  );
                },
                child: Text(AppLocalizations.of(context)!.upload),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processDocumentUpload(
    PlatformFile file,
    String name,
    String description,
    String category,
    String? propertyId,
    Set<String> tenantIds,
  ) async {
    try {
      final l10nUpload = AppLocalizations.of(context)!;
      _showInfoSnackBar(l10nUpload.downloadingDocument(file.name));
      // Normalize category: convert localized label back to internal canonical label set to avoid duplicate 'Other'
      final lc = category.toLowerCase();
      final l10n = AppLocalizations.of(context)!;
      final canonicalMap = <String, String>{
        l10n.leaseAgreement.toLowerCase(): l10n.leaseAgreement,
        l10n.operatingCosts.toLowerCase(): l10n.operatingCosts,
        l10n.correspondence.toLowerCase(): l10n.correspondence,
        l10n.insurance.toLowerCase(): l10n.insurance,
        l10n.inspectionReports.toLowerCase(): l10n.inspectionReports,
        l10n.legalDocuments.toLowerCase(): l10n.legalDocuments,
        l10n.otherCategory.toLowerCase(): l10n.otherCategory,
      };
      category = canonicalMap[lc] ?? category;

      final authState = ref.read(authProvider);
      if (authState.userId == null) {
        _showErrorSnackBar(l10nUpload.pleaseLoginToUploadDocuments);
        return;
      }

      final documentService = ref.read(documentServiceProvider);
      await documentService.uploadDocument(
        file: file,
        name: name,
        description: description,
        category: category,
        uploadedBy: authState.userId!,
        propertyId: propertyId,
        tenantIds: tenantIds.toList(),
      );

      ref.read(landlordDocumentsProvider.notifier).refresh();
      _showSuccessSnackBar(l10nUpload.documentUploadedSuccessfully(file.name));
    } catch (e) {
      final l10nUpload = AppLocalizations.of(context)!;
      _showErrorSnackBar(l10nUpload.failedToUploadDocumentGeneric(e));
    }
  }

  void _bulkUploadDocuments() {
    final l10n = AppLocalizations.of(context)!;
    _showInfoSnackBar(l10n.featureComingSoonTitle);
  }

  void _exportDocuments() {
    final l10n = AppLocalizations.of(context)!;
    _showInfoSnackBar(l10n.featureComingSoonTitle);
  }

  void _showDocumentSettings() {
    final l10n = AppLocalizations.of(context)!;
    _showInfoSnackBar(l10n.featureComingSoonTitle);
  }

  void _viewDocument(DocumentModel document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentViewerPage(document: document),
      ),
    );
  }

  void _downloadDocument(DocumentModel document) async {
    try {
      _showInfoSnackBar(
          AppLocalizations.of(context)!.downloadingDocument(document.name));

      final documentService = ref.read(documentServiceProvider);
      await documentService.downloadDocument(document);

      final l10n = AppLocalizations.of(context)!;
      _showSuccessSnackBar(l10n.documentDownloadedSuccessfully(document.name));
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context)!
          .failedToDownloadDocument(document.name));
    }
  }

  void _deleteDocument(DocumentModel document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete),
        content: Text(AppLocalizations.of(context)!.areYouSure),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final documentService = ref.read(documentServiceProvider);
        await documentService.deleteDocument(document.id);

        ref.read(landlordDocumentsProvider.notifier).refresh();
        _showSuccessSnackBar(AppLocalizations.of(context)!
            .documentDeletedSuccessfully(document.name));
      } catch (e) {
        _showErrorSnackBar(
            AppLocalizations.of(context)!.failedToDeleteDocument(e));
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
