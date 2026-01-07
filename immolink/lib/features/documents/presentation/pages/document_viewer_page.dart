import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/document_model.dart';
import '../../../../core/config/api_config.dart';

const _backgroundStart = Color(0xFF0A1128);
const _backgroundEnd = Colors.black;
const _cardColor = Color(0xFF1C1C1E);
const _surfaceDark = Color(0xFF2C2C2E);

const _textPrimary = Colors.white;
const _textSecondary = Color(0xFFB0B0B0);

/// Backwards-compatible alias for the requested name.
class DocumentDetailScreen extends DocumentViewerPage {
  const DocumentDetailScreen({super.key, required super.document});
}

class DocumentViewerPage extends ConsumerStatefulWidget {
  final DocumentModel document;

  const DocumentViewerPage({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends ConsumerState<DocumentViewerPage> {
  bool _isLoading = false;
  String? _error;
  Uint8List? _documentData;

  @override
  void initState() {
    super.initState();
    // Auto-load lightweight previews (images & small docs) for better UX
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mime = widget.document.mimeType.toLowerCase();
      final isImage = mime.startsWith('image/');
      final isPdf = mime.contains('pdf');
      final small = widget.document.fileSize < 5 * 1024 * 1024; // <5MB
      if ((isImage || isPdf) && small) {
        _loadDocument();
      }
    });
  }

  Future<void> _loadDocument() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get authentication headers
      final headers = await _getAuthHeaders();
      debugPrint('DocumentViewer: Auth headers: ${headers.keys.join(", ")}');

      // Prefer raw endpoint (streams from disk or DB) rather than guessing path
      final rawUrl = '${ApiConfig.baseUrl}/documents/${widget.document.id}/raw';
      debugPrint('DocumentViewer: Loading document from raw endpoint: $rawUrl');
      http.Response response =
          await http.get(Uri.parse(rawUrl), headers: headers);

      // Fallback: if 404, attempt download endpoint (may differ in older deployments)
      if (response.statusCode == 404) {
        final altUrl =
            '${ApiConfig.baseUrl}/documents/download/${widget.document.id}';
        debugPrint(
            'DocumentViewer: raw endpoint 404, trying download endpoint: $altUrl');
        response = await http.get(Uri.parse(altUrl), headers: headers);
      }

      debugPrint('DocumentViewer: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _documentData = response.bodyBytes;
            _isLoading = false;
          });
          print(
              'DocumentViewer: Successfully loaded ${response.bodyBytes.length} bytes');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please log in again');
      } else if (response.statusCode == 403) {
        throw Exception(
            'Access denied: You do not have permission to view this document');
      } else {
        throw Exception(
            'Failed to load document: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('DocumentViewer: Error loading document: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('sessionToken');
      if (token != null && token.isNotEmpty) {
        return {
          'Authorization': 'Bearer $token',
          'x-access-token': token,
        };
      }
      return {};
    } catch (e) {
      debugPrint('DocumentViewer: Failed to read auth token: $e');
      return {};
    }
  }

  Future<void> _downloadDocument() async {
    try {
      if (_documentData == null) {
        await _loadDocument();
        if (_documentData == null) return;
      }

      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          downloadsDir = Directory('$userProfile\\Downloads');
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          downloadsDir = Directory('$home/Downloads');
        }
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null || !await downloadsDir.exists()) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final fileName = widget.document.name;
      final filePath = '${downloadsDir.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);

      await file.writeAsBytes(_documentData!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.documentDownloadedTo(filePath)),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.openFolder,
              onPressed: () => _openFolder(downloadsDir!.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${AppLocalizations.of(context)!.downloadFailed}: $e')),
        );
      }
    }
  }

  Future<void> _openFolder(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
    } catch (e) {
      // Ignore errors opening folder
    }
  }

  Future<void> _openInExternalApp() async {
    try {
      if (_documentData == null) {
        await _loadDocument();
        if (_documentData == null) return;
      }

      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.document.name;
      final tempFile =
          File('${tempDir.path}${Platform.pathSeparator}$fileName');

      await tempFile.writeAsBytes(_documentData!);

      final uri = Uri.file(tempFile.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception(AppLocalizations.of(context)!.noAppToOpenFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${AppLocalizations.of(context)!.failedToOpen}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_backgroundStart, _backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                  child: _buildBody(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, color: _textPrimary),
                  tooltip: AppLocalizations.of(context)!.close,
                  style: IconButton.styleFrom(
                    backgroundColor: _surfaceDark,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              l10n.loadingDocument,
              style: const TextStyle(color: _textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return BentoCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              l10n.unableToLoadDocument,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _downloadDocument,
                icon: const Icon(Icons.download_rounded),
                label: Text(l10n.downloadInstead),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textPrimary,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show document preview or file information
    return _buildDocumentPreview();
  }

  Widget _buildDocumentPreview() {
    final l10n = AppLocalizations.of(context)!;
    final meta =
        '${_getFileTypeDescription()} • ${widget.document.formattedFileSize}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BentoCard(
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _backgroundStart.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Icon(
                    _getFileIcon(),
                    size: 80,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.document.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                meta,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _primaryGradientButton(
                label: 'Vorschau laden',
                icon: Icons.visibility_rounded,
                onPressed: _documentData == null ? _loadDocument : null,
              ),
              const SizedBox(height: 12),
              _secondaryButton(
                label: 'In externer App öffnen',
                icon: Icons.open_in_new_rounded,
                onPressed: _openInExternalApp,
              ),
              const SizedBox(height: 10),
              _outlinedButton(
                label: 'Auf Gerät herunterladen',
                icon: Icons.download_rounded,
                onPressed: _downloadDocument,
              ),
              if (_documentData != null && _isImageFile()) ...[
                const SizedBox(height: 10),
                _outlinedButton(
                  label: l10n.viewImage,
                  icon: Icons.image_rounded,
                  onPressed: _showImagePreview,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _isImageFile() {
    final mimeType = widget.document.mimeType.toLowerCase();
    final fileName = widget.document.name.toLowerCase();
    return mimeType.startsWith('image/') ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.gif') ||
        fileName.endsWith('.bmp') ||
        fileName.endsWith('.webp');
  }

  void _showImagePreview() {
    if (_documentData == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Image.memory(
                _documentData!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.failedToDisplayImage,
                      style: const TextStyle(color: _textPrimary),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    final fileName = widget.document.name.toLowerCase();
    final mimeType = widget.document.mimeType.toLowerCase();

    if (mimeType.contains('pdf') || fileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf_rounded;
    } else if (mimeType.startsWith('image/')) {
      return Icons.image_rounded;
    } else if (mimeType.startsWith('text/') || fileName.endsWith('.txt')) {
      return Icons.description_rounded;
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description_rounded;
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Icons.table_chart_rounded;
    } else if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
      return Icons.slideshow_rounded;
    } else {
      return Icons.insert_drive_file_rounded;
    }
  }

  String _getFileTypeDescription() {
    final fileName = widget.document.name.toLowerCase();
    final mimeType = widget.document.mimeType.toLowerCase();

    if (mimeType.contains('pdf') || fileName.endsWith('.pdf')) {
      return AppLocalizations.of(context)!.pdfDocument;
    } else if (mimeType.startsWith('image/')) {
      return AppLocalizations.of(context)!.imageFile;
    } else if (mimeType.startsWith('text/')) {
      return AppLocalizations.of(context)!.textFile;
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return AppLocalizations.of(context)!.wordDocument;
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return AppLocalizations.of(context)!.excelSpreadsheet;
    } else if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
      return AppLocalizations.of(context)!.powerPointPresentation;
    } else {
      return AppLocalizations.of(context)!.documentFile;
    }
  }
}

class BentoCard extends StatelessWidget {
  const BentoCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

Widget _primaryGradientButton({
  required String label,
  required IconData icon,
  required VoidCallback? onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 54,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.cyan],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    ),
  );
}

Widget _secondaryButton({
  required String label,
  required IconData icon,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _surfaceDark,
        foregroundColor: _textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white12),
        ),
      ),
    ),
  );
}

Widget _outlinedButton({
  required String label,
  required IconData icon,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _textPrimary,
        side: const BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),
  );
}
