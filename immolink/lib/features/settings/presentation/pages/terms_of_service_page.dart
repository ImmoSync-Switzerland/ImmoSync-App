import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:immosync/l10n/app_localizations.dart';

class TermsOfServicePage extends ConsumerStatefulWidget {
  const TermsOfServicePage({super.key});
  @override
  ConsumerState<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends ConsumerState<TermsOfServicePage> {
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _headingKeys = {};
  final Set<String> _assignedOnce = {};
  final Set<int> _skipIndices =
      {}; // lines belonging to embedded static TOC enumeration
  // Similar pattern: numbered headings need content after number. Include explicit first-section labels for multiple locales.
  final _headingRegex = RegExp(
      r'^(?:[0-9]{1,2}\.[ \t]+\S|Vertragliche Grundlagen|Foundational Provisions|Disposizioni Fondamentali|Dispositions fondamentales)');
  late List<String> _lines;
  late List<String> _headings;

  void _prepare(String body) {
    _lines = body.split('\n');
    _skipIndices.clear();
    // Detect embedded static TOC (language variants of a TOC heading) and skip its lines.
    const tocMarkers = [
      'Inhaltsverzeichnis',
      'Indice',
      'Index',
      'Table des matières',
      'Table of Contents'
    ];
    final tocTitleIndex =
        _lines.indexWhere((l) => tocMarkers.contains(l.trim()));
    List<String> enumerationHeadings = [];
    if (tocTitleIndex != -1) {
      _skipIndices.add(tocTitleIndex);
      final seenLocal = <String>{};
      for (var i = tocTitleIndex + 1; i < _lines.length; i++) {
        final t = _lines[i].trim();
        if (t.isEmpty) break;
        final isHeading = _headingRegex.hasMatch(t);
        if (!isHeading) break;
        if (seenLocal.contains(t)) break; // start of real content
        enumerationHeadings.add(t);
        seenLocal.add(t);
        _skipIndices.add(i);
      }
    }
    // Collect all headings (dedupe preserving order)
    final all = _lines
        .asMap()
        .entries
        .where((e) => _headingRegex.hasMatch(e.value.trim()))
        .map((e) => e.value.trim())
        .toList();
    if (enumerationHeadings.isNotEmpty) {
      _headings = enumerationHeadings;
    } else {
      final seen = <String>{};
      _headings = [
        for (final h in all)
          if (seen.add(h)) h
      ];
    }
    _headingKeys.clear();
    _assignedOnce.clear();
    for (final h in _headings) {
      if (!_headingKeys.containsKey(h)) {
        _headingKeys[h] = GlobalKey();
      }
    }
  }

  Future<void> _scrollTo(String heading) async {
    final key = _headingKeys[heading];
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final body = l.termsOfServiceContent;
    _prepare(body);
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(l.termsOfService,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () => context.pop()),
        actions: [
          IconButton(
            tooltip: l.copy,
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: body));
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l.copied)));
              }
            },
          )
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            color: AppColors.surfaceCards,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.termsOfService,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(l.termsOfServiceLastUpdated,
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  if (_headings.isNotEmpty)
                    _Toc(
                        headings: _headings,
                        title: l.tableOfContents,
                        onTap: _scrollTo),
                  const Divider(height: 32),
                  ..._buildParagraphs(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildParagraphs() {
    final widgets = <Widget>[];
    for (var i = 0; i < _lines.length; i++) {
      if (_skipIndices.contains(i)) continue; // hide static TOC lines
      final text = _lines[i].trim();
      if (text.isEmpty) continue;
      final isHeading = _headingRegex.hasMatch(text);
      GlobalKey? key;
      if (isHeading && !_assignedOnce.contains(text)) {
        key = _headingKeys[text];
        _assignedOnce.add(text);
      }
      widgets.add(Padding(
        key: key,
        padding: EdgeInsets.only(
            bottom: isHeading ? 12 : 10, top: isHeading ? 16 : 0),
        child: SelectableText(
          text,
          style: isHeading
              ? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              : const TextStyle(fontSize: 14, height: 1.5),
        ),
      ));
    }
    return widgets;
  }
}

class _Toc extends StatelessWidget {
  final List<String> headings;
  final String title;
  final void Function(String heading) onTap;
  const _Toc(
      {required this.headings, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final h in headings)
              ActionChip(
                label: Text(h, style: const TextStyle(fontSize: 12)),
                onPressed: () => onTap(h.trim()),
              )
          ],
        )
      ],
    );
  }
}
