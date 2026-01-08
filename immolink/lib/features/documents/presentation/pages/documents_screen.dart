import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:immosync/l10n/app_localizations.dart';

import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/auth/presentation/providers/user_role_provider.dart';
import 'package:immosync/features/documents/domain/models/document_model.dart';
import 'package:immosync/features/documents/presentation/pages/document_viewer_page.dart';
import 'package:immosync/features/documents/presentation/providers/document_providers.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();

  static const _bgTop = Color(0xFF0A1128);
  static const _bgBottom = Colors.black;
  static const _card = Color(0xFF1C1C1E);

  static const _categoryAll = '__all__';

  // Canonical category names (see DocumentModel._normalizeCategory)
  static const _categoryLease = 'Lease Agreement';
  static const _categoryOperatingCosts = 'Operating Costs';
  static const _categoryCorrespondence = 'Correspondence';
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = DocumentsScreen._categoryAll;

  String _categoryLabel(AppLocalizations l10n, String category) {
    switch (category) {
      case DocumentsScreen._categoryAll:
        return l10n.all;
      case DocumentsScreen._categoryLease:
        return l10n.leaseAgreement;
      case DocumentsScreen._categoryOperatingCosts:
        return l10n.operatingCosts;
      case DocumentsScreen._categoryCorrespondence:
        return l10n.correspondence;
      default:
        return category;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearchSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(left: 12, right: 12, bottom: bottomInset),
          child: Container(
            decoration: BoxDecoration(
              color: DocumentsScreen._card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.search,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    hintStyle: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white70,
                    ),
                    suffixIcon: _searchController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                            ),
                            tooltip: l10n.close,
                          ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      l10n.filter,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _categoryLabel(l10n, _selectedCategory),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFilterSheet(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final options = <String>[
          DocumentsScreen._categoryAll,
          DocumentsScreen._categoryLease,
          DocumentsScreen._categoryOperatingCosts,
          DocumentsScreen._categoryCorrespondence,
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Container(
            decoration: BoxDecoration(
              color: DocumentsScreen._card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.filter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        itemBuilder: (context, index) {
                          final value = options[index];
                          final label = _categoryLabel(l10n, value);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            trailing: value == _selectedCategory
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedCategory = value;
                              });
                              Navigator.of(sheetContext).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final role = ref.watch(userRoleProvider);
    final path = GoRouterState.of(context).uri.path;
    final isLandlord = role == 'landlord' || path.startsWith('/landlord/');
    final documentsAsync = ref.watch(
      isLandlord
          ? landlordVisibleDocumentsProvider
          : tenantVisibleDocumentsProvider,
    );

    final userId =
        ref.watch(currentUserProvider)?.id ?? ref.watch(authProvider).userId;

    Future<void> refresh() async {
      if (isLandlord) {
        ref.read(landlordDocumentsProvider.notifier).refresh();
      } else {
        await ref.read(tenantDocumentsProvider.notifier).refresh();
      }
    }

    Future<void> uploadQuick(String category) async {
      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pleaseLoginToUploadDocuments)),
        );
        return;
      }

      try {
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const [
            'pdf',
            'doc',
            'docx',
            'txt',
            'png',
            'jpg',
            'jpeg'
          ],
          allowMultiple: false,
          withData: true,
        );

        if (picked == null || picked.files.isEmpty) return;
        final file = picked.files.first;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );

        final documentService = ref.read(documentServiceProvider);
        await documentService.uploadDocument(
          file: file,
          name: file.name,
          description: '',
          category: category,
          uploadedBy: userId,
        );

        await refresh();
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.documentUploadedSuccessfully(file.name)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).maybePop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToUploadDocumentGeneric(e.toString())),
            ),
          );
        }
      }
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(
            Icons.chevron_left,
            color: Colors.white,
            size: 32,
          ),
          tooltip: l10n.back,
        ),
        title: Text(
          l10n.documents,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _openSearchSheet(context, l10n),
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            tooltip: l10n.search,
          ),
          IconButton(
            onPressed: () {
              _openFilterSheet(context, l10n);
            },
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            tooltip: l10n.filter,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [DocumentsScreen._bgTop, DocumentsScreen._bgBottom],
          ),
        ),
        child: SafeArea(
          child: documentsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _BentoCard(
                  child: Text(
                    '${l10n.errorLoadingDocuments}: ${e.toString()}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            data: (docs) {
              final query = _searchController.text.trim().toLowerCase();

              final allDocuments = List<DocumentModel>.from(docs)
                ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));

              final filteredDocuments = allDocuments.where((doc) {
                final matchesCategory =
                    _selectedCategory == DocumentsScreen._categoryAll ||
                        doc.category == _selectedCategory;
                if (!matchesCategory) return false;
                if (query.isEmpty) return true;

                final haystack =
                    '${doc.name} ${doc.description} ${doc.category}'
                        .toLowerCase();
                return haystack.contains(query);
              }).toList(growable: false);

              final showAllMatches = query.isNotEmpty ||
                  _selectedCategory != DocumentsScreen._categoryAll;
              final recent = showAllMatches
                  ? filteredDocuments
                  : filteredDocuments.take(20).toList(growable: false);

              final totalBytes = filteredDocuments.fold<int>(
                0,
                (sum, d) => sum + d.fileSize,
              );
              final subtitle = l10n.documentsStorageSubtitle(
                filteredDocuments.length,
                _formatTotalSize(totalBytes),
              );

              return RefreshIndicator(
                onRefresh: refresh,
                color: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BentoCard(
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.folder_rounded,
                                color: Color(0xFF3B82F6),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isLandlord
                                        ? l10n.documentManagement
                                        : l10n.myDocuments,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.uploadNew,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _QuickActionCard(
                              label: l10n.leaseAgreement,
                              icon: Icons.description_rounded,
                              onTap: () => uploadQuick('Lease Agreement'),
                            ),
                            const SizedBox(width: 12),
                            _QuickActionCard(
                              label: l10n.operatingCosts,
                              icon: Icons.receipt_long_rounded,
                              onTap: () => uploadQuick('Operating Costs'),
                            ),
                            const SizedBox(width: 12),
                            _QuickActionCard(
                              label: l10n.correspondence,
                              icon: Icons.campaign_rounded,
                              onTap: () => uploadQuick('Correspondence'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.recentFiles,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (recent.isEmpty)
                        _BentoCard(
                          child: Text(
                            l10n.noDocumentsAvailable,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recent.length,
                          itemBuilder: (context, index) {
                            final doc = recent[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == recent.length - 1 ? 0 : 10,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DocumentViewerPage(document: doc),
                                    ),
                                  );
                                },
                                child: _BentoCard(
                                  child: Row(
                                    children: [
                                      _FileTypeIconBox(fileName: doc.name),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_formatDate(doc.uploadDate)} • ${doc.formattedFileSize}',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        onPressed: () {
                                          // Viewer page has download/open actions; keep this minimal.
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DocumentViewerPage(
                                                document: doc,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.more_horiz_rounded,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        tooltip: l10n.more,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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
}

String _formatDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

String _formatTotalSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const kb = 1024;
  const mb = 1024 * 1024;
  const gb = 1024 * 1024 * 1024;
  if (bytes < kb) return '$bytes B';
  if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
  if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / gb).toStringAsFixed(1)} GB';
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DocumentsScreen._card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = DocumentsScreen._card;
    final pressedColor = Colors.white.withValues(alpha: 0.06);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 110,
        decoration: BoxDecoration(
          color: _pressed ? pressedColor : baseColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Colors.white, size: 26),
            const SizedBox(height: 10),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTypeIconBox extends StatelessWidget {
  const _FileTypeIconBox({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    final ext = fileName.toLowerCase();

    final bool isPdf = ext.endsWith('.pdf');
    final bool isImage = ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.webp');
    final bool isDoc = ext.endsWith('.doc') || ext.endsWith('.docx');

    final IconData icon;
    final Color color;

    if (isPdf) {
      icon = Icons.picture_as_pdf_rounded;
      color = const Color(0xFFEF4444);
    } else if (isImage) {
      icon = Icons.image_rounded;
      color = const Color(0xFF3B82F6);
    } else if (isDoc) {
      icon = Icons.description_rounded;
      color = const Color(0xFF3B82F6);
    } else {
      icon = Icons.insert_drive_file_rounded;
      color = Colors.white70;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
