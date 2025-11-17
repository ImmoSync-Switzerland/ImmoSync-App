import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:immosync/l10n/app_localizations.dart';

class PrivacyPolicyPage extends ConsumerStatefulWidget {
  const PrivacyPolicyPage({super.key});
  @override
  ConsumerState<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends ConsumerState<PrivacyPolicyPage> {
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _headingKeys = {};
  final Set<String> _assignedOnce =
      {}; // track which heading texts already received a GlobalKey in the widget tree

  late List<String> _lines;
  late List<String> _headings;
  // Indices of lines inside the embedded static table of contents we want to hide (because we render a dynamic TOC widget)
  final Set<int> _skipIndices = {};
  // Require at least one non-whitespace character after the number & period to avoid matching bare list indices like "1." used in nested lists
  final _headingRegex = RegExp(r'^[0-9]{1,2}\.[ \t]+\S');

  void _prepare(String body) {
    _lines = body.split('\n');
    _skipIndices.clear();
    // Detect and strip an in-text static table of contents block so that headings do not appear twice.
    // This block pattern (language dependent) looks like:
    //   <TOC title> (e.g. "Inhaltsverzeichnis", "Indice", etc.)
    //   1. Heading A
    //   2. Heading B
    //   ...
    //   <first heading repeated again>  (start of real content) OR a non-heading paragraph
    const tocMarkers = [
      'Inhaltsverzeichnis',
      'Indice',
      'Index',
      'Table des matières',
      'Table of Contents'
    ];
    final tocTitleIndex =
        _lines.indexWhere((l) => tocMarkers.contains(l.trim()));
    final List<String> enumerationHeadings = [];
    if (tocTitleIndex != -1) {
      _skipIndices.add(tocTitleIndex); // hide the TOC title line inside content
      final seen = <String>{};
      for (var i = tocTitleIndex + 1; i < _lines.length; i++) {
        final raw = _lines[i];
        final trimmed = raw.trim();
        if (trimmed.isEmpty) break; // blank line ends enumeration
        final isHeadingCandidate = _headingRegex.hasMatch(trimmed);
        if (!isHeadingCandidate) {
          break; // enumeration block ends when a non-heading encountered
        }
        if (seen.contains(trimmed)) {
          // We encountered a heading we've already listed -> this is the start of real content
          break;
        }
        // Record heading for TOC and mark to skip in body
        enumerationHeadings.add(trimmed);
        seen.add(trimmed);
        _skipIndices.add(i);
      }
    }

    final List<String> allHeadings = _lines
        .asMap()
        .entries
        .where((e) => _headingRegex.hasMatch(e.value.trim()))
        .map((e) => e.value.trim())
        .toList();
    // If we detected an enumeration we want unique order from that; else dedupe from all occurrences.
    if (enumerationHeadings.isNotEmpty) {
      _headings = enumerationHeadings; // already unique
    } else {
      final seen = <String>{};
      _headings = [
        for (final h in allHeadings)
          if (seen.add(h)) h
      ];
    }
    _headingKeys.clear();
    _assignedOnce.clear();
    for (final h in _headings) {
      final trimmed = h.trim();
      // Only create a key for the first occurrence; duplicates won't get anchors to avoid GlobalKey collisions
      if (!_headingKeys.containsKey(trimmed)) {
        _headingKeys[trimmed] = GlobalKey();
      }
    }
  }

  Future<void> _scrollTo(String heading) async {
    final key = _headingKeys[heading];
    if (key == null) return;
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(context,
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
    final body = l.privacyPolicyContent;
    _prepare(body);
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(l.privacyPolicy,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
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
                  Text(l.privacyPolicy,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(l.privacyPolicyLastUpdated,
                      style: const TextStyle(
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
      final raw = _lines[i];
      final text = raw.trim();
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
