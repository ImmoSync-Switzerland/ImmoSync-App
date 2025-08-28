import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/document_model.dart';

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
    // Don't auto-load the document to avoid potential crashes
    // Only load when user explicitly requests it
  }

  Future<void> _loadDocument() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Construct the correct URL for file access
      String fileUrl;
      if (widget.document.filePath.startsWith('/')) {
        fileUrl = 'https://backend.immosync.ch${widget.document.filePath}';
      } else {
        fileUrl = 'https://backend.immosync.ch/${widget.document.filePath}';
      }

      print('DocumentViewer: Loading document from URL: $fileUrl');

      final response = await http.get(Uri.parse(fileUrl));

      print('DocumentViewer: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _documentData = response.bodyBytes;
            _isLoading = false;
          });
          print('DocumentViewer: Successfully loaded ${response.bodyBytes.length} bytes');
        }
      } else {
        throw Exception('Failed to load document: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('DocumentViewer: Error loading document: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
            content: Text(AppLocalizations.of(context)!.documentDownloadedTo(filePath)),
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
          SnackBar(content: Text('${AppLocalizations.of(context)!.downloadFailed}: $e')),
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
      final tempFile = File('${tempDir.path}${Platform.pathSeparator}$fileName');
      
      await tempFile.writeAsBytes(_documentData!);
      
      final uri = Uri.file(tempFile.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('No application found to open this file type');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.failedToOpen}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = ref.watch(dynamicColorsProvider);
    
    return Scaffold(
      backgroundColor: dynamicColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          widget.document.name,
          style: TextStyle(
            color: dynamicColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: dynamicColors.primaryBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: dynamicColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInExternalApp,
            tooltip: AppLocalizations.of(context)!.openInExternalApp,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadDocument,
            tooltip: AppLocalizations.of(context)!.download,
          ),
        ],
      ),
      body: _buildBody(dynamicColors),
    );
  }

  Widget _buildBody(DynamicAppColors colors) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.primaryAccent),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loadingDocument,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.unableToLoadDocument,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _downloadDocument,
              icon: const Icon(Icons.download),
              label: Text(AppLocalizations.of(context)!.downloadInstead),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: colors.textOnAccent,
              ),
            ),
          ],
        ),
      );
    }

    // Show document preview or file information
    return _buildDocumentPreview(colors);
  }

  Widget _buildDocumentPreview(DynamicAppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // File icon and info
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.surfaceCards,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderLight),
            ),
            child: Column(
              children: [
                Icon(
                  _getFileIcon(),
                  size: 80,
                  color: colors.primaryAccent,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.document.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _getFileTypeDescription(),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.document.formattedFileSize,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons
          Column(
            children: [
              if (_documentData != null && _isImageFile()) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showImagePreview(colors),
                    icon: const Icon(Icons.visibility),
                    label: Text(AppLocalizations.of(context)!.viewImage),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryAccent,
                      foregroundColor: colors.textOnAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              if (_documentData == null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadDocument,
                    icon: const Icon(Icons.visibility),
                    label: Text(AppLocalizations.of(context)!.loadPreview),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryAccent,
                      foregroundColor: colors.textOnAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openInExternalApp,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(AppLocalizations.of(context)!.openInExternalApp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryAccent,
                    foregroundColor: colors.textOnAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _downloadDocument,
                  icon: const Icon(Icons.download),
                  label: Text(AppLocalizations.of(context)!.downloadToDevice),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primaryAccent,
                    side: BorderSide(color: colors.primaryAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  void _showImagePreview(DynamicAppColors colors) {
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
                      style: TextStyle(color: colors.textPrimary),
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
      return Icons.picture_as_pdf;
    } else if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('text/') || fileName.endsWith('.txt')) {
      return Icons.description;
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description;
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Icons.table_chart;
    } else if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
      return Icons.slideshow;
    } else {
      return Icons.insert_drive_file;
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
