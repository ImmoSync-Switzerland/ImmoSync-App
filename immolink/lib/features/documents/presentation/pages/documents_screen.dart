import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/auth/presentation/providers/user_role_provider.dart';
import 'package:immosync/features/documents/domain/models/document_model.dart';
import 'package:immosync/features/documents/presentation/pages/document_viewer_page.dart';
import 'package:immosync/features/documents/presentation/providers/document_providers.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  static const _bgTop = Color(0xFF0A1128);
  static const _bgBottom = Colors.black;
  static const _card = Color(0xFF1C1C1E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final path = GoRouterState.of(context).uri.path;
    final isLandlord = role == 'landlord' || path.startsWith('/landlord/');
    final documentsAsync = ref.watch(
      isLandlord ? landlordDocumentsProvider : tenantDocumentsProvider,
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
          const SnackBar(content: Text('Please sign in again.')),
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
            const SnackBar(content: Text('Document uploaded.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).maybePop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')),
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
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          tooltip: 'Back',
        ),
        title: const Text(
          'Documents',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            tooltip: 'Filter',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
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
                    'Failed to load documents: $e',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            data: (docs) {
              final documents = List<DocumentModel>.from(docs)
                ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
              final recent = documents.take(20).toList();
              final totalBytes =
                  documents.fold<int>(0, (sum, d) => sum + d.fileSize);
              final subtitle =
                  '${documents.length} Files • ${_formatTotalSize(totalBytes)} Used';

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
                                        ? 'Document Management'
                                        : 'My Documents',
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
                      const Text(
                        'Upload New',
                        style: TextStyle(
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
                              label: 'Lease',
                              icon: Icons.description_rounded,
                              onTap: () => uploadQuick('Lease Agreement'),
                            ),
                            const SizedBox(width: 12),
                            _QuickActionCard(
                              label: 'Receipt',
                              icon: Icons.receipt_long_rounded,
                              onTap: () => uploadQuick('Operating Costs'),
                            ),
                            const SizedBox(width: 12),
                            _QuickActionCard(
                              label: 'Notice',
                              icon: Icons.campaign_rounded,
                              onTap: () => uploadQuick('Correspondence'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Recent Files',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (recent.isEmpty)
                        const _BentoCard(
                          child: Text(
                            'No documents yet.',
                            style: TextStyle(
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
                                        tooltip: 'More',
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
