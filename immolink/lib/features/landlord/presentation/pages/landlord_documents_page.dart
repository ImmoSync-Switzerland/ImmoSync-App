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
  Set<String> _selectedTenantIds = {};

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(l10n, colors),
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(landlordDocumentsProvider.notifier).refresh();
                ref.invalidate(landlordPropertiesProvider);
              },
              color: colors.primaryAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(
                        currentUser?.fullName ?? 'Landlord', colors),
                    const SizedBox(height: 24),
                    _buildUploadSection(colors),
                    const SizedBox(height: 24),
                    _buildFilterSection(colors, propertiesAsync),
                    const SizedBox(height: 24),
                    _buildDocumentsList(documentsAsync, colors),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(
      AppLocalizations l10n, DynamicAppColors colors) {
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
      actions: [
        IconButton(
          onPressed: () {
            // Add search functionality
          },
          icon: Icon(Icons.search, color: colors.textPrimary),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: colors.textPrimary),
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
            const PopupMenuItem(
                value: 'bulk_upload', child: Text('Bulk Upload')),
            const PopupMenuItem(value: 'export', child: Text('Export List')),
            const PopupMenuItem(value: 'settings', child: Text('Settings')),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(String userName, DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE3F2FD), // Light blue
            const Color(0xFFBBDEFB), // Lighter blue
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3), // Blue
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.folder_shared,
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
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.documentsSharedByLandlord,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(DynamicAppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
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
          Text(
            AppLocalizations.of(context)!.quickUpload,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickUploadButton(
            AppLocalizations.of(context)!.leaseAgreement,
            Icons.description,
            const Color(0xFF2196F3), // Blue
            () => _uploadDocumentWithCategory(
                AppLocalizations.of(context)!.leaseAgreement),
          ),
          const SizedBox(height: 12),
          _buildQuickUploadButton(
            AppLocalizations.of(context)!.notice,
            Icons.announcement,
            const Color(0xFFFF9800), // Orange
            () => _uploadDocumentWithCategory(
                AppLocalizations.of(context)!.correspondence),
          ),
          const SizedBox(height: 12),
          _buildQuickUploadButton(
            AppLocalizations.of(context)!.receipt,
            Icons.receipt,
            const Color(0xFF4CAF50), // Green
            () => _uploadDocumentWithCategory(
                AppLocalizations.of(context)!.operatingCosts),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickUploadButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    final colors = ref.watch(dynamicColorsProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
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
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
      DynamicAppColors colors, AsyncValue<List<dynamic>> propertiesAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderLight),
        boxShadow: [
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
          Text(
            AppLocalizations.of(context)!.filterDocuments,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Category filter
          Text(
            AppLocalizations.of(context)!.category,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories
                  .map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: _selectedCategory == category
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFF2E7D32),
                                        const Color(0xFF66BB6A),
                                      ],
                                    )
                                  : null,
                              color: _selectedCategory == category
                                  ? null
                                  : colors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedCategory == category
                                    ? const Color(0xFF2E7D32)
                                    : colors.borderLight,
                                width: _selectedCategory == category ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedCategory == category
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _selectedCategory == category
                                    ? Colors.white
                                    : colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Property filter
          Text(
            AppLocalizations.of(context)!.property,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          propertiesAsync.when(
            data: (properties) {
              // Ensure current selected property still exists; else reset to null
              if (_selectedPropertyId != null &&
                  !properties.any((p) => p.id == _selectedPropertyId)) {
                _selectedPropertyId = null;
              }
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPropertyId,
                    isExpanded: true,
                    hint: Text(
                      AppLocalizations.of(context)!.allProperties,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    icon:
                        Icon(Icons.arrow_drop_down, color: colors.textPrimary),
                    dropdownColor: colors.surfaceCards,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          AppLocalizations.of(context)!.allProperties,
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      ),
                      ...properties.map((property) => DropdownMenuItem<String>(
                            value: property.id,
                            child: Text(
                              '${property.address.street}, ${property.address.city}',
                              style: TextStyle(color: colors.textPrimary),
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
                color: colors.surfaceSecondary,
                border: Border.all(color: colors.borderLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colors.primaryAccent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.loadingProperties,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                border: Border.all(color: colors.error),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colors.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.errorLoadingProperties,
                    style: TextStyle(color: colors.error),
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
      AsyncValue<List<DocumentModel>> documentsAsync, DynamicAppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.documentLibrary,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
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
              return _buildEmptyState(colors);
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
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: colors.primaryAccent),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.loadingDocuments,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          error: (error, stack) => _buildErrorState(error, colors),
        ),
      ],
    );
  }

  Widget _buildEmptyState(DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noDocumentsFound,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.uploadFirstDocument,
              style: TextStyle(
                color: colors.textSecondary,
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
                backgroundColor: colors.primaryAccent,
                foregroundColor: colors.textOnAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, DynamicAppColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error,
              size: 48,
              color: colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingDocuments,
              style: TextStyle(
                color: colors.error,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                color: colors.error,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(landlordDocumentsProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.textOnAccent,
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  void _uploadDocument() async {
    // Use localized "Other" category so the dropdown initialValue matches items in non-English locales
    final l10n = AppLocalizations.of(context)!;
    _uploadDocumentWithCategory(l10n.otherCategory);
  }

  void _uploadDocumentWithCategory(String category) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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
    Set<String> selectedTenantIds = {};
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
                      border: OutlineInputBorder(),
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
                      border: OutlineInputBorder(),
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
                      border: OutlineInputBorder(),
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
                        border: OutlineInputBorder(),
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
